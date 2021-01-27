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

#include "YTLocalVideoListModel.h"

#include "YTLocalVideoManager.h"
#include "YTLocalVideo.h"

YTLocalVideoListModel::YTLocalVideoListModel(QObject *parent) :
    QSqlQueryModel(parent)
{
    _roleNames[Qt::UserRole] = "videoId";
    QString str;
    QTextStream ts(&str);
    ts << "SELECT videoId FROM local_videos ORDER BY CASE status"
       << " WHEN " << YTLocalVideo::Loading << " THEN 1"
       << " WHEN " << YTLocalVideo::Paused << " THEN 2"
       << " WHEN " << YTLocalVideo::Queued << " THEN 3"
       << " ELSE 4 END ASC, title COLLATE NOCASE";

    setQuery(str, QSqlDatabase::database());
    Q_ASSERT(lastError().type() == QSqlError::NoError);
}

QVariant
YTLocalVideoListModel::data(const QModelIndex &index, int role) const
{
    if (role < Qt::UserRole)
        return QSqlQueryModel::data(index, role);

    QSqlRecord r = record(index.row());
    return r.value(role - Qt::UserRole);
}

void
YTLocalVideoListModel::remove(int index)
{
    QMetaObject::invokeMethod(this, "onRemove",
        Qt::QueuedConnection, Q_ARG(int, index));
}

void
YTLocalVideoListModel::onRemove(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    removeRow(index);
    endRemoveRows();
}
