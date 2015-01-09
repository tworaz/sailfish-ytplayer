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

#ifndef YTLOCALVIDEO_H
#define YTLOCALVIDEO_H

#include <QUrl>
#include <QObject>
#include <QVariantMap>
#include <QSharedPointer>

class YTLocalVideoManager;
class YTLocalVideoData;

class YTLocalVideo: public QObject
{
    Q_OBJECT

    Q_ENUMS(Status)

    Q_PROPERTY(QString videoId READ videoId WRITE setVideoId)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QVariantMap thumbnails READ thumbnails NOTIFY thumbnailsChanged)
    Q_PROPERTY(bool canDownload READ canDownload NOTIFY canDownloadChanged)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantMap streams READ streams NOTIFY streamsChanged)
    Q_PROPERTY(unsigned downloadProgress
               READ downloadProgress
               NOTIFY downloadProgressChanged)

public:
    explicit YTLocalVideo(QObject *parent = 0);

    typedef enum {
        Initial,
        Queued,
        Loading,
        Paused,
        Downloaded
    } Status;

    Q_INVOKABLE void download(QString title);
    Q_INVOKABLE void remove() const;
    Q_INVOKABLE void pause() const;
    Q_INVOKABLE void resume() const;

signals:
    void titleChanged(QString);
    void durationChanged(QString);
    void thumbnailsChanged(QVariantMap);
    void canDownloadChanged(bool);
    void statusChanged(Status status);
    void streamsChanged(QVariantMap streams);
    void downloadProgressChanged(unsigned);

private slots:
    void onInDatabaseChanged(bool);
    void onThumbnailUrlChanged(QUrl);
    void onVideoUrlChanged(QUrl);

private:
    QString videoId() const { return _videoId; }
    void setVideoId(QString id);
    QString title() const;
    QString duration() const;
    QVariantMap thumbnails();
    bool canDownload() const;
    Status status() const;
    QVariantMap streams() const;
    unsigned downloadProgress() const;

    QString _videoId;
    QVariantMap _thumbnails;

    YTLocalVideoManager& _manager;
    QSharedPointer<YTLocalVideoData> _data;

    Q_DISABLE_COPY(YTLocalVideo)
};

#endif // YTLOCALVIDEO_H
