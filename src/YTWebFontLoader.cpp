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

#include "YTWebFontLoader.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QNetworkReply>
#include <QFontDatabase>
#include <QFile>
#include <QDebug>


static QUrl kYouTubeWebFontURL = QUrl("https://www.youtube.com/s/tv/fonts/youtube-icons.ttf");

extern QSharedPointer<QNetworkAccessManager> GetNetworkAccessManager();

YTWebFontLoader::YTWebFontLoader(QObject *parent)
    : QObject(parent)
    , _loaded(false)
    , _network_access_manager(GetNetworkAccessManager())
{
    _fontPath = QStandardPaths::writableLocation(
        QStandardPaths::DataLocation).append("/youtube-icons.ttf");
}

YTWebFontLoader::~YTWebFontLoader()
{
}

void
YTWebFontLoader::load()
{
    if (_loaded) {
        return;
    }

    if (QFile::exists(_fontPath) && installFont()) {
        return;
    }

    QNetworkRequest request(kYouTubeWebFontURL);
    _reply = _network_access_manager->get(request);
    connect(_reply, SIGNAL(finished()), this, SLOT(onFinished()));
}

bool
YTWebFontLoader::installFont()
{
    if (QFontDatabase::addApplicationFont(_fontPath) < 0) {
        qCritical() << "Failed to install YouTube web font";
        return false;
    }
    _loaded = true;
    emit loadedChanged(true);
    return true;
}

void
YTWebFontLoader::onFinished()
{
    QFile fontFile(_fontPath);

    if (fontFile.open(QIODevice::WriteOnly)) {
        if (_reply->error() == QNetworkReply::NoError) {
            fontFile.write(_reply->readAll());
            fontFile.close();
            installFont();
        } else {
            qCritical() << "Failed to download font file, error: " << _reply->error();
            emit error();
        }
    } else {
        qCritical() << "Failed to open font file for writing: " << _fontPath;
        emit error();
    }

    _reply->deleteLater();
    _reply = NULL;
}
