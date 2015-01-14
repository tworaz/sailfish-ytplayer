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

#ifndef YTNETWORKMANAGER_H
#define YTNETWORKMANAGER_H

#include <QObject>
#include <QMutex>
#include <QList>

class QNetworkConfigurationManager;
class QNetworkAccessManager;
class QNetworkConfiguration;
class QNetworkSession;

class YTNetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool online READ online NOTIFY onlineChanged)
    Q_PROPERTY(bool cellular READ cellular NOTIFY cellularChanged)
    Q_PROPERTY(qint64 imageCacheUsage READ imageCacheUsage
               NOTIFY imageCacheUsageChanged)
    Q_PROPERTY(qint64 apiResponseCacheUsage READ apiResponseCacheUsage
               NOTIFY apiResponseCacheUsageChanged)
    Q_PROPERTY(qint64 imageCacheMaxSize READ imageCacheMaxSize
               WRITE setImageCacheMaxSize)
    Q_PROPERTY(qint64 apiResponseCacheMaxSize READ apiResponseCacheMaxSize
               WRITE setApiResponseCacheMaxSize)

public:
    static YTNetworkManager& instance();

    Q_INVOKABLE void tryConnect() const;
    Q_INVOKABLE void clearCache();

    void shutdown();
    bool online() const { return _online; }
    bool cellular() const { return _cellular; }
    void manageSessionFor(QNetworkAccessManager*);

signals:
    void onlineChanged(bool online);
    void cellularChanged(bool cellular);
    void imageCacheUsageChanged();
    void apiResponseCacheUsageChanged();

protected slots:
    void onOnlineStateChanged(bool isOnline);
    void onConfigurationChanged(const QNetworkConfiguration&);
    void onSessionOpened();
    void onSessionClosed();
    void onNetworkAccessManagerDestroyed(QObject*);

private:
    explicit YTNetworkManager(QObject *parent = 0);
    ~YTNetworkManager();

    void openNetworkSession(const QNetworkConfiguration&);
    void closeNetworkSession();

    // Values returned in kB
    qint64 imageCacheUsage() const;
    qint64 apiResponseCacheUsage() const;

    // Sizes are in MB
    qint64 imageCacheMaxSize() const;
    void setImageCacheMaxSize(qint64);
    qint64 apiResponseCacheMaxSize() const;
    void setApiResponseCacheMaxSize(qint64);

    QMutex _nam_list_mutex;
    QList<QNetworkAccessManager*> _managed_nam_list;
    QNetworkConfigurationManager *_manager;
    QNetworkSession *_session;
    bool _online;
    bool _cellular;
};

#endif // YTNETWORKMANAGER_H
