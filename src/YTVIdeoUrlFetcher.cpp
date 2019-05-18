/*-
 * Copyright (c) 2015 Peter Tworek
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

#include "YTVideoUrlFetcher.h"
#include "YTPlayer.h"

namespace {
const int kMaxResponseCacheSize = 20;
const char kYouTubeDLBinaryName[] = "youtube-dl";

    QString getYouTubeDLPath()
    {
        static QString program;
        if (program.isEmpty()) {
            program = "/usr/bin/python3";
            Q_ASSERT(QFile(program).exists());
        }
        return program;
    }
}

QCache<QString, QVariantMap> YTVideoUrlFetcher::_response_cache;
QString YTVideoUrlFetcher::_version_str;
bool YTVideoUrlFetcher::_works = false;

YTVideoUrlFetcher::YTVideoUrlFetcher()
    : QObject(0)
    , _process(0)
{
    Q_ASSERT(QFile(QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+kYouTubeDLBinaryName).exists());

    static bool registered = false;
    if (!registered) {
        qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
        qRegisterMetaType<QProcess::ProcessError>("QProcess::ProcessError");
        _response_cache.setMaxCost(kMaxResponseCacheSize);
        registered = true;
    }
    moveToThread(GetBackgroundTaskThread());
}

void
YTVideoUrlFetcher::runInitialCheck()
{
    QStringList arguments;
    arguments << QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+kYouTubeDLBinaryName
              << "--version";

    QProcess process;
    process.start(getYouTubeDLPath(), arguments, QIODevice::ReadOnly);
    process.waitForFinished();

    if (process.exitStatus() == QProcess::NormalExit &&
        process.exitCode() == 0) {
        _version_str = process.readAllStandardOutput();
        _version_str = _version_str.simplified();
        _works = true;
        qDebug() << "youtube-dl works, current version:" << _version_str;
    } else {
        qWarning() << "youtube-dl is non functional:" << process.readAllStandardError();
    }
}

void
YTVideoUrlFetcher::fetchUrlsFor(QString videoId)
{
    Q_ASSERT(_works);
    QMetaObject::invokeMethod(this, "onFetchUrlsFor",
        Qt::QueuedConnection, Q_ARG(QString, videoId));
}

void
YTVideoUrlFetcher::onFetchUrlsFor(QString videoId)
{
    Q_ASSERT(!_process);

    qDebug() << "Trying to obtain video urls for:" << videoId;

    if (_response_cache.contains(videoId)) {
        qDebug() << "Response for" << videoId << "available in cache, using it";
        QVariantMap response = *_response_cache[videoId];
        emit success(response);
        return;
    }

    QStringList arguments;
    arguments << QStandardPaths::writableLocation(QStandardPaths::DataLocation)+QDir::separator()+QDir::separator()+kYouTubeDLBinaryName
              << "--dump-json"
              << "--youtube-skip-dash-manifest"
              << "--no-cache-dir"
              << "--no-call-home"
              << "https://www.youtube.com/watch?v=" + videoId;

    qDebug() << "YouTubeDL subprocess:" << getYouTubeDLPath() << arguments;

    _process = new QProcess(0);
    connect(_process, SIGNAL(finished(int, QProcess::ExitStatus)),
            this, SLOT(onProcessFinished(int, QProcess::ExitStatus)));
    connect(_process, SIGNAL(error(QProcess::ProcessError)),
            this, SLOT(onProcessError(QProcess::ProcessError)));
    _process->start(getYouTubeDLPath(), arguments, QIODevice::ReadOnly);
}

void
YTVideoUrlFetcher::onProcessFinished(int code, QProcess::ExitStatus status)
{
    qDebug() << "youtube-dl process finished, status:" << status
             << ", exit code:" << code;
    if (status == QProcess::NormalExit && code == 0) {
        QByteArray response = _process->readAllStandardOutput();
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(response, &error);
        if (error.error != QJsonParseError::NoError) {
            qCritical() << "JSON parse error:" << error.errorString();
            emit failure(QVariantMap());
        } else {
            Q_ASSERT(!doc.isNull());
            QVariantMap response = parseResponse(doc);
            if (!response.isEmpty()) {
                QVariantMap map = doc.toVariant().toMap();
                Q_ASSERT(!map.isEmpty() && map.contains("id"));
                _response_cache.insert(map["id"].toString(), new QVariantMap(response));
                emit success(response);
            } else {
                qCritical() << "Invalid youtube-dl JSON response: " << response;
                emit failure(QVariantMap());
            }
        }
    } else {
        QByteArray response = _process->readAllStandardError();
        qCritical() << "YouTubeDL process did not finish cleanly:" << response;
        QString reason;
        if (response.contains("YouTube said:")) {
            QRegExp rx("YouTube\\ssaid:\\s(.*)$");
            rx.indexIn(response, 0);
            reason = rx.cap(1).simplified();
        }

        QVariantMap map;
        if (!response.isEmpty()) {
            map["message"] = reason;
        }
        emit failure(map);
    }
    delete _process;
    _process = NULL;
}

void
YTVideoUrlFetcher::onProcessError(QProcess::ProcessError error)
{
    qCritical() << "Process error:" << error;
    delete _process;
    _process = NULL;
    emit failure(QVariantMap());
}

YTVideoUrlFetcher::~YTVideoUrlFetcher()
{
    if (_process) {
        _process->disconnect();
        _process->kill();
        _process->waitForFinished();
        _process->deleteLater();
        _process = NULL;
    }
}

QVariantMap
YTVideoUrlFetcher::parseResponse(QJsonDocument doc)
{
    Q_ASSERT(doc.isObject());
    QVariantMap map = doc.object().toVariantMap();

    if (!map.contains("formats")) {
        qCritical() << "Output JSON does not contain formats array";
        return QVariantMap();
    }

    QVariant formats = map["formats"];
    if (formats.type() != QVariant::List) {
        qCritical() << "Formats is not an array!" << formats.type();
        return QVariantMap();
    }

    QVariantMap response;
    QVariantList lst = formats.toList();
    QVariantList::iterator it = lst.begin();
    for (;it != lst.end(); ++it) {
        QVariantMap entry = it->toMap();
        if (entry.isEmpty())
            continue;
        if (!entry.contains("format_id") || !entry.contains("url"))
            continue;

        QVariantMap details;
        details["url"] = entry["url"];

        int itag = entry["format_id"].toInt();
        switch (itag) {
        case 18:
            response.insert("360p", details);
            break;
        case 22:
            response.insert("720p", details);
            break;
        case 37:
            response.insert(("1080p"), details);
            break;
        }
    }

    return response;
}
