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
#include <QDebug>


static QUrl kTryConnectUrl("https://www.youtube.com/index.html");

extern QSharedPointer<QNetworkAccessManager> GetNetworkAccessManager();

YTNetworkManager::YTNetworkManager(QObject *parent)
    : QObject(parent)
    , _manager(new QNetworkConfigurationManager(parent))
    , _online(_manager->isOnline())
{
    connect(_manager, SIGNAL(onlineStateChanged(bool)), this, SLOT(onOnlineStateChanged(bool)));
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
    GetNetworkAccessManager()->get(request);
}

bool
YTNetworkManager::isMobileNetwork() const {
    QList<QNetworkConfiguration> configs = _manager->allConfigurations(QNetworkConfiguration::Active);
    if (configs.empty()) {
        return true;
    }

    qDebug() << "Bearer type: " << configs.first().bearerTypeName();

    Q_ASSERT(configs.size() == 1);
    switch (configs.first().bearerType()) {
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

void
YTNetworkManager::onOnlineStateChanged(bool isOnline)
{
    if (isOnline != _online) {
        qDebug() << "Network is " << (isOnline ? "online" : "offline");
        _online = isOnline;
        emit onlineChanged();
    }
}
