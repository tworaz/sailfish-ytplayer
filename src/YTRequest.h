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

#ifndef YTREQUEST_H
#define YTREQUEST_H

#include <QUrl>
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QtNetwork/QNetworkReply>
#include <QSharedPointer>
#include <QtNetwork/QNetworkConfigurationManager>
#include <QtNetwork/QNetworkAccessManager>
#include <QScopedPointer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringList>
#include <QUrlQuery>
#include <QSettings>
#include <QLocale>
#include <QDebug>

#include <nemonotifications-qt5/notification.h>

#include "YTListModel.h"
#include "YTUpdater.h"

class QNetworkAccessManager;
class YTVideoUrlFetcher;

class YTRequest : public QObject
{
    Q_OBJECT

    Q_ENUMS(Method)

    Q_PROPERTY(QUrl oAuth2Url READ oAuth2Url CONSTANT)
    Q_PROPERTY(QString resource READ resource WRITE setResource)
    Q_PROPERTY(Method method READ method WRITE setMethod)
    Q_PROPERTY(QVariantMap params READ params WRITE setParams)
    Q_PROPERTY(QVariant content READ content WRITE setContent)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    Q_PROPERTY(YTListModel* model READ model WRITE setModel)

public:
    explicit YTRequest(QObject *parent = 0, QNetworkAccessManager *nam = 0);
    ~YTRequest();

    static QNetworkAccessManager& GetNetworkAccessManager();

    enum Method {
        List,
        Post,
        Delete
    };

    Q_INVOKABLE void run();
    Q_INVOKABLE void reset() { setLoaded(false); }

    void setMethod(Method method) { _method = method; }
    void setResource(QString resource) { _resource = resource; }
    void setParams(QVariantMap params) { _params = params; }
    bool isRunning() const { return _reply && _reply->isRunning(); }
    void abort() { Q_ASSERT(_reply); _reply->abort(); }

signals:
    void success(QVariant response);
    void error(QVariant details);
    void busyChanged(bool busy);
    void loadedChanged(bool loaded);

protected slots:
    void onTokenRequestFinished();
    void onFinished();
    void onURLFetcherFailed(QVariantMap);
    void onURLFetcherSucceeded(QVariantMap);

private:
    void handleSuccess(QNetworkReply*);
    void handleError(QNetworkReply*);
    void handleTokenReply(QNetworkReply*);
    bool handleVideoInfoReply(QNetworkReply*);
    void requestToken();
    void refreshToken();
    bool tryExternalStreamFetcher();

    QString resource() const { return _resource; }
    Method method() const { return _method; }
    QVariantMap params() const { return _params; }
    QVariant content() const { return _content; }
    void setContent(QVariant content) { _content = content; }
    bool busy() const { return _busy; }
    bool loaded() const { return _loaded; }
    void setModel(YTListModel *model) { _model = model; }
    YTListModel *model() const { return _model; }
    QUrl oAuth2Url();
    void setLoaded(bool);
    void setBusy(bool);

    QNetworkReply *_reply;
    QNetworkReply *_token_reply;
    YTVideoUrlFetcher *_url_fetcher;
    QNetworkAccessManager& _network_access_manager;
    QString _resource;
    Method _method;
    QVariantMap _params;
    QVariant _content;
    bool _loaded;
    bool _busy;
    YTListModel *_model;
    int _retryCount;
};

#endif // YTREQUEST_H
