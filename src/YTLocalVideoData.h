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

#ifndef YTLOCALVIDEODATA_H
#define YTLOCALVIDEODATA_H

#include <QSharedPointer>
#include <QString>
#include <QObject>
#include <QMutex>
#include <QFile>
#include <QUrl>

#include "YTLocalVideo.h"

class YTLocalVideoData: public QObject
{
    Q_OBJECT
public:
    YTLocalVideoData(QString& videoId, QObject* parent = 0);
    ~YTLocalVideoData();

    bool inDatabase() const;
    QString title() const;
    unsigned videoDownloadProgress() const;
    QString videoId() const;
    YTLocalVideo::Status status() const;
    QString quality() const;
    QUrl videoUrl() const;
    QUrl thumbnailUrl() const;
    bool hasThumbnail() const;

signals:
    void inDatabaseChanged(bool);
    void videoDownloadProgressChanged(unsigned);
    void statusChanged(YTLocalVideo::Status);
    void titleChanged(QString);
    void destroyed(QString);
    void thumbnailUrlChanged(QUrl);
    void videoUrlChanged(QUrl);
    void videoDataWritten();

protected:
    friend class YTDownloadInfo;
    friend class YTLocalVideoManager;

    // Called only from YTLocalVideoManager, but modifies data
    // shared with YTLocalVideo. Need to lock _mutex;
    void setTitle(QString title);
    void setThumbnailExtension(QString ext);
    void setQuality(QString q);

    // Called only from YTLocalVideoManager, does not touch any
    // data shared between threads.
    bool hasVideo() const;
    bool hasPartialVideo() const;
    qint64 videoDataSize() const;

    void remove();
    void check();

    void thumbnailDownloadFinished(QByteArray data);
    void reportVideoDownloadProgress(unsigned percentage);
    void videoDataFetched(QByteArray data);
    void videoDownloadFinished();
    void videoDownloadFailed();

    void downloadQueued();
    void downloadStarted();
    void downloadPaused();
    void downloadResumed();
    void downloadFinished();

    void removeVideoData();

private:
    void changeStatus(YTLocalVideo::Status);

    bool _inDatabase;
    bool _canReportVideoDownloadProgress;
    unsigned _videoDownloadProgress;

    mutable QMutex _mutex;
    QString _videoId;
    QString _title;
    QString _quality;
    QByteArray _videoPath;
    QSharedPointer<QFile> _videoFile;
    QString _thumbnailPath;
    QString _thumbnailExt;
    YTLocalVideo::Status _status;

    Q_DISABLE_COPY(YTLocalVideoData)
};

#endif // YTLOCALVIDEOIMPL_H
