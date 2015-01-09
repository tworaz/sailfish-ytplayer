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

#include "YTLocalVideo.h"

#include <QDebug>

#include "YTLocalVideoManager.h"
#include "YTLocalVideoData.h"
#include "YTPlayer.h"

YTLocalVideo::YTLocalVideo(QObject *parent)
    : QObject(parent)
    , _manager(YTLocalVideoManager::instance())
{
}

void
YTLocalVideo::download(QString title)
{
    Q_ASSERT(_data);
    Q_ASSERT(status() == Initial);
    _data->setTitle(title);
    _manager.download(_data);
}

void
YTLocalVideo::remove() const
{
    Q_ASSERT(_data);
    Q_ASSERT(status() != Initial);
    _manager.removeDownload(_data->videoId());
}

void
YTLocalVideo::pause() const
{
    Q_ASSERT(_data);
    Q_ASSERT(status() == Loading);
    _manager.pauseDownload(_data->videoId());
}

void
YTLocalVideo::resume() const
{
    Q_ASSERT(_data);
    Q_ASSERT(status() == Paused);
    _manager.resumeDownload(_data->videoId());
}

void
YTLocalVideo::onInDatabaseChanged(bool inDatabase)
{
    emit canDownloadChanged(!inDatabase);
}

void
YTLocalVideo::onThumbnailUrlChanged(QUrl)
{
    _thumbnails.clear();
    emit thumbnailsChanged(thumbnails());
}

void YTLocalVideo::onVideoUrlChanged(QUrl)
{
    emit streamsChanged(streams());
}

void
YTLocalVideo::setVideoId(QString id)
{
    _videoId = id;

    _data = _manager.getDataForVideo(id);
    Q_ASSERT(!_data.isNull());

    connect(_data.data(), &YTLocalVideoData::inDatabaseChanged,
            this, &YTLocalVideo::onInDatabaseChanged);
    connect(_data.data(), &YTLocalVideoData::statusChanged,
            this, &YTLocalVideo::statusChanged);
    connect(_data.data(), &YTLocalVideoData::videoDownloadProgressChanged,
            this, &YTLocalVideo::downloadProgressChanged);
    connect(_data.data(), &YTLocalVideoData::titleChanged,
            this, &YTLocalVideo::titleChanged);
    connect(_data.data(), &YTLocalVideoData::durationChanged,
            this, &YTLocalVideo::durationChanged);
    connect(_data.data(), &YTLocalVideoData::thumbnailUrlChanged,
            this, &YTLocalVideo::onThumbnailUrlChanged);
    connect(_data.data(), &YTLocalVideoData::videoUrlChanged,
            this, &YTLocalVideo::onVideoUrlChanged);

    if (_data->inDatabase()) {
        if (!_data->title().isEmpty())
            emit titleChanged(_data->title());

        if (!_data->duration().isEmpty())
            emit durationChanged(_data->duration());

        if (_data->hasThumbnail())
            emit thumbnailsChanged(thumbnails());

        if (_data->status() != Initial)
            emit statusChanged(_data->status());
    }
}

QString
YTLocalVideo::title() const
{
    if (_data)
        return _data->title();
    return QString();
}

QString
YTLocalVideo::duration() const
{
    if (_data)
        return _data->duration();
    return QString();
}

QVariantMap
YTLocalVideo::thumbnails()
{
    if (_thumbnails.isEmpty() && _data) {
        QVariantMap entry;
        entry["url"] = _data->thumbnailUrl().toString();
        _thumbnails["default"] = entry;
    }
    return _thumbnails;
}

bool
YTLocalVideo::canDownload() const
{
    return (_data && !_data->inDatabase());
}

YTLocalVideo::Status
YTLocalVideo::status() const
{
    if (!_data)
        return Initial;
    return _data->status();
}

QVariantMap
YTLocalVideo::streams() const
{
    QVariantMap entry;
    entry["url"] = _data->videoUrl().toString();

    QVariantMap streamMap;
    streamMap[_data->quality()] = entry;

    return streamMap;
}

unsigned
YTLocalVideo::downloadProgress() const
{
    Q_ASSERT(_data);
    return _data->videoDownloadProgress();
}
