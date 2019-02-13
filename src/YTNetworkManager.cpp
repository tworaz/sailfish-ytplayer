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

#include "YTPlayer.h"
#include "YTRequest.h"

namespace {

static bool
_isCellular(const QNetworkConfiguration& config)
{
    switch (config.bearerType()) {
    case QNetworkConfiguration::Bearer2G:
    case QNetworkConfiguration::BearerHSPA:
    case QNetworkConfiguration::BearerCDMA2000:
    case QNetworkConfiguration::BearerWCDMA:
    case QNetworkConfiguration::BearerWiMAX:
    case QNetworkConfiguration::BearerEVDO:
    case QNetworkConfiguration::BearerLTE:
    case QNetworkConfiguration::Bearer3G:
    case QNetworkConfiguration::Bearer4G:
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
    , _online(_manager->isOnline() && _manager->defaultConfiguration().isValid())
    , _cellular(true)
{
    connect(_manager, SIGNAL(onlineStateChanged(bool)),
            this, SLOT(onOnlineStateChanged(bool)));
    connect(_manager, SIGNAL(configurationChanged(QNetworkConfiguration)),
            this, SLOT(onConfigurationChanged(QNetworkConfiguration)));

    QList<QNetworkConfiguration> configs =
        _manager->allConfigurations(QNetworkConfiguration::Active);
    QList<QNetworkConfiguration>::Iterator it;
    for (it = configs.begin(); it != configs.end(); ++it)
        onConfigurationChanged(*it);
}

YTNetworkManager::~YTNetworkManager()
{
    delete _manager;
    closeNetworkSession();
}

void
YTNetworkManager::tryConnect() const
{
    qDebug() << "Requesting network connection popup from lipstick";
    QDBusConnection conn = QDBusConnection::connectToBus(
        QDBusConnection::SessionBus, "session");
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "com.jolla.lipstick.ConnectionSelector", "/",
        "com.jolla.lipstick.ConnectionSelectorIf", "openConnection");
    QList<QVariant> args;
    args.append(QString("wlan"));
    msg.setArguments(args);
    conn.asyncCall(msg);
}

void
YTNetworkManager::clearCache() {
    GetAPIResponseDiskCache()->clear();
    GetImageDiskCache()->clear();
    emit imageCacheUsageChanged();
    emit apiResponseCacheUsageChanged();
}

void
YTNetworkManager::shutdown()
{
    QMutexLocker lock(&_nam_list_mutex);
    _managed_nam_list.clear();
}

void
YTNetworkManager::manageSessionFor(QNetworkAccessManager *nam)
{
    QMutexLocker lock(&_nam_list_mutex);
    connect(nam, &QNetworkAccessManager::destroyed,
            this, &YTNetworkManager::onNetworkAccessManagerDestroyed);
    _managed_nam_list.append(nam);
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
YTNetworkManager::onConfigurationChanged(const QNetworkConfiguration& config)
{
    if (config.state() == QNetworkConfiguration::Active) {
        qDebug() << "Network confg active:" << config.name();
        if (!_session || (_session && (_session->configuration() != config))) {
            qDebug() << "Active config changed, opening new network session";
            openNetworkSession(config);
        }

        bool cellular = _isCellular(config);
        if (_cellular != cellular) {
            _cellular = cellular;
            emit cellularChanged(_cellular);
        }
    } else {
        if (_session && _session->configuration() == config) {
            qDebug() << "Network config for active session deactivated, closing session";
            closeNetworkSession();
        }
    }
}

void
YTNetworkManager::onSessionOpened()
{
    qDebug() << "Network session opened";
    QMutexLocker lock(&_nam_list_mutex);
    QList<QNetworkAccessManager*>::iterator it = _managed_nam_list.begin();
    for (; it != _managed_nam_list.end(); ++it) {
        (*it)->setConfiguration(_session->configuration());
        (*it)->setNetworkAccessible(QNetworkAccessManager::Accessible);
    }
}

void
YTNetworkManager::onSessionClosed()
{
    qDebug() << "Network session closed," ;
    QMutexLocker lock(&_nam_list_mutex);
    QList<QNetworkAccessManager*>::iterator it = _managed_nam_list.begin();
    for (; it != _managed_nam_list.end(); ++it)
        (*it)->setNetworkAccessible(QNetworkAccessManager::NotAccessible);
}

void
YTNetworkManager::onNetworkAccessManagerDestroyed(QObject *obj)
{
    QMutexLocker lock(&_nam_list_mutex);
    QNetworkAccessManager *nam = static_cast<QNetworkAccessManager*>(obj);
    if (_managed_nam_list.contains(nam))
        _managed_nam_list.removeOne(nam);
}

void
YTNetworkManager::openNetworkSession(const QNetworkConfiguration &cfg)
{
    Q_ASSERT(cfg.isValid());
    closeNetworkSession();

    _session = new QNetworkSession(cfg);
    connect(_session, &QNetworkSession::opened, this, &YTNetworkManager::onSessionOpened);
    connect(_session, &QNetworkSession::closed, this, &YTNetworkManager::onSessionClosed);
    _session->open();
}

void
YTNetworkManager::closeNetworkSession()
{
    if (!_session)
        return;

    _session->close();
    delete _session;
    _session = NULL;
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
