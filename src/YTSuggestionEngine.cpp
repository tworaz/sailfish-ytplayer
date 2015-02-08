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

#include "YTSuggestionEngine.h"

#include <QJsonDocument>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QUrlQuery>
#include <QSqlError>
#include <QSettings>
#include <QDebug>
#include <QUrl>

#include "YTRequest.h"
#include "YTPrefs.h"

namespace  {
const char kGoogleSuggestionUrlBase[] =
    "https://suggestqueries.google.com/complete/search";
const int kMaxSuggestions = 6;

QUrl
googleSuggestionUrl(QString q)
{
    QUrl url(kGoogleSuggestionUrlBase);

    QUrlQuery query;
    query.addQueryItem("client", "firefox");
    if (QLocale::system().name() != "C") {
        query.addQueryItem("hl", QLocale::system().name());
    } else {
        query.addQueryItem("hl", "en");
    }
    query.addQueryItem("q", q);

    url.setQuery(query);

    return url;
}

void
executeSqlQuery(QSqlQuery q)
{
    if (!q.exec())
        qWarning("Failed to execute SQL query: %s",
               qPrintable(q.lastError().text()));
}

void
initDatabase()
{
    QSqlDatabase db = QSqlDatabase::database();
    if (!db.isValid())
        qFatal("Failed to open application database!");
    QStringList tables = db.tables();
    if (!tables.contains("search_history")) {
        if (!QSqlQuery().exec("CREATE TABLE search_history (query TEXT);"))
            qFatal("Failed to create search_hostory database");
    }
}

} // namespace

YTSuggestionEngine::YTSuggestionEngine(QObject *parent)
    : QObject(parent)
    , _network_access_manager(YTRequest::GetNetworkAccessManager())
    , _reply(NULL)
{
    static bool db_initialized = false;
    if (!db_initialized) {
        initDatabase();
        db_initialized = true;
    }

    QSettings settings;
    QString engine = settings.value(kSearchSuggestionEngineKey).toString();
    if (engine == kGoogleSuggestionEngine) {
        _type = GoogleEngine;
    } else {
        Q_ASSERT(engine == kHistorySuggestionEngine);
        _type = HistoryEngine;
    }
}

YTSuggestionEngine::~YTSuggestionEngine()
{
    if (_reply) {
        delete _reply;
        _reply = NULL;
    }
}

void
YTSuggestionEngine::find(QString query)
{
    if (_type == GoogleEngine) {
        findGoogleSuggestion(query);
    } else {
        Q_ASSERT(_type == HistoryEngine);
        findLocalSearchHistory(query);
    }
}

void
YTSuggestionEngine::addToHistory(QString query)
{
    if (_type != HistoryEngine)
        return;

    QSqlQuery q;
    q.prepare("SELECT count(*) FROM search_history WHERE query=?;");
    q.addBindValue(query);
    if (!q.exec()) {
        qWarning() << "Can't check if" << query
                   << "is arealdy present in search history";
        return;
    }

    Q_ASSERT(q.first());
    if (q.value(0).toInt() == 0) {
        q.prepare("INSERT INTO search_history (query) VALUES (?);");
        q.addBindValue(query);
        executeSqlQuery(q);
    }
}

void
YTSuggestionEngine::clearHistory()
{
    QMetaObject::invokeMethod(this, "onClearHistory", Qt::QueuedConnection);
}

void
YTSuggestionEngine::onClearHistory()
{
    QSqlQuery q;
    q.prepare("DELETE FROM search_history;");
    executeSqlQuery(q);
    emit historySizeChanged(0);
}

void
YTSuggestionEngine::onFinished()
{
    switch (_reply->error()) {
    case QNetworkReply::NoError:
    {
        QByteArray data = _reply->readAll();
        QJsonParseError error;
        QJsonDocument json = QJsonDocument::fromJson(data, &error);
        if (error.error != QJsonParseError::NoError) {
            qCritical() << "Failed to parse suggestion reply:" << error.errorString();
            break;
        }
        if (json.toVariant().type() != QVariant::List) {
            qCritical() << "Unknown reply type:" << json.toVariant().type();
            break;
        }
        QVariantList lst = json.toVariant().toList();
        if (lst.length() != 2) {
            qCritical() << "Unknown reply format, bad list size:" << lst.length();
            break;
        }
        QVariant suggestions = lst[1];
        if (suggestions.type() != QVariant::List) {
            qCritical() << "Suggestion item is not a list:" << suggestions.type();
            break;
        }

        emit suggestionListChanged(lst[1].toList().mid(0, kMaxSuggestions));

        break;
    }
    default:
        qCritical() << "Google suggestion request failed: " << _reply->readAll();
        break;
    }

    _reply->deleteLater();
    _reply = NULL;
}

int
YTSuggestionEngine::historySize() const
{
    QSqlQuery q;
    q.prepare("SELECT count(*) FROM search_history;");
    if (!q.exec()) {
        qCritical() << "Failed to obtain the number of history items!";
        return 0;
    }
    Q_ASSERT(q.first());
    qDebug() << "History size:" << q.value(0).toInt();
    return q.value(0).toInt();
}

void
YTSuggestionEngine::findGoogleSuggestion(QString query)
{
    if (_reply)
        delete _reply;

    QNetworkRequest request(googleSuggestionUrl(query));
    _reply = _network_access_manager.get(request);

    connect(_reply, &QNetworkReply::finished,
            this, &YTSuggestionEngine::onFinished);
}

void
YTSuggestionEngine::findLocalSearchHistory(QString query)
{
    QSqlQuery q;
    q.prepare("SELECT query FROM search_history WHERE query LIKE ? LIMIT ?;");
    query.append("%");
    q.addBindValue(query);
    q.addBindValue(kMaxSuggestions);
    executeSqlQuery(q);

    QList<QVariant> list;
    while (q.next())
        list.append(q.value("query"));

    emit suggestionListChanged(list);
}
