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

#include "YTWatchedRecently.h"

#include <QSqlDatabase>
#include <QSqlRecord>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

namespace {

const int kMaximumDatabaseRows = 500;

const char kCreateDBQueryText[] =
    "CREATE TABLE watched_recently (video_id TEXT primary key,"
     "title TEXT, thumbnail_url TEXT, duration TEXT,"
     "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)";

const char kInsertDataQueryText[] =
    "INSERT OR REPLACE INTO watched_recently"
    "(video_id, title, duration, thumbnail_url) VALUES (?,?,?,?)";

const char kReloadDataQueryText[] =
    "SELECT video_id, title, thumbnail_url, duration, timestamp "
    "FROM watched_recently ORDER BY timestamp DESC LIMIT ?";

const char kTrimQueryText[] =
    "DELETE FROM watched_recently WHERE video_id IN "
    "(SELECT video_id FROM watched_recently ORDER BY timestamp ASC LIMIT ?)";

const char kTableSizeQueryText[] =
    "SELECT count(*) from watched_recently";

const char kLoadMoreDataQueryText[] =
    "SELECT video_id, title, thumbnail_url, duration, timestamp "
    "FROM watched_recently WHERE timestamp<? "
    "ORDER BY timestamp DESC LIMIT ?";

const char kSearchQueryText[] =
   "SELECT video_id, title, thumbnail_url, duration, timestamp "
   "FROM watched_recently WHERE title LIKE ? COLLATE NOCASE "
   "ORDER BY timestamp DESC LIMIT ?";

const char kDeleteAllQueryText[] =
   "DELETE FROM watched_recently";

} // namespace

YTWatchedRecently::YTWatchedRecently(QObject *parent)
    : YTSqlListModel(parent)
{
    QSqlDatabase db = QSqlDatabase::database();
    if (!db.isValid())
        qFatal("Failed to open application database!");
    QStringList tables = db.tables();
    if (!tables.contains("watched_recently")) {
        if (!QSqlQuery().exec(kCreateDBQueryText))
            qFatal("Failed to create watched_recently database");
    }

    _roleNames[VideoIdRole] = "video_id";
    _roleNames[TitleRole] = "video_title";
    _roleNames[ThumbnailUrlRole] = "thumbnail_url";
    _roleNames[VideoDurationRole] = "video_duration";

    QSqlQuery q;
    q.prepare(kTableSizeQueryText);
    if (q.exec() && q.first() && (q.value(0).toInt() > kMaximumDatabaseRows)) {
        int drop_count = q.value(0).toInt() - kMaximumDatabaseRows;
        qDebug() << "Watched recently table has more than"
                 << kMaximumDatabaseRows << "trimming it";
        q.finish();
        q.prepare(kTrimQueryText);
        q.addBindValue(drop_count);
        if (!q.exec())
            qWarning() << "Failed to trim watched_recently database:" << q.lastError();
    }
}

void
YTWatchedRecently::addVideo(QString videoId, QString title, QString thumb_url, QString duration)
{
    QSqlQuery q;
    q.prepare(kInsertDataQueryText);
    q.addBindValue(videoId);
    q.addBindValue(title);
    q.addBindValue(duration);
    q.addBindValue(thumb_url);
    if (!q.exec())
        qWarning("Failed to execute SQL query: %s",
                 qPrintable(q.lastError().text()));
}

QSqlQuery
YTWatchedRecently::getTableSizeQuery() const
{
    QSqlQuery q;
    q.prepare(kTableSizeQueryText);
    return q;
}

QSqlQuery
YTWatchedRecently::getReloadDataQuery(int limit) const
{
    QSqlQuery q;
    q.prepare(kReloadDataQueryText);
    q.addBindValue(limit);
    return q;
}

QSqlQuery
YTWatchedRecently::getSearchQuery(const QString& query, int limit) const
{
    QSqlQuery q;
    q.prepare(kSearchQueryText);
    QString newQuery = query;
    newQuery.prepend("%");
    newQuery.append("%");
    q.addBindValue(newQuery);
    q.addBindValue(limit);
    return q;
}

QSqlQuery
YTWatchedRecently::getFetchMoreQuery(const QVector<QVariant>& lastRow, int limit) const
{
    QVariant lastTimestamp = lastRow.at(TimestampRole - Qt::UserRole);
    QSqlQuery q;
    q.prepare(kLoadMoreDataQueryText);
    q.addBindValue(lastTimestamp);
    q.addBindValue(limit);
    return q;
}

void
YTWatchedRecently::removeAllFromDatabase()
{
    QSqlQuery q;
    q.prepare(kDeleteAllQueryText);
    if (!q.exec())
        qCritical("Failed to execute SQL query: %s",
                  qPrintable(q.lastError().text()));
}
