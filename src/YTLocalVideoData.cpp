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

#include "YTLocalVideoData.h"

#include "YTLocalVideoManager.h"
#include "YTPlayer.h"

namespace {

static const char kPartialContentSuffix[] = ".part";

void
executeSqlQuery(QSqlQuery q)
{
    if (!q.exec())
        qFatal("Failed to execute SQL query: %s", qPrintable(q.lastError().text()));
}
}

YTLocalVideoData::YTLocalVideoData(QString& videoId, QObject* parent)
    : QObject(parent)
    , _inDatabase(false)
    , _videoDownloadProgress(0)
    , _videoId(videoId)
    , _status(YTLocalVideo::Initial)
{
    QSqlQuery q;
    q.prepare("SELECT * FROM local_videos WHERE videoId=?");
    q.addBindValue(_videoId);
    executeSqlQuery(q);

    if (q.first()) {
        _inDatabase = true;
        _title = q.value("title").toString();
        _duration = q.value("duration").toString();
        _thumbnailPath = q.value("thumbnail").toString();
        _videoPath = q.value("video").toByteArray();
        _quality = q.value("quality").toString();
        _status = static_cast<YTLocalVideo::Status>(q.value("status").toInt());
        Q_ASSERT(!q.next());
    }
}

YTLocalVideoData::~YTLocalVideoData()
{
    Q_ASSERT(_videoFile.isNull());
    Q_ASSERT(_status != YTLocalVideo::Loading);
    emit destroyed(_videoId);
}

bool
YTLocalVideoData::inDatabase() const
{
    QMutexLocker lock(&_mutex);
    return _inDatabase;
}

QString
YTLocalVideoData::title() const
{
    QMutexLocker lock(&_mutex);
    return _title;
}

void
YTLocalVideoData::setTitle(QString title)
{
    QMutexLocker lock(&_mutex);
    _title = title;
    emit titleChanged(_title);
}

unsigned
YTLocalVideoData::videoDownloadProgress() const
{
    QMutexLocker lock(&_mutex);
    return _videoDownloadProgress;
}

QString
YTLocalVideoData::videoId() const
{
    QMutexLocker lock(&_mutex);
    return _videoId;
}

YTLocalVideo::Status
YTLocalVideoData::status() const
{
    QMutexLocker lock(&_mutex);
    return _status;
}

QString
YTLocalVideoData::quality() const
{
    QMutexLocker lock(&_mutex);
    return _quality;
}

QUrl
YTLocalVideoData::videoUrl() const
{
    QMutexLocker lock(&_mutex);
    return QUrl::fromLocalFile(_videoPath);
}

QUrl
YTLocalVideoData::thumbnailUrl() const
{
    QMutexLocker lock(&_mutex);
    if (!_thumbnailPath.isEmpty())
        return QUrl::fromLocalFile(_thumbnailPath);
    return QUrl();
}

bool
YTLocalVideoData::hasThumbnail() const
{
    QMutexLocker lock(&_mutex);
    return QFile(_thumbnailPath).exists();
}

QString
YTLocalVideoData::duration() const
{
    QMutexLocker lock(&_mutex);
    return _duration;
}

void
YTLocalVideoData::setThumbnailExtension(QString ext)
{
    QMutexLocker lock(&_mutex);
    _thumbnailExt = ext;
}

void
YTLocalVideoData::setQuality(QString q)
{
    QMutexLocker lock(&_mutex);
    _quality = q;
}

void
YTLocalVideoData::setDuration(QString d)
{
    QMutexLocker lock(&_mutex);
    _duration = d;
}

bool
YTLocalVideoData::hasVideo() const
{
    if (_videoPath.endsWith(kPartialContentSuffix))
        return false;
    return QFile(_videoPath).exists();
}

bool
YTLocalVideoData::hasPartialVideo() const
{
    return _videoPath.endsWith(kPartialContentSuffix) &&
        QFile(_videoPath).exists();
}

qint64
YTLocalVideoData::videoDataSize() const
{
    QFile vid(_videoPath);
    Q_ASSERT(vid.exists());
    return vid.size();
}

void
YTLocalVideoData::remove()
{
    QMutexLocker lock(&_mutex);

    Q_ASSERT(_status != YTLocalVideo::Initial);
    Q_ASSERT(_inDatabase);

    removeVideoData();
    QFile(_thumbnailPath).remove();

    QSqlQuery q;
    q.prepare("DELETE FROM local_videos WHERE videoId=?");
    q.addBindValue(_videoId);
    executeSqlQuery(q);

    _videoPath.clear();
    _thumbnailPath.clear();
    _thumbnailExt.clear();
    _quality.clear();
    _inDatabase = false;
    changeStatus(YTLocalVideo::Initial);

    emit inDatabaseChanged(false);
}

void
YTLocalVideoData::check()
{
    if (_status == YTLocalVideo::Downloaded && !QFile(_videoPath).exists()) {
        qWarning() << "Video" << _videoId << "in database, but local data in"
                   << _videoPath << "not present, removing entry from database";
        remove();
    }
}

void
YTLocalVideoData::thumbnailDownloadFinished(QByteArray data)
{
    Q_ASSERT(!_thumbnailPath.isEmpty());
    QFile thumbFile(_thumbnailPath);
    // TODO: Handle open and write failures
    thumbFile.open(QIODevice::WriteOnly);
    thumbFile.write(data);
    thumbFile.close();
    emit thumbnailUrlChanged(thumbnailUrl());
    qDebug() << "Finished downloading thumbnail for video:" << _videoId;
}

void
YTLocalVideoData::reportVideoDownloadProgress(unsigned percentage)
{
    QMutexLocker lock(&_mutex);
    if (_videoDownloadProgress != percentage) {
        _videoDownloadProgress = percentage;
        emit videoDownloadProgressChanged(percentage);
    }
}

void
YTLocalVideoData::videoDataFetched(QByteArray data)
{
    Q_ASSERT(_videoFile && _videoFile->isOpen());
    _videoFile->write(data);
}

void
YTLocalVideoData::videoDownloadFinished()
{
    _mutex.lock();

    Q_ASSERT(_videoFile->size() > 0);

    Q_ASSERT(_videoPath.endsWith(kPartialContentSuffix));
    _videoPath = _videoPath.left(_videoPath.size() - static_cast<int>(strlen(kPartialContentSuffix)));

    if (QFile(_videoPath).exists())
        QFile(_videoPath).remove();

    _videoFile->rename(_videoPath);
    _videoFile.clear();

    Q_ASSERT(!_quality.isEmpty());

    _mutex.unlock();

    QSqlQuery q;
    q.prepare("UPDATE local_videos SET video=?, quality=? WHERE videoId=?");
    q.addBindValue(_videoPath);
    q.addBindValue(_quality);
    q.addBindValue(_videoId);
    executeSqlQuery(q);

    emit videoUrlChanged(videoUrl());
    qDebug() << "Finished downloading video: " << _videoId;
}

void
YTLocalVideoData::videoDownloadFailed()
{
    QMutexLocker lock(&_mutex);

    _videoFile->remove();
    _videoFile.clear();

    changeStatus(YTLocalVideo::Queued);
}

void
YTLocalVideoData::downloadQueued()
{
    QMutexLocker lock(&_mutex);

    _status = YTLocalVideo::Queued;

    QSqlQuery q;
    q.prepare("INSERT INTO local_videos (videoId, status, title) VALUES (?, ?, ?)");
    q.addBindValue(_videoId);
    q.addBindValue(_status);
    q.addBindValue(_title);
    executeSqlQuery(q);
    _inDatabase = true;

    emit inDatabaseChanged(true);
    emit statusChanged(_status);

    qDebug() << "Video download queued, id:" << _videoId;
}

void
YTLocalVideoData::downloadStarted()
{
    Q_ASSERT(!_quality.isEmpty());
    Q_ASSERT(!_title.isEmpty());
    Q_ASSERT(!_thumbnailExt.isEmpty());
    Q_ASSERT(!_duration.isEmpty());

    QMutexLocker lock(&_mutex);

    QSettings settings;
    QString videosDir = settings.value("Download/Location").toString();
    if (!QDir(videosDir).exists())
        QDir().mkpath(videosDir);
    QString videoName = _title.trimmed() + "_" + _videoId + ".mp4";
    videoName.append(kPartialContentSuffix);
    // Title may contain slashes, but file names shouldn't
    videoName.replace(QRegularExpression("[\\/|\\\\]"), "_");
    _videoPath = videosDir.toLocal8Bit();
    _videoPath.append(QDir::separator());
    _videoPath.append(videoName.toLocal8Bit());

    QString thumbsDir = QStandardPaths::writableLocation((QStandardPaths::DataLocation));
    thumbsDir += QDir::separator();
    thumbsDir += "VideoThumbnails";
    if (!QDir(thumbsDir).exists())
        QDir().mkpath(thumbsDir);
    QString thumbName = _videoId + "." + _thumbnailExt;
    _thumbnailPath = thumbsDir + QDir::separator() + thumbName;

    QSqlQuery q;
    q.prepare("UPDATE local_videos SET video=?, thumbnail=?,"
              "quality=?, title=?, duration=? WHERE videoId=?");
    q.addBindValue(_videoPath);
    q.addBindValue(_thumbnailPath);
    q.addBindValue(_quality);
    q.addBindValue(_title);
    q.addBindValue(_duration);
    q.addBindValue(_videoId);
    executeSqlQuery(q);

    _videoFile = QSharedPointer<QFile>(new QFile(_videoPath));
    bool opened = _videoFile->open(QIODevice::WriteOnly | QIODevice::Append);
    Q_ASSERT(opened);
    changeStatus(YTLocalVideo::Loading);

    qDebug() << "Video download started, id:" << _videoId
             << ", temporary video path:" << _videoPath
             << ", thumbnail path:" << _thumbnailPath;
}

void
YTLocalVideoData::downloadPaused()
{
    QMutexLocker lock(&_mutex);

    Q_ASSERT(_status == YTLocalVideo::Loading ||
             _status == YTLocalVideo::Queued);
    // _videoFile can be NULL when pausing restored downloads from
    // YTLocalVideoManager::initialize
    if (_videoFile) {
        _videoFile->close();
        _videoFile.clear();
    }
    changeStatus(YTLocalVideo::Paused);
    qDebug() << "Video download paused, id:" << _videoId;
}

void
YTLocalVideoData::downloadResumed()
{
    QMutexLocker lock(&_mutex);

    Q_ASSERT(_status == YTLocalVideo::Paused);
    changeStatus(YTLocalVideo::Queued);
    qDebug() << "Video download resumed, id:" << _videoId;
}

void
YTLocalVideoData::downloadFinished()
{
    QMutexLocker lock(&_mutex);

    Q_ASSERT(QFile(_videoPath).exists());
    Q_ASSERT(QFile(_thumbnailPath).exists());
    changeStatus(YTLocalVideo::Downloaded);
    qDebug() << "Both video data and thumbnail finished downloading for:" << _videoId;
}

void
YTLocalVideoData::removeVideoData()
{
    if (_videoFile) {
        _videoFile->remove();
        _videoFile.clear();
    }
    else if (!_videoPath.isEmpty())
        QFile(_videoPath).remove();
}

void
YTLocalVideoData::changeStatus(YTLocalVideo::Status status)
{
    // _mutex should always be locked when calling this function
    if (_status == status)
        return;

    if (status != YTLocalVideo::Initial) {
        Q_ASSERT(_inDatabase);
        QSqlQuery q;
        q.prepare("UPDATE local_videos SET status=? WHERE videoId=?");
        q.addBindValue(status);
        q.addBindValue(_videoId);
        executeSqlQuery(q);
    }

    _status = status;
    emit statusChanged(_status);
}
