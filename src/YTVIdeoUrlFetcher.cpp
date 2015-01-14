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

#include <QJsonDocument>
#include <sailfishapp.h>
#include <QStringList>
#include <QProcess>

#include "YTPlayer.h"

namespace {
const char kYouTubeDLBinaryName[] = "youtube-dl";
}

YTVideoUrlFetcher::YTVideoUrlFetcher()
    : QObject(0)
    , _process(0)
{
    static bool registered = false;
    if (!registered) {
        qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
        qRegisterMetaType<QProcess::ProcessError>("QProcess::ProcessError");
        registered = true;
    }
    moveToThread(GetBackgroundTaskThread());
}

void
YTVideoUrlFetcher::fetchUrlsFor(QString videoId)
{
    QMetaObject::invokeMethod(this, "onFetchUrlsFor",
        Qt::QueuedConnection, Q_ARG(QString, videoId));
}

void
YTVideoUrlFetcher::onFetchUrlsFor(QString videoId)
{
    Q_ASSERT(!_process);

    qDebug() << "Trying to obtain video urls for:" << videoId;

    QString program = SailfishApp::pathTo("bin").toLocalFile();
    program.append(QDir::separator());
    program.append(kYouTubeDLBinaryName);

    QStringList arguments;
    arguments << "--dump-json"
              << "--youtube-skip-dash-manifest"
              << "--no-cache-dir"
              << "--no-call-home"
              << "https://www.youtube.com/watch?v=" + videoId;

    qDebug() << "YouTubeDL subprocess:" << program << arguments;

    _process = new QProcess(0);
    connect(_process, SIGNAL(finished(int, QProcess::ExitStatus)),
            this, SLOT(onProcessFinished(int, QProcess::ExitStatus)));
    connect(_process, SIGNAL(error(QProcess::ProcessError)),
            this, SLOT(onProcessError(QProcess::ProcessError)));
    _process->start(program, arguments, QIODevice::ReadOnly);
}

void
YTVideoUrlFetcher::onProcessFinished(int code, QProcess::ExitStatus status)
{
    qDebug() << "youtube-dl process finished, status:" << status
             << ", exit code:" << code;
    if (status == QProcess::NormalExit) {
        if (code == 0) {
            QByteArray rawJson = _process->readAllStandardOutput();
            QJsonParseError error;
            QJsonDocument doc = QJsonDocument::fromJson(rawJson, &error);
            if (error.error != QJsonParseError::NoError) {
                qCritical() << "JSON parse error:" << error.errorString();
                emit failure();
            } else {
                Q_ASSERT(!doc.isNull());
                QVariantMap response = parseResponse(doc);
                if (response.isEmpty())
                    emit failure();
                else
                    emit success(response);
            }
        } else {
            qCritical() << "YouTubeDL process did not finish cleanly:" << code;
            qCritical() << _process->readAllStandardError();
            emit failure();
        }
    } else {
        qCritical() << "youtube-dl process has crashed!";
        emit failure();
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
    emit failure();
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
