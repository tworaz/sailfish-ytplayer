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

#ifndef YTSUGGESTIONENGINE_H
#define YTSUGGESTIONENGINE_H

#include <QNetworkAccessManager>
#include <QVariant>
#include <QObject>
#include <QString>
#include <QList>

class QNetworkReply;

class YTSuggestionEngine: public QObject
{
    Q_OBJECT
    Q_PROPERTY(int historySize READ historySize NOTIFY historySizeChanged)
public:
    explicit YTSuggestionEngine(QObject *parent = 0);
    ~YTSuggestionEngine();

    Q_INVOKABLE void find(QString);
    Q_INVOKABLE void addToHistory(QString);
    Q_INVOKABLE void clearHistory();

signals:
    void suggestionListChanged(QList<QVariant> suggestionList);
    void historySizeChanged(int size);

private slots:
    void onClearHistory();
    void onFinished();

private:
    typedef enum {
        GoogleEngine,
        HistoryEngine,
    } SuggestionEngineType;

    int historySize() const;
    void findGoogleSuggestion(QString query);
    void findLocalSearchHistory(QString query);

    SuggestionEngineType _type;
    QNetworkAccessManager& _network_access_manager;
    QNetworkReply* _reply;

    Q_DISABLE_COPY(YTSuggestionEngine)
};

#endif // YTSUGGESTIONENGINE_H
