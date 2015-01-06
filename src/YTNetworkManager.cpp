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

#include "YTNetworkManager.h"

#include <QNetworkConfigurationManager>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QSharedPointer>
#include <QSettings>
#include <QDebug>

#include "YTPlayer.h"

namespace {

static QUrl kTryConnectUrl("https://www.youtube.com/index.html");

static bool
_isCellular(const QNetworkConfiguration& config)
{
    switch (config.bearerType()) {
    case QNetworkConfiguration::Bearer2G:
    case QNetworkConfiguration::BearerBluetooth:
    case QNetworkConfiguration::BearerHSPA:
    case QNetworkConfiguration::BearerCDMA2000:
    case QNetworkConfiguration::BearerWCDMA:
    case QNetworkConfiguration::BearerWiMAX:
        return true;
    default:
        return false;
    }
}

}

YTNetworkManager&
YTNetworkManager::instance()
{
    static YTNetworkManager instance;
    return instance;
}

YTNetworkManager::YTNetworkManager(QObject *parent)
    : QObject(parent)
    , _manager(new QNetworkConfigurationManager(parent))
    , _online(_manager->isOnline())
    , _cellular(true)
{
    connect(_manager, SIGNAL(onlineStateChanged(bool)),
            this, SLOT(onOnlineStateChanged(bool)));
    connect(_manager, SIGNAL(configurationChanged(QNetworkConfiguration)),
            this, SLOT(onConfigurationChanged(QNetworkConfiguration)));

    QList<QNetworkConfiguration> configs =
        _manager->allConfigurations(QNetworkConfiguration::Active);
    if (!configs.isEmpty())
        onConfigurationChanged(configs.first());
    else
        _online = false;
}

YTNetworkManager::~YTNetworkManager()
{
    delete _manager;
}

void
YTNetworkManager::tryConnect() const
{
    qDebug() << "Trying to connect to internet";
    QNetworkRequest request(kTryConnectUrl);
    GetYTApiNetworkAccessManager()->get(request);
}

void
YTNetworkManager::clearCache() {
    GetAPIResponseDiskCache()->clear();
    GetImageDiskCache()->clear();
    emit imageCacheUsageChanged();
    emit apiResponseCacheUsageChanged();
}

void
YTNetworkManager::onOnlineStateChanged(bool isOnline)
{
    if (isOnline != _online) {
        qDebug() << "Network is " << (isOnline ? "online" : "offline");
        _online = isOnline;
        emit onlineChanged(_online);
    }
}

void
YTNetworkManager::onConfigurationChanged(const QNetworkConfiguration&)
{
    QList<QNetworkConfiguration> configs =
        _manager->allConfigurations(QNetworkConfiguration::Active);

    bool cellular = true;
    QList<QNetworkConfiguration>::Iterator it;
    for (it = configs.begin(); it != configs.end(); ++it) {
        if (!_isCellular(*it)) {
            cellular = false;
            break;
        }
    }

    if (_cellular != cellular) {
        _cellular = cellular;
        emit cellularChanged(_cellular);
    }
}

qint64
YTNetworkManager::imageCacheUsage() const {
    return GetImageDiskCache()->cacheSize() / 1024;
}

qint64
YTNetworkManager::apiResponseCacheUsage() const {
    return GetAPIResponseDiskCache()->cacheSize() / 1024;
}

qint64
YTNetworkManager::imageCacheMaxSize() const {
    return GetImageDiskCache()->maximumCacheSize() / (1024 * 1024);
}

void
YTNetworkManager::setImageCacheMaxSize(qint64 size) {
    QSettings().setValue("Cache/ImageSize", size);
    GetImageDiskCache()->setMaximumCacheSize(size * 1024 * 1024);
}

qint64
YTNetworkManager::apiResponseCacheMaxSize() const {
    return GetAPIResponseDiskCache()->maximumCacheSize() / (1024 * 1024);
}

void
YTNetworkManager::setApiResponseCacheMaxSize(qint64 size) {
    QSettings().setValue("Cache/YouTubeApiResponseSize", size);
    GetAPIResponseDiskCache()->setMaximumCacheSize(size * 1024 * 1024);
}
