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

#ifndef YTLOCALVIDEOMANAGER_H
#define YTLOCALVIDEOMANAGER_H

#include <QSharedPointer>
#include <QScopedPointer>
#include <QNetworkReply>
#include <QWeakPointer>
#include <QObject>
#include <QMutex>
#include <QUrl>
#include <QMap>

#include "YTNetworkManager.h"

class QNetworkAccessManager;
class YTLocalVideoData;
class YTDownloadInfo;

class YTLocalVideoManager: public QObject
{
    Q_OBJECT
public:
    static YTLocalVideoManager& instance();

    QSharedPointer<YTLocalVideoData> getDataForVideo(QString videoId);

    void download(QSharedPointer<YTLocalVideoData>);
    void removeDownload(QString videoId);
    void pauseDownload(QString videoId);
    void resumeDownload(QString videoId);

signals:
    // Notifications for the UI
    void downloadFinished(QString video);
    void downloadFailed(QString video);

private slots:
    void onDownloadFinished(YTDownloadInfo*);
    void onDownloadFailed(YTDownloadInfo*);
    void onVideoDataDestroyed(QString videoId);
    void onOnlineChanged(bool);
    void onCellularChanged(bool);
    void onProcessQueuedDownloads();

    void onRestoreDownloads();
    void onDownload(QSharedPointer<YTLocalVideoData> data);
    void onRemoveDownload(QString videoId);
    void onPauseDownload(QString videoId);
    void onResumeDownload(QString videoId);

private:
    explicit YTLocalVideoManager(QObject *parent = 0);

    void processQueuedDownloads();
    void stopInProgressDownloads();

    typedef QList<YTDownloadInfo*> YTDownloadInfoList;
    typedef QMap<QString, QWeakPointer<YTLocalVideoData> > YTManagedVideosMap;

    QScopedPointer<YTNetworkManager> _networkManager;

    QMutex _managedVideosMutex;
    YTDownloadInfoList _queuedDownloads;
    YTDownloadInfoList _inProgressDownloads;
    YTDownloadInfoList _pausedDownloads;
    YTManagedVideosMap _managedVideos;
    QNetworkAccessManager* _networkAccessManager;
    bool _queueProcessingScheduled;

    Q_DISABLE_COPY(YTLocalVideoManager)
};

#endif // YTVIDEODOWNLOADER_H
