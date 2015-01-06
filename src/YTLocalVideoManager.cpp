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

#include "YTLocalVideoManager.h"

#include <QNetworkAccessManager>
#include <QSqlDatabase>
#include <QStringList>
#include <QJsonObject>
#include <QSettings>
#include <QFileInfo>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

#include "YTNetworkManager.h"
#include "YTLocalVideoData.h"
#include "YTRequest.h"
#include "YTPlayer.h"
#include "Prefs.h"

class YTDownloadInfo : public QObject {
    Q_OBJECT
public:
    explicit YTDownloadInfo(QSharedPointer<YTLocalVideoData> data,
                            QNetworkAccessManager& nam, QObject *parent = 0)
        : QObject(parent)
        , _downloadData(data)
        , _streamRequest(NULL)
        , _snippetRequest(NULL)
        , _thumbnailReply(NULL)
        , _videoReply(NULL)
        , _initialVideoOffset(0)
        , _networkAccessManager(nam)
    {
    }

    ~YTDownloadInfo() {
#ifndef QT_NO_DEBUG
        qDebug() << "Destroy download info:" << _downloadData->videoId();
#endif
        Q_ASSERT(!_videoReply);
        Q_ASSERT(!_thumbnailReply);
        Q_ASSERT(!_streamRequest);
        Q_ASSERT(!_snippetRequest);
    }

    void start()
    {
        qDebug() << "Starting download:" << _downloadData->videoId();
        if (!_thumbnailUrl.isValid())
            getThumbnailUrl();

        if (!_videoUrl.isValid())
            getVideoUrl();

        beginDataDownloadsIfPossible();
    }

    void abort()
    {
        qDebug() << "Abort download:" << _downloadData->videoId();
        cleanup();
        _downloadData->remove();
    }

    void pause()
    {
        qDebug() << "Pause download:" << _downloadData->videoId();
        cleanup();
        _downloadData->downloadPaused();
    }

    void resume()
    {
        qDebug() << "Resume download:" << _downloadData->videoId();
        _downloadData->downloadResumed();
    }

    void queued()
    {
        qDebug() << "Queue download:" << _downloadData->videoId();
        _downloadData->downloadQueued();
    }

    YTLocalVideoData& videoData() const
    {
        return *_downloadData.data();
    }

signals:
    void finished(YTDownloadInfo*);
    void failed(YTDownloadInfo*);

private slots:
    void onThumbnailDownloadFinished()
    {
        if (_thumbnailReply->error() == QNetworkReply::NoError) {
            _downloadData->thumbnailDownloadFinished(_thumbnailReply->readAll());
            dataDownloadFinished();
        } else {
            _thumbnailUrl.clear();
            dataDownloadFailed(*_thumbnailReply);
        }
        _thumbnailReply->disconnect();
        _thumbnailReply->deleteLater();
        _thumbnailReply = NULL;
    }

    void onVideoDownloadFinished()
    {
        if (_videoReply->error() == QNetworkReply::NoError) {
            int httpCode = _videoReply->attribute(
                QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (httpCode == 200 || httpCode == 206) {
                _downloadData->videoDataFetched(_videoReply->readAll());
                _downloadData->videoDownloadFinished();
                dataDownloadFinished();
            } else if (httpCode == 302) {
                qDebug() << "Video download redirected";
                _videoUrl = _videoReply->attribute(
                    QNetworkRequest::RedirectionTargetAttribute).toUrl();
                _videoReply->disconnect();
                _videoReply->deleteLater();
                _videoReply = NULL;
                startVideoDataDownload();
                return;
            } else {
                qCritical() << "Unhandled HTTP status code:" << httpCode
                           << ", treating as error";
                _downloadData->videoDownloadFailed();
                dataDownloadFailed(*_videoReply);
            }
        } else {
            dataDownloadFailed(*_videoReply);
        }
        _videoReply->disconnect();
        _videoReply->deleteLater();
        _videoReply = NULL;
    }

    void onVideoDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
    {
        Q_ASSERT(_videoReply);
        if (bytesTotal != 0) {
            double p = (double)(_initialVideoOffset + bytesReceived) /
                               (_initialVideoOffset + bytesTotal);
            _downloadData->reportVideoDownloadProgress(p * 100);
        }
        _downloadData->videoDataFetched(_videoReply->readAll());
    }

    void onStreamsRequestSuccess(QVariant response)
    {
        qDebug() << "Got stream info for video:" << _downloadData->videoId();

        QVariantMap map = response.toMap();
        Q_ASSERT(!map.isEmpty());

        QSettings settings;
        QString quality = settings.value("Download/Quality", "360p").toString();

        if (!map.contains(quality)) {
            if (map.contains("720p")) {
                quality = "720p";
            } else if (map.contains("360p")) {
                quality = "360p";
            } else if (map.contains("1080p")) {
                quality = "1080p";
            } else {
                Q_ASSERT(false);
                onMetadataRequestError(response);
                return;
            }
            qDebug() << "User selected quality not available";
        }

        qDebug() << "Selected video download quality:" << quality;

        if (_downloadData->hasPartialVideo()) {
            QString prevQuality = _downloadData->quality();
            Q_ASSERT(!prevQuality.isEmpty());
            // The user has changed video quality before unpausing the download
            if (prevQuality != quality) {
                if (map.contains(prevQuality))
                    quality = prevQuality;
                else
                    _downloadData->removeVideoData();
            }
        }

        QVariantMap urlMap;
        urlMap = map[quality].toMap();

        _videoUrl = QUrl(urlMap["url"].toString(), QUrl::StrictMode);
        _downloadData->setQuality(quality);

        _streamRequest->deleteLater();
        _streamRequest = NULL;
        beginDataDownloadsIfPossible();
    }

    void onSnippetRequestSuccess(QVariant response)
    {
        qDebug() << "Got snippet info for video:" << _downloadData->videoId();

        QVariantMap top = response.toJsonObject().toVariantMap();
        Q_ASSERT(!top.isEmpty() && top.contains("items"));

        QList<QVariant> lst = top["items"].toList();
        Q_ASSERT(!lst.empty() && lst.size() == 1);

        QVariantMap map = lst.at(0).toMap();
        Q_ASSERT(!map.isEmpty() && map.contains("snippet"));

        QVariantMap snippet = map["snippet"].toMap();
        Q_ASSERT(!snippet.isEmpty() && snippet.contains("thumbnails") &&
                 snippet.contains("title"));

        QVariantMap thumbnails = snippet["thumbnails"].toMap();
        Q_ASSERT(!thumbnails.isEmpty() && thumbnails.contains("default"));

        QVariantMap quality;
        if (thumbnails.contains("high"))
            quality = thumbnails["high"].toMap();
        else if (thumbnails.contains("medium"))
            quality = thumbnails["medium"].toMap();
        else
            quality = thumbnails["default"].toMap();

        QString url = quality["url"].toString();

        setThumbnailUrl(QUrl(url));
        _downloadData->setTitle(snippet["title"].toString());

        _snippetRequest->deleteLater();
        _snippetRequest = NULL;
        beginDataDownloadsIfPossible();
    }

    void onMetadataRequestError(QVariant response)
    {
        qCritical() << "Failed to obtain video matadata:" << response;
        cleanup();
        emit failed(this);
    }

private:
    void cleanup()
    {
        if (_snippetRequest) {
            _snippetRequest->disconnect();
            if (_snippetRequest->isRunning())
                _snippetRequest->abort();
            _snippetRequest->deleteLater();
            _snippetRequest = NULL;
            qDebug() << "Cleaning up snippet request";
        }
        if (_streamRequest) {
            _streamRequest->disconnect();
            if (_streamRequest->isRunning())
                _streamRequest->abort();
            _streamRequest->deleteLater();
            _streamRequest = NULL;
            qDebug() << "Cleaning up stream request";
        }
        if (_videoReply) {
            _videoReply->disconnect();
            if (_videoReply->isRunning())
                _videoReply->abort();
            _videoReply->deleteLater();
            _videoReply = NULL;
            qDebug() << "Cleaning up video reply";
        }
        if (_thumbnailReply) {
            _thumbnailReply->disconnect();
            if (_thumbnailReply->isRunning())
                _thumbnailReply->abort();
            _thumbnailReply->deleteLater();
            _thumbnailReply = NULL;
            qDebug() << "Cleaning up thumbnail reply";
        }
    }

    void setThumbnailUrl(QUrl thumbUrl)
    {
        _thumbnailUrl = thumbUrl;
        // XXX: In Qt 5.2 thumb.fileName() should be used
        QString thumbFileName = thumbUrl.path();
        QFileInfo fileInfo(thumbFileName);
        _downloadData->setThumbnailExtension(fileInfo.completeSuffix());
    }

    void beginDataDownloadsIfPossible()
    {
        if (_videoUrl.isValid() && _thumbnailUrl.isValid()) {
            _downloadData->downloadStarted();
            if (!_downloadData->hasVideo())
                startVideoDataDownload();
            if (!_downloadData->hasThumbnail())
                startVideoThumbnailDownload();
        }
    }

    void startVideoDataDownload()
    {
        Q_ASSERT(!_videoReply);
        if (!_downloadData->hasVideo()) {
            QNetworkRequest videoRequest(_videoUrl);
            videoRequest.setAttribute(QNetworkRequest::CacheSaveControlAttribute, QVariant(false));

            if (_downloadData->hasPartialVideo()) {
                _initialVideoOffset = _downloadData->videoDataSize();
                qDebug() << "Video" << _downloadData->videoId() << "has partial data, resuming download"
                         << ", offset:" << _initialVideoOffset;
                QByteArray range = "bytes=" + QByteArray::number(_initialVideoOffset) + "-";
                videoRequest.setRawHeader("Range", range);
            }

            _videoReply = _networkAccessManager.get(videoRequest);

            connect(_videoReply, &QNetworkReply::finished,
                    this, &YTDownloadInfo::onVideoDownloadFinished);
            connect(_videoReply, &QNetworkReply::downloadProgress,
                    this, &YTDownloadInfo::onVideoDownloadProgress);
        }
    }

    void startVideoThumbnailDownload()
    {
        Q_ASSERT(!_thumbnailReply);
        if (!_downloadData->hasThumbnail()) {
            QNetworkRequest thumbRequest(_thumbnailUrl);
            thumbRequest.setAttribute(QNetworkRequest::CacheSaveControlAttribute, QVariant(false));
            _thumbnailReply = _networkAccessManager.get(thumbRequest);
            connect(_thumbnailReply, &QNetworkReply::finished,
                    this, &YTDownloadInfo::onThumbnailDownloadFinished);
        }
    }

    void getVideoUrl()
    {
        Q_ASSERT(!_videoUrl.isValid());

        _streamRequest = new YTRequest(this, &_networkAccessManager);
        _streamRequest->setResource("video/url");
        _streamRequest->setMethod(YTRequest::List);
        QVariantMap params;
        params["video_id"] = QVariant(_downloadData->videoId());
        _streamRequest->setParams(params);

        connect(_streamRequest, &YTRequest::success,
                this, &YTDownloadInfo::onStreamsRequestSuccess);
        connect(_streamRequest, &YTRequest::error,
                this, &YTDownloadInfo::onMetadataRequestError);

        _streamRequest->run();
    }

    void getThumbnailUrl()
    {
        Q_ASSERT(!_thumbnailUrl.isValid());

        _snippetRequest = new YTRequest(this, &_networkAccessManager);
        _snippetRequest->setResource("videos");
        _snippetRequest->setMethod(YTRequest::List);
        QVariantMap params;
        params["part"] = QVariant("snippet");
        params["id"] = QVariant(_downloadData->videoId());
        _snippetRequest->setParams(params);

        connect(_snippetRequest, &YTRequest::success,
                this, &YTDownloadInfo::onSnippetRequestSuccess);
        connect(_snippetRequest, &YTRequest::error,
                this, &YTDownloadInfo::onMetadataRequestError);

        _snippetRequest->run();
    }

    void dataDownloadFinished()
    {
        if (_downloadData->hasThumbnail() && _downloadData->hasVideo()) {
            _downloadData->downloadFinished();
            emit finished(this);
        }
    }

    void dataDownloadFailed(QNetworkReply& reply)
    {
        cleanup();
        switch (reply.error()) {
        case QNetworkReply::OperationCanceledError:
            break;
        default:
            qDebug() << "Video download failed!" << reply.errorString();
            emit failed(this);
            break;
        }
    }

    QSharedPointer<YTLocalVideoData> _downloadData;
    YTRequest* _streamRequest;
    YTRequest* _snippetRequest;
    QUrl _videoUrl;
    QUrl _thumbnailUrl;
    QNetworkReply *_thumbnailReply;
    QNetworkReply *_videoReply;
    qint64 _initialVideoOffset;
    QNetworkAccessManager& _networkAccessManager;
};

// Force qmake to run moc on this file
#include "YTLocalVideoManager.moc"

namespace {

QList<YTDownloadInfo*>::iterator
findDownloadInfo(QString videoId, QList<YTDownloadInfo*>& list)
{
    QList<YTDownloadInfo*>::iterator it = list.begin();
    for (; it != list.end(); ++it) {
        if ((*it)->videoData().videoId() == videoId)
            return it;
    }
    return list.end();
}

}

YTLocalVideoManager&
YTLocalVideoManager::instance()
{
    static YTLocalVideoManager* instance = NULL;
    if (instance == NULL)
        instance = new YTLocalVideoManager;
    return *instance;
}

YTLocalVideoManager::YTLocalVideoManager(QObject *parent)
    : QObject(parent)
    , _networkAccessManager(new QNetworkAccessManager(this))
    , _queueProcessingScheduled(false)
{
    QSqlDatabase db = QSqlDatabase::database();
    if (!db.isValid())
        qFatal("Failed to open application database!");
    QStringList tables = db.tables();
    if (!tables.contains("local_videos", Qt::CaseInsensitive)) {
        if (!QSqlQuery().exec("CREATE TABLE local_videos (videoId string primary key,"
                              "title varchar, status int, thumbnail blob, video blob,"
                              "quality text)"))
            qFatal("Failed to create local_videos database");
    }

    connect(&YTNetworkManager::instance(), &YTNetworkManager::onlineChanged,
            this, &YTLocalVideoManager::onOnlineChanged);
    connect(&YTNetworkManager::instance(), &YTNetworkManager::cellularChanged,
            this, &YTLocalVideoManager::onCellularChanged);

    qRegisterMetaType<QSharedPointer<YTLocalVideoData> >("QSharedPointer<YTLocalVideoData>");
    qRegisterMetaType<YTLocalVideo::Status>("YTLocalVideo::Status");

    QMetaObject::invokeMethod(this, "onRestoreDownloads", Qt::QueuedConnection);
}

QSharedPointer<YTLocalVideoData>
YTLocalVideoManager::getDataForVideo(QString videoId)
{
    _managedVideosMutex.lock();

    QSharedPointer<YTLocalVideoData> data;
    if (_managedVideos.contains(videoId))
        data = _managedVideos[videoId].toStrongRef();

    if (data.isNull()) {
        data.reset(new YTLocalVideoData(videoId));
        data->moveToThread(this->thread());
        _managedVideos[videoId] = data.toWeakRef();
        connect(data.data(), &YTLocalVideoData::destroyed,
                this, &YTLocalVideoManager::onVideoDataDestroyed);
    }

    _managedVideosMutex.unlock();

    data->check();
    return data;
}

void
YTLocalVideoManager::download(QSharedPointer<YTLocalVideoData> data)
{
    QMetaObject::invokeMethod(this, "onDownload",
        Qt::QueuedConnection, Q_ARG(QSharedPointer<YTLocalVideoData>, data));
}

void
YTLocalVideoManager::removeDownload(QString videoId)
{
    QMetaObject::invokeMethod(this, "onRemoveDownload",
        Qt::QueuedConnection, Q_ARG(QString, videoId));
}

void
YTLocalVideoManager::pauseDownload(QString videoId)
{
    QMetaObject::invokeMethod(this, "onPauseDownload",
        Qt::QueuedConnection, Q_ARG(QString, videoId));
}

void
YTLocalVideoManager::resumeDownload(QString videoId)
{
    QMetaObject::invokeMethod(this, "onResumeDownload",
        Qt::QueuedConnection, Q_ARG(QString, videoId));
}

void
YTLocalVideoManager::onDownloadFinished(YTDownloadInfo *di)
{
    Q_ASSERT(_inProgressDownloads.contains(di));

    _inProgressDownloads.removeOne(di);
    di->deleteLater();
    processQueuedDownloads();

    emit downloadFinished(di->videoData().title());
}

void
YTLocalVideoManager::onDownloadFailed(YTDownloadInfo *di)
{
    Q_ASSERT(_inProgressDownloads.contains(di));

    _inProgressDownloads.removeOne(di);
    di->disconnect();
    di->deleteLater();
    di->videoData().remove();
    processQueuedDownloads();

    emit downloadFailed(di->videoData().title());
}

void
YTLocalVideoManager::onVideoDataDestroyed(QString videoId)
{
    QMutexLocker lock(&_managedVideosMutex);

    Q_ASSERT(_managedVideos.contains(videoId));

#ifndef QT_NO_DEBUG
    qDebug() << "Video data destroyed for:" << videoId;
#endif
    _managedVideos.remove(videoId);
}

void
YTLocalVideoManager::onOnlineChanged(bool online)
{
    if (online) {
        if (!_queuedDownloads.isEmpty()) {
            qDebug() << "Network online, resuming queued downloads";
            processQueuedDownloads();
        }
    } else if (!_inProgressDownloads.empty()) {
        qDebug() << "Network offline, stopping in progress downloads";
        stopInProgressDownloads();
    }
}

void
YTLocalVideoManager::onCellularChanged(bool cellular)
{
    QSettings s;
    QString ct = s.value("Download/ConnectionType").toString();

    qDebug() << "Allowed connection type for downloads:" << ct
             << ", network is cellular: " << cellular;

    if ((cellular && ct == kWiFiOnly) || (!cellular && ct == kCellularOnly)) {
        stopInProgressDownloads();
    } else if (!_queuedDownloads.isEmpty()){
        processQueuedDownloads();
    }
}

void
YTLocalVideoManager::processQueuedDownloads()
{
    if (!_queueProcessingScheduled) {
        QMetaObject::invokeMethod(this,
            "onProcessQueuedDownloads", Qt::QueuedConnection);
        _queueProcessingScheduled = true;
    }
}

void
YTLocalVideoManager::onProcessQueuedDownloads()
{
    Q_ASSERT(_queueProcessingScheduled);
    _queueProcessingScheduled = false;

    YTNetworkManager& nm = YTNetworkManager::instance();

    if (!nm.online())
        return;

    QSettings s;
    QString ct = s.value("Download/ConnectionType").toString();
    if ((nm.cellular() && ct == kWiFiOnly) || (!nm.cellular() && ct == kCellularOnly))
        return;

    int maxConcurrentDownloads = s.value("Download/MaxConcurrentDownloads").toInt();

    if (_queuedDownloads.empty() || _inProgressDownloads.size() >= maxConcurrentDownloads)
        return;

    while (_inProgressDownloads.size() < maxConcurrentDownloads &&
           !_queuedDownloads.isEmpty()) {
        YTDownloadInfo *di = _queuedDownloads.takeFirst();

        _inProgressDownloads.append(di);

        connect(di, &YTDownloadInfo::finished,
                this, &YTLocalVideoManager::onDownloadFinished);
        connect(di, &YTDownloadInfo::failed,
                this, &YTLocalVideoManager::onDownloadFailed);

        di->start();
    }
    qDebug() << "Download manager status"
             << ", queued:" << _queuedDownloads.size()
             << ", in progress:" << _inProgressDownloads.size()
             << ", paused:" << _pausedDownloads.size()
             << ", max concurrent downloads:" << maxConcurrentDownloads;
}

void
YTLocalVideoManager::onRestoreDownloads()
{
    QSettings settings;
    bool resume = settings.value("Download/ResumeOnStartup").toBool();
    qDebug() << "Auto resume downloads on startup:" << resume;

    QSqlQuery q;
    q.prepare("SELECT videoId,status FROM local_videos WHERE status!=?");
    q.addBindValue(YTLocalVideo::Downloaded);
    if (!q.exec())
        qFatal("Failed to execute SQL query: %s", q.lastError().text().toLocal8Bit().data());
    while (q.next()) {
        QString videoId = q.value(0).toString();
        YTLocalVideo::Status status =
            static_cast<YTLocalVideo::Status>(q.value(1).toInt());
        QSharedPointer<YTLocalVideoData> data = getDataForVideo(videoId);

        switch (status) {
        case YTLocalVideo::Queued: {
            YTDownloadInfo* info = new YTDownloadInfo(
                data, *_networkAccessManager, this);
            if (resume) {
                qDebug() << "Resuming queued download for" << videoId;
                _queuedDownloads.push_back(info);
            } else {
                qDebug() << "Pausing queued download for" << videoId;
                _pausedDownloads.push_back(info);
                info->pause();
            }
            break;
        }
        case YTLocalVideo::Paused: {
            qDebug() << "Resuming paused download for" << videoId;
            _pausedDownloads.push_back(new YTDownloadInfo(
                data, *_networkAccessManager, this));
            break;
        }
        case YTLocalVideo::Loading: {
            qWarning() << "Resuming in progress download for" << videoId;
            YTDownloadInfo* info = new YTDownloadInfo(
                data, *_networkAccessManager, this);
            info->pause();
            if (resume) {
                info->resume();
                _queuedDownloads.append(info);
            } else {
                _pausedDownloads.push_back(info);
            }
            break;
        }
        default:
            Q_ASSERT(false);
            data->remove();
            break;
        }
    }
    processQueuedDownloads();
}

void
YTLocalVideoManager::onDownload(QSharedPointer<YTLocalVideoData> data)
{
    YTDownloadInfo *info = new YTDownloadInfo(data, *_networkAccessManager, this);
    _queuedDownloads.append(info);
    info->queued();
    processQueuedDownloads();
}

void
YTLocalVideoManager::onRemoveDownload(QString videoId)
{
    Q_ASSERT(_managedVideos.contains(videoId));

    YTDownloadInfoList::iterator it = findDownloadInfo(videoId, _queuedDownloads);
    if (it != _queuedDownloads.end()) {
        qDebug() << "Removing queued download for video:" << videoId;
        YTDownloadInfo *di = *it;
        di->abort();
        _queuedDownloads.erase(it);
        delete di;
        return;
    }

    it = findDownloadInfo(videoId, _inProgressDownloads);
    if (it != _inProgressDownloads.end()) {
        qDebug() << "Removing in progress download for video:" << videoId;
        YTDownloadInfo *di = *it;
        di->abort();
        _inProgressDownloads.erase(it);
        delete di;
        processQueuedDownloads();
        return;
    }

    it = findDownloadInfo(videoId, _pausedDownloads);
    if (it != _pausedDownloads.end()) {
        qDebug() << "Removing paused download for video:" << videoId;
        YTDownloadInfo *di = *it;
        di->abort();
        _pausedDownloads.erase(it);
        delete di;
        return;
    }

    qDebug() << "Removing downloaded video:" << videoId;
    QSharedPointer<YTLocalVideoData> ptr = _managedVideos[videoId].toStrongRef();
    Q_ASSERT(!ptr.isNull());
    ptr->remove();
}

void
YTLocalVideoManager::onPauseDownload(QString videoId)
{
    YTDownloadInfoList::iterator it = findDownloadInfo(videoId, _inProgressDownloads);
    Q_ASSERT(it != _inProgressDownloads.end());
    qDebug() << "Pausing download for" << videoId;
    YTDownloadInfo* di = (*it);
    di->disconnect();
    di->pause();
    _inProgressDownloads.erase(it);
    _pausedDownloads.append(di);
    processQueuedDownloads();
}

void
YTLocalVideoManager::onResumeDownload(QString videoId)
{
    YTDownloadInfoList::iterator it = findDownloadInfo(videoId, _pausedDownloads);
    Q_ASSERT(it != _pausedDownloads.end());
    qDebug() << "Resuming download for" << videoId;
    YTDownloadInfo* di = (*it);
    _pausedDownloads.erase(it);
    _queuedDownloads.append(di);
    di->resume();
    processQueuedDownloads();
}

void
YTLocalVideoManager::stopInProgressDownloads()
{
    if (_inProgressDownloads.isEmpty())
        return;

    qDebug() << "Stopping all running downloads";

    YTDownloadInfoList::Iterator it = _inProgressDownloads.begin();
    for (; it != _inProgressDownloads.end(); ++it) {
        (*it)->disconnect();
        (*it)->pause();
        (*it)->resume();
    }
    _queuedDownloads += _inProgressDownloads;
    _inProgressDownloads.clear();
}
