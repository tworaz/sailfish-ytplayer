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

#include "YTFavorites.h"

#include <QSqlDatabase>
#include <QSqlRecord>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

namespace {
const char kCreateDbQueryText[] =
    "CREATE TABLE favorites (video_id TEXT primary key,"
    "title TEXT, thumbnail_url TEXT, duration TEXT)";

const char kIsFavoriteQueryText[] =
    "SELECT count(*) FROM favorites WHERE video_id=?";

const char kAddFavoriteQueryText[] =
    "INSERT INTO favorites (video_id, title, thumbnail_url, duration)"
    "VALUES (?,?,?,?)";

const char kRemoveFavoriteQueryText[] =
    "DELETE FROM favorites WHERE video_id=?";

const char kRefreshViewQueryText[] =
    "SELECT video_id, title, thumbnail_url, duration "
    "FROM favorites ORDER BY title ASC";
}

YTFavorites::YTFavorites(QObject *parent) :
    QSqlQueryModel(parent)
{
    QSqlDatabase db = QSqlDatabase::database();
    if (!db.isValid())
        qFatal("Failed to open application database!");
    QStringList tables = db.tables();
    if (!tables.contains("favorites")) {
        if (QSqlQuery().exec(kCreateDbQueryText))
            qFatal("Failed to create favorites table!");
    }

    _roleNames[VideoIdRole] = "video_id";
    _roleNames[TitleRole] = "video_title";
    _roleNames[ThumbnailUrlRole] = "thumbnail_url";
    _roleNames[VideoDurationRole] = "video_duration";
}

bool
YTFavorites::isFavorite(QString videoId)
{
    QSqlQuery q;
    q.prepare(kIsFavoriteQueryText);
    q.addBindValue(videoId);
    if (!q.exec()) {
        qWarning("Failed to check if video %s is in favorites: %s",
                 qPrintable(videoId), qPrintable(q.lastError().text()));
        return false;
    }
    q.first();
    return  q.value(0).toInt() > 0;
}

void
YTFavorites::add(QString videoId, QString title, QString thumbUrl, QString duration)
{
    qDebug() << "Adding video" << videoId << "to favorites";
    QSqlQuery q;
    q.prepare(kAddFavoriteQueryText);
    q.addBindValue(videoId);
    q.addBindValue(title);
    q.addBindValue(thumbUrl);
    q.addBindValue(duration);
    if (!q.exec())
        qWarning("Failed to add video %s to favorites: %s",
               qPrintable(videoId), qPrintable(q.lastError().text()));
}

void
YTFavorites::remove(QString videoId)
{
    qDebug() << "Removing video" << videoId << "from favorites";
    QSqlQuery q;
    q.prepare(kRemoveFavoriteQueryText);
    q.addBindValue(videoId);
    if (!q.exec())
        qWarning("Failed to remove video %s from favorites: %s",
               qPrintable(videoId), qPrintable(q.lastError().text()));
}

QVariant
YTFavorites::data(const QModelIndex &item, int role) const
{
    if (role < Qt::UserRole)
        return QSqlQueryModel::data(item, role);
    QSqlRecord r = record(item.row());
    return r.value(role - Qt::UserRole);
}

void
YTFavorites::refresh()
{
    setQuery(kRefreshViewQueryText, QSqlDatabase::database());
    Q_ASSERT(lastError().type() == QSqlError::NoError);
}
