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

#include "YTClient.h"

#include <QNetworkRequest>
#include <QJsonDocument>
#include <QNetworkReply>
#include <QJsonObject>
#include <QStringList>
#include <QSettings>
#include <QLocale>
#include <QDebug>
#include <QUrl>

#include "NativeUtil.h"
#include "config.h"

static QString YouTubeDataV3Url("https://www.googleapis.com/youtube/v3/");
static QString YouTubeGetVideoInfoUrl("http://www.youtube.com/get_video_info");

static void
appendParams(QVariantMap& params, QUrlQuery& query)
{
    for (QVariantMap::const_iterator i = params.begin(); i != params.end(); ++i) {
        query.addQueryItem(i.key(), i.value().toString());
    }
}

static bool
authEnabled()
{
    QSettings settings;
    QVariant auth = settings.value("YouTubeAccountIntegration");
    return (auth.isValid() && auth.toBool());
}

static void
appendAuthHeader(QNetworkRequest& request)
{
    if (authEnabled()) {
        QSettings settings;
        QString auth = settings.value("YouTubeAccessTokenType").toString() +
                " " + settings.value("YouTubeAccessToken").toString();
        request.setRawHeader("Authorization", auth.toLocal8Bit());
    }
}

YTClient::YTClient(QObject *parent)
    : QObject(parent)
    , _manager(new QNetworkAccessManager(this))
    , _regionCode(NativeUtil::getRegionCode())
{
    connect(_manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(onRequestFinished(QNetworkReply*)));
    connect(_manager, SIGNAL(networkAccessibleChanged(QNetworkAccessManager::NetworkAccessibility)),
            this, SLOT(onNetworkAccessibleChanged(QNetworkAccessManager::NetworkAccessibility)));
}

YTClient::~YTClient()
{
    delete _manager;
}

void
YTClient::list(QString resource, QVariantMap params)
{
    QUrlQuery query;
    appendParams(params, query);
    qDebug() << "resource: " << resource << ", params: " << query.toString();
    appendCommonParams(query);

    QUrl url(YouTubeDataV3Url + resource);
    url.setQuery(query);

    QNetworkRequest request;
    request.setUrl(url);
    appendAuthHeader(request);

    _manager->get(request);
}

void
YTClient::post(QString resource, QVariantMap params, QVariant content)
{
    QUrlQuery query;
    appendParams(params, query);
    qDebug() << "resource: " << resource << ", params: " << query.toString();
    appendCommonParams(query);

    QUrl url(YouTubeDataV3Url + resource);
    url.setQuery(query);

    QNetworkRequest request;
    QByteArray data;
    request.setUrl(url);
    if (content.isValid()) {
        QJsonDocument jsonDoc = QJsonDocument::fromVariant(content);
        data = jsonDoc.toJson(QJsonDocument::Compact);
        qDebug() << "content: " << data;
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        request.setHeader(QNetworkRequest::ContentLengthHeader, data.size());
    } else {
        request.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain");
        request.setHeader(QNetworkRequest::ContentLengthHeader, 0);
    }

    appendAuthHeader(request);

    _manager->post(request, data);
}

void
YTClient::del(QString resource, QVariantMap params)
{
    QUrlQuery query;
    appendParams(params, query);
    qDebug() << "resource: " << resource << ", params: " << query.toString();
    appendCommonParams(query);

    QUrl url(YouTubeDataV3Url + resource);
    url.setQuery(query);

    QNetworkRequest request;
    request.setUrl(url);
    appendAuthHeader(request);

    _manager->deleteResource(request);
}

void
YTClient::getDirectVideoURL(QString videoId)
{
    QUrlQuery query;
    query.addQueryItem("video_id", videoId);
    query.addQueryItem("el", "player_embedded");
    query.addQueryItem("gl", _regionCode);
    if (QLocale::system().name() != "C") {
        query.addQueryItem("hl", QLocale::system().name());
    } else {
        query.addQueryItem("hl", "en");
    }

    QUrl url(YouTubeGetVideoInfoUrl);
    url.setQuery(query);

    QNetworkRequest request;
    request.setUrl(url);

    _manager->get(request);
}

void
YTClient::requestOAuth2Token(QString authCode)
{
	QUrlQuery query;
	query.addQueryItem("code", authCode);
	query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
	query.addQueryItem("client_secret", YOUTUBE_AUTH_CLIENT_SECRET);
	query.addQueryItem("redirect_uri", "urn:ietf:wg:oauth:2.0:oob");
	query.addQueryItem("grant_type", "authorization_code");
	QByteArray data = query.toString(QUrl::FullyEncoded).toLocal8Bit();

	qDebug() << "Requesting YouTube OAuth2 tokens";

	QNetworkRequest request(QUrl(YOUTUBE_AUTH_TOKEN_URI));
	request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

	_manager->post(request, data);
}

void
YTClient::onRequestFinished(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        if (reply->request().url() == QUrl(YOUTUBE_AUTH_TOKEN_URI)) {
            handleTokenReply(reply);
        } else if (reply->request().url().toString().startsWith(YouTubeGetVideoInfoUrl)) {
            handleVideoInfoReply(reply);
        } else {
            handleSuccess(reply);
        }
    } else if (reply->error() == QNetworkReply::AuthenticationRequiredError && authEnabled()) {
        refreshToken();
    } else {
        handleError(reply);
    }

    delete reply;
}

void
YTClient::onNetworkAccessibleChanged(QNetworkAccessManager::NetworkAccessibility accessible)
{
    qDebug() << "Network accessibility changed: " << accessible;
}

void
YTClient::refreshToken() const
{
	QSettings settings;

	Q_ASSERT(settings.value("YouTubeRefreshToken").isValid());

	QUrlQuery query;
	query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
	query.addQueryItem("client_secret", YOUTUBE_AUTH_CLIENT_SECRET);
	query.addQueryItem("refresh_token", settings.value("YouTubeRefreshToken").toString());
	query.addQueryItem("grant_type", "refresh_token");
	QByteArray data = query.toString(QUrl::FullyEncoded).toLocal8Bit();

	qDebug() << "OAuth2 token expired, refreshing";

	QNetworkRequest request(QUrl(YOUTUBE_AUTH_TOKEN_URI));
	request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

	_manager->post(request, data);
}

void
YTClient::handleSuccess(QNetworkReply *reply)
{
	QVariant contentType = reply->header(QNetworkRequest::ContentTypeHeader);

	if (contentType.isValid() && contentType.toString().contains("application/json")) {
		QByteArray data = reply->readAll();
		QJsonDocument json = QJsonDocument::fromJson(data);
		emit success(QVariant(json.object()));
	} else {
		qDebug() << "Unknown response: " << contentType.toString();
		emit success(QVariant());
	}
}

void
YTClient::handleError(QNetworkReply *reply)
{
    QVariant contentType = reply->header(QNetworkRequest::ContentTypeHeader);
    Q_ASSERT(contentType.type() == QVariant::String);

    qCritical() << "Error : " << reply->readAll();

	if (contentType.toString().contains("application/json")) {
		QByteArray data = reply->readAll();
		QJsonDocument json = QJsonDocument::fromJson(data);
		emit error(QVariant(json.object()));
	} else {
		qCritical() << "Unrecognized error content type: " << contentType.toString();
		emit error(QVariant());
	}
}

void
YTClient::handleTokenReply(QNetworkReply *reply)
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

    settings.setValue("YouTubeAccountIntegration", true);
    settings.setValue("YouTubeAccessToken", map["access_token"]);
    settings.setValue("YouTubeAccessTokenType", map["token_type"]);

    if (map.find("refresh_token") == map.end()) {
        qDebug() << "OAuth2 token refreshed";
        emit retry();
    } else {
        qDebug() << "New OAuth2 token obtained";
        settings.setValue("YouTubeRefreshToken", map["refresh_token"]);
        emit success(QVariant(json.object()));
    }
}

void
YTClient::handleVideoInfoReply(QNetworkReply *reply)
{
    QUrlQuery query(reply->readAll());
    typedef QList<QPair<QString, QString> > QueryItemList;

    QString streamMap = query.queryItemValue("url_encoded_fmt_stream_map");
    if (streamMap.isEmpty()) {
        qWarning() << "YouTube get_video_info did not return proper stream map!";
        emit error(QVariant());
        return;
    }

    QStringList mapEntries = streamMap.split(",", QString::SkipEmptyParts);
    if (mapEntries.size() == 0) {
        qWarning() << "YouTube stream map empty";
        emit error(QVariant());
    }

    QVariantList streamList;
    for (int i = 0; i < mapEntries.size(); ++i) {
        query = QUrlQuery(mapEntries[i]);
        QueryItemList items = query.queryItems();
        QueryItemList::Iterator it;
        QVariantMap map;
        for (it = items.begin(); it != items.end(); ++it) {
            if (it->first == "url") {
                QString decodedUrl = QUrl::fromPercentEncoding(it->second.toLocal8Bit());
                decodedUrl = QUrl::fromPercentEncoding(decodedUrl.toLocal8Bit());
                map.insert(it->first, QVariant(decodedUrl));
            } else {
                map.insert(it->first, QVariant(it->second));
            }
        }
        streamList.append(map);
    }
    emit success(streamList);
}

void
YTClient::appendCommonParams(QUrlQuery& query)
{
	QSettings settings;
	query.addQueryItem("key", YOUTUBE_DATA_API_V3_KEY);
	query.addQueryItem("regionCode", _regionCode);
	if (QLocale::system().name() != "C") {
		query.addQueryItem("hl", QLocale::system().name());
	} else {
		query.addQueryItem("hl", "en");
	}
	if (!query.hasQueryItem("maxResults")) {
		query.addQueryItem("maxResults", settings.value("ResultsPerPage").toString());
	}
}

QString
YTClient::getOAuth2URL() const
{
	QUrlQuery query;
	query.addQueryItem("client_id", YOUTUBE_AUTH_CLIENT_ID);
	query.addQueryItem("redirect_uri", YOUTUBE_AUTH_REDIRECT_URI);
	query.addQueryItem("scope", "https://www.googleapis.com/auth/youtube");
	query.addQueryItem("response_type", "code");
	query.addQueryItem("access_type=", "offline");

	QUrl url(YOUTUBE_AUTH_URI);
	url.setQuery(query);

	return url.toString();
}
