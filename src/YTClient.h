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

#ifndef YTCLIENT_H
#define YTCLIENT_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantMap>
#include <QUrlQuery>
#include <QVariant>
#include <QObject>

class YTClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString OAuth2URL READ getOAuth2URL CONSTANT)

public:
    explicit YTClient(QObject *parent = 0);
    ~YTClient();

    Q_INVOKABLE void list(QString resource, QVariantMap params);
    Q_INVOKABLE void post(QString resource, QVariantMap params, QVariant content);
    Q_INVOKABLE void del(QString resource, QVariantMap params);

    Q_INVOKABLE void requestOAuth2Token(QString authCode);

signals:
    void error(QVariant details);
    void success(QVariant response);
    void retry();

private slots:
    void onRequestFinished(QNetworkReply *reply);
    void onNetworkAccessibleChanged(QNetworkAccessManager::NetworkAccessibility);

private:
    void refreshToken() const;
    void handleSuccess(QNetworkReply*);
    void handleError(QNetworkReply*);
    void handleTokenReply(QNetworkReply*);

    void appendCommonParams(QUrlQuery& query);

    QString getOAuth2URL() const;

    QNetworkAccessManager *_manager;
    QString _regionCode;
};

#endif // YTCLIENT_H
