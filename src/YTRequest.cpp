/*-
 * Copyright (c) 2014 Peter Tworek
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the author nor the names of any co-contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "YTRequest.h"

#include <QNetworkConfigurationManager>
#include <QNetworkAccessManager>
#include <QScopedPointer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringList>
#include <QUrlQuery>
#include <QSettings>
#include <QLocale>
#include <QDebug>

#include "YTVideoUrlFetcher.h"
#include "YTNetworkManager.h"
#include "YTTranslations.h"
#include "YTPlayer.h"
#include "NativeUtil.h"
#include "config.h"

namespace {
static const QString kYouTubeDataV3Url("https://www.googleapis.com/youtube/v3/");
static const QString kYouTubeGetVideoInfoUrl("http://www.youtube.com/get_video_info");
static const QString kMaxResults("50"); // Maximum allowed by YouTube
static const int kMaxRetryCount = 3;
}

static void
appendParams(QUrlQuery& query, QVariantMap& params)
{
    for (QVariantMap::const_iterator i = params.begin(); i != params.end(); ++i)
        query.addQueryItem(i.key(), i.value().toString());
}

static void
appendCommonParams(QUrlQuery& query)
{
    query.addQueryItem("key", YOUTUBE_DATA_API_V3_KEY);
    query.addQueryItem("regionCode", NativeUtil::getRegionCode());
    query.addQueryItem("maxResults", kMaxResults);
    query.addQueryItem("hl", YTTranslations::language());
}

static bool
authEnabled()
{
    QSettings settings;
    QVariant auth = settings.value("AccountIntegration");
    return (auth.isValid() && auth.toBool());
}

static void
appendAuthHeader(QNetworkRequest& request)
{
    if (authEnabled()) {
        QSettings settings;
        QString auth = settings.value("YouTube/AccessTokenType").toString() +
                " " + settings.value("YouTube/AccessToken").toString();
        request.setRawHeader("Authorization", auth.toLocal8Bit());
    }
}

static QString
methodToString(YTRequest::Method method)
{
    switch (method) {
    case YTRequest::List: return "list";
    case YTRequest::Post: return "post";
    case YTRequest::Delete: return "delete";
    default: return "unknown";
    }
}

static QUrl
youtubeDataAPIUrl(QString resource, QVariantMap params)
{
    QUrlQuery query;
    appendParams(query, params);
    appendCommonParams(query);

    QUrl url(kYouTubeDataV3Url + resource);
    url.setQuery(query);
    return url;
}

static QUrl
youtubeVideoInfoUrl(QVariantMap params)
{
    QUrlQuery query;
    appendParams(query, params);
    query.addQueryItem("el", "player_embedded");
    query.addQueryItem("gl", NativeUtil::getRegionCode());
    if (QLocale::system().name() != "C") {
        query.addQueryItem("hl", QLocale::system().name());
    } else {
        query.addQueryItem("hl", "en");
    }

    QUrl url(kYouTubeGetVideoInfoUrl);
    url.setQuery(query);
    return url;
}

YTRequest::YTRequest(QObject *parent, QNetworkAccessManager* nam)
    : QObject(parent)
    , _reply(NULL)
    , _token_reply(NULL)
    , _url_fetcher(NULL)
    , _network_access_manager(nam ? *nam : GetNetworkAccessManager())
    , _loaded(false)
    , _busy(false)
    , _model(NULL)
    , _retryCount(0)
{
    Q_ASSERT(thread() == _network_access_manager.thread());
}

YTRequest::~YTRequest()
{
    if (_reply) {
        if (!_reply->isFinished())
            _reply->abort();
        _reply->deleteLater();
        _reply = NULL;
    }
    if (_token_reply) {
        if (!_token_reply->isFinished())
            _token_reply->abort();
        _reply->deleteLater();
        _token_reply = NULL;
    }
    if (_url_fetcher) {
        _url_fetcher->disconnect();
        _url_fetcher->deleteLater();
        _url_fetcher = NULL;
    }
}

QNetworkAccessManager&
YTRequest::GetNetworkAccessManager()
{
    static QNetworkAccessManager instance;
    static bool configured = false;
    if (!configured) {
        YTNetworkManager::instance().manageSessionFor(&instance);
        instance.setCache(GetAPIResponseDiskCache());
        configured = true;
    }
    return instance;
}

void
YTRequest::run()
{
    QUrl url;
    if (_resource == "video/url") {
        Q_ASSERT(_method == List);
        url = youtubeVideoInfoUrl(_params);
    } else if (_resource == "oauth2") {
        Q_ASSERT(_method == Post);
        return requestToken();
    } else {
        url = youtubeDataAPIUrl(_resource, _params);
    }

    qDebug() << "YouTube request method: " << methodToString(_method)
             << ", resource: " << _resource
             << ", params: " << _params;

    QNetworkRequest request(url);
    appendAuthHeader(request);

    if (_reply) {
        delete _reply;
    }

    switch (_method) {
    case List:
        _reply = _network_access_manager.get(request);
        break;
    case Post:
    {
        QByteArray data;
        if (_content.isValid()) {
            QJsonDocument doc = QJsonDocument::fromVariant(_content);
            data = doc.toJson(QJsonDocument::Compact);
            request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
            request.setHeader(QNetworkRequest::ContentLengthHeader, data.size());
        } else {
            request.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain");
            request.setHeader(QNetworkRequest::ContentLengthHeader, 0);
        }
        _reply = _network_access_manager.post(request, data);
        break;
    }
    case Delete:
        _reply = _network_access_manager.deleteResource(request);
        break;
    default:
        qCritical() << "Unhandled method type: " << methodToString(_method);
    }

    connect(_reply, SIGNAL(finished()), this, SLOT(onFinished()));
    _busy = true;
    emit busyChanged(_busy);

    _loaded = false;
    emit loadedChanged(false);
}

void
YTRequest::onTokenRequestFinished()
{
    Q_ASSERT(_token_reply);

    switch (_token_reply->error()) {
    case QNetworkReply::NoError:
        handleTokenReply(_token_reply);
        break;
    default:
        handleError(_token_reply);
        if (_reply) {
            delete _reply;
            _reply = NULL;
        }
        break;
    }

    _token_reply->deleteLater();
    _token_reply = NULL;
}

void
YTRequest::onFinished()
{
    Q_ASSERT(_reply);

    bool busy = false;

    switch (_reply->error()) {
    case QNetworkReply::NoError:
        if (_reply->request().url().toString().startsWith(kYouTubeGetVideoInfoUrl)) {
            if (!handleVideoInfoReply(_reply)) {
                busy = true;
                break;
            }
        } else {
            handleSuccess(_reply);
        }
        _loaded = true;
        emit loadedChanged(true);
        break;
    case QNetworkReply::OperationCanceledError:
        // Ignore
        break;
    case QNetworkReply::UnknownNetworkError:
        // Unknown error is often reported when the request is made
        // just after switching from celluar to mobile connection or
        // the other way around. The error string just states
        // "Connection Timed Out"
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::TimeoutError:
        if (!YTNetworkManager::instance().online())
            break;
        if (_retryCount++ < kMaxRetryCount) {
            qDebug() << "Request failed, retrying ("
                     << _retryCount << "of" << kMaxRetryCount << ")"
                     << ", error:" << _reply->errorString();
            QMetaObject::invokeMethod(this, "run", Qt::QueuedConnection);
        } else {
            handleError(_reply);
        }
        break;
    case QNetworkReply::AuthenticationRequiredError:
        if (authEnabled()) {
            busy = true;
            refreshToken();
            break;
        }
    default:
        handleError(_reply);
        break;
    }

    _reply->deleteLater();
    _reply = NULL;

    if (_busy != busy) {
        _busy = busy;
        emit busyChanged(_busy);
    }
}

void
YTRequest::onURLFetcherFailed()
{
    _busy = false;
    emit busyChanged(_busy);
    _loaded = true;
    emit loadedChanged(true);
    emit error(QVariant());
}

void
YTRequest::onURLFetcherSucceeded(QVariantMap response)
{
    _busy = false;
    emit busyChanged(_busy);
    _loaded = true;
    emit loadedChanged(true);
    emit success(response);
}

void
YTRequest::handleSuccess(QNetworkReply *reply)
{
    QVariant contentType = reply->header(QNetworkRequest::ContentTypeHeader);
    if (contentType.isValid() && contentType.toString().contains("application/json")) {
        QByteArray data = reply->readAll();
        QJsonDocument json = QJsonDocument::fromJson(data);
        if (_model && (_params.end() != _params.find("part"))) {
            Q_ASSERT(json.isObject());
            QJsonValue val = json.object().value("items");
            Q_ASSERT(val.toVariant().isValid());
            _model->append(val.toVariant().toList());
        }
        emit success(QVariant(json.object()));
    } else if (contentType.isValid()) {
        qCritical() << "Unknown response:" << reply->readAll();
        emit error(QVariant());
    }
}

void
YTRequest::handleError(QNetworkReply *reply)
{
    QVariant contentType = reply->header(QNetworkRequest::ContentTypeHeader);
    if (contentType.isValid() && contentType.toString().contains("application/json")) {
        QByteArray data = reply->readAll();
        QJsonDocument json = QJsonDocument::fromJson(data);
        qCritical() << "API Error: " << json;
        emit error(QVariant(json.object()));
    } else {
        QVariantMap map;
        map["ErrorCode"] = reply->error();
        map["ErrorString"] = reply->errorString();
        map["HttpStatusCode"] = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
        map["Content"] = QVariant(reply->readAll());
        qCritical() << "Unknown Error: " << map;
        emit error(map);
    }
}

void
YTRequest::handleTokenReply(QNetworkReply *reply)
{
    QVariant contentType = reply->header(QNetworkRequest::ContentTypeHeader);
    QByteArray data = reply->readAll();
    QSettings settings;

    if (!contentType.toString().contains("application/json")) {
        qCritical() << "Unrecognized YouTube OAuth2 response content type: " << contentType;
        emit error(QVariant(data));
        return;
    }

    QJsonDocument json = QJsonDocument::fromJson(data);
    QVariantMap map = json.toVariant().toMap();

    if (map.find("access_token") == map.end() ||
            map.find("token_type") == map.end()) {
        qCritical() << "Invalid YouTube OAuth2 response: " << data;
        emit error(QVariant(json.object()));
        return;
    }

    settings.setValue("AccountIntegration", true);
    settings.setValue("YouTube/AccessToken", map["access_token"]);
    settings.setValue("YouTube/AccessTokenType", map["token_type"]);

    if (map.find("refresh_token") == map.end()) {
        qDebug() << "OAuth2 token refreshed";
        run();
    } else {
        qDebug() << "New OAuth2 token obtained";
        settings.setValue("YouTube/RefreshToken", map["refresh_token"]);
        emit success(QVariant(json.object()));
    }
}

bool
YTRequest::handleVideoInfoReply(QNetworkReply *reply)
{
    QUrlQuery query(reply->readAll());
    typedef QList<QPair<QString, QString> > QueryItemList;

    QString streamMap = query.queryItemValue("url_encoded_fmt_stream_map", QUrl::FullyDecoded);
    if (streamMap.isEmpty()) {
        qWarning() << "YouTube get_video_info did not return proper stream map!";
        qDebug() << "Reply: " << reply->readAll();
        emit error(QVariant());
        return true;
    }

    QStringList mapEntries = streamMap.split(",", QString::SkipEmptyParts);
    if (mapEntries.size() == 0) {
        qWarning() << "YouTube stream map empty";
        emit error(QVariant());
        return true;
    }

    QVariantMap outMap;
    for (int i = 0; i < mapEntries.size(); ++i) {
        query = QUrlQuery(mapEntries[i]);
        QueryItemList items = query.queryItems();
        QueryItemList::Iterator it;

        int itag = -1;
        QMap<QString, QVariant> streamDetailsMap;

        for (it = items.begin(); it != items.end(); ++it) {
            if (it->first == "url") {
                QString decodedUrl = QUrl::fromPercentEncoding(it->second.toLocal8Bit());
                decodedUrl = QUrl::fromPercentEncoding(decodedUrl.toLocal8Bit());
                streamDetailsMap.insert(it->first, decodedUrl);
            } else if (it->first == "itag") {
                itag = it->second.toInt();
            } else if (it->first == "s" ) {
                if (!YTVideoUrlFetcher::available()) {
                    qWarning() << "youtube-dl stream fetcher not available or broken!";
                    emit error(QVariant());
                    return true;
                }
                // Encrypted content, use youtube-dl to find video streams
                if (!_url_fetcher) {
                    _url_fetcher = new YTVideoUrlFetcher;
                    connect(_url_fetcher, &YTVideoUrlFetcher::success,
                            this, &YTRequest::onURLFetcherSucceeded);
                    connect(_url_fetcher, &YTVideoUrlFetcher::failure,
                            this, &YTRequest::onURLFetcherFailed);
                }
                Q_ASSERT(_params.contains("video_id") &&
                         _params["video_id"].canConvert(QVariant::String));
                _url_fetcher->fetchUrlsFor(_params["video_id"].toString());
                return false;
            } else {
                streamDetailsMap.insert(it->first, it->second);
            }
        }
        Q_ASSERT(!streamDetailsMap.empty());

        // TODO: Allow steaming only audio
        // 139 MP4 Low bitrate AO
        // 140 MP4 Med bitrate AO
        // 141 MP4 Hi bitrate AO
        switch (itag) {
        case 18: // MP4 480 x 360
            outMap.insert("360p", streamDetailsMap);
            break;
        case 22: // MP4 1280 x 720
            outMap.insert("720p", streamDetailsMap);
            break;
        case 37: // MP4 1920 x 1080
            outMap.insert("1080p", streamDetailsMap);
            break;
        }
    }

    emit success(outMap);
    return true;
}

void
YTRequest::requestToken()
{
    QUrlQuery query;
    appendParams(query, _params);
    //query.addQueryItem("code", authCode);
    query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
    query.addQueryItem("client_secret", YOUTUBE_AUTH_CLIENT_SECRET);
    query.addQueryItem("redirect_uri", "urn:ietf:wg:oauth:2.0:oob");
    query.addQueryItem("grant_type", "authorization_code");
    QByteArray data = query.toString(QUrl::FullyEncoded).toLocal8Bit();

    qDebug() << "Requesting YouTube OAuth2 tokens";

    QNetworkRequest request(QUrl(YOUTUBE_AUTH_TOKEN_URI));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    if (_token_reply) {
        Q_ASSERT(_token_reply->isFinished());
        delete _token_reply;
    }

    _token_reply = _network_access_manager.post(request, data);
    connect(_token_reply, SIGNAL(finished()), this, SLOT(onTokenRequestFinished()));
}

void
YTRequest::refreshToken()
{
    QSettings settings;
    QUrlQuery query;

    qDebug() << "OAuth2 token expired, refreshing";
    Q_ASSERT(settings.value("YouTube/RefreshToken").isValid());

    query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
    query.addQueryItem("client_secret", YOUTUBE_AUTH_CLIENT_SECRET);
    query.addQueryItem("refresh_token", settings.value("YouTube/RefreshToken").toString());
    query.addQueryItem("grant_type", "refresh_token");
    QByteArray data = query.toString(QUrl::FullyEncoded).toLocal8Bit();

    QNetworkRequest request(QUrl(YOUTUBE_AUTH_TOKEN_URI));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    if (_token_reply) {
        Q_ASSERT(_token_reply->isFinished());
        delete _token_reply;
    }

    _token_reply = _network_access_manager.post(request, data);
    connect(_token_reply, SIGNAL(finished()), this, SLOT(onTokenRequestFinished()));
}

QUrl
YTRequest::oAuth2Url() const
{
    QUrlQuery query;
    query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
    query.addQueryItem("redirect_uri", YOUTUBE_AUTH_REDIRECT_URI);
    query.addQueryItem("scope", "https://www.googleapis.com/auth/youtube");
    query.addQueryItem("response_type", "code");
    query.addQueryItem("access_type=", "offline");

    QUrl url(YOUTUBE_AUTH_URI);
    url.setQuery(query);
    return url;
}
