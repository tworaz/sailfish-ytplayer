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

#include "YTSqlListModel.h"

namespace {

static int kResultPageSize = 50;

} // namespace

YTSqlListModel::YTSqlListModel(QObject *parent)
    : QAbstractListModel(parent)
    , _totalRowCount(0)
    , _canFetchMore(false)
    , _searchMode(false)
{
}

void
YTSqlListModel::remove(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    const QVector<QVariant>& v = _data.at(index);
    removeFromDatabase(v);
    _data.removeAt(index);
    _totalRowCount--;
    endRemoveRows();
}

void
YTSqlListModel::search(QString query)
{
    if (query.isEmpty()) {
        reload();
        return;
    }

    QSqlQuery q = getSearchQuery(query, kResultPageSize);
    if (!q.exec()) {
        qWarning("Failed to execute search query: %s",
                 qPrintable(q.lastError().text()));
        return;
    }

    _searchMode = true;

    handleNewData(q);
}

void
YTSqlListModel::reload()
{
    _searchMode = false;

    QSqlQuery q = getTableSizeQuery();
    if (!q.exec()) {
        qWarning("Failed to get table row count : %s",
                 qPrintable(q.lastError().text()));
        return;
    }
    q.first();
    _totalRowCount = q.value(0).toInt();
    if (_totalRowCount <= 0) {
        qDebug() << "Table empty";
        return;
    }

    q = getReloadDataQuery(kResultPageSize);
    if (!q.exec()) {
        qWarning("Failed to reload model data: %s",
                 qPrintable(q.lastError().text()));
        return;
    }

    handleNewData(q);
}

void
YTSqlListModel::clear()
{
    beginRemoveRows(QModelIndex(), 0, _data.size() - 1);
    _data.clear();
    _totalRowCount = 0;
    endRemoveRows();
}

QVariant
YTSqlListModel::data(const QModelIndex& item, int role) const
{
    if (item.row() < 0 || item.row() >= _data.size())
        return QVariant();

    const QVector<QVariant> v = _data.at(item.row());
    return v.at(role - Qt::UserRole);
}

int
YTSqlListModel::rowCount(const QModelIndex&) const
{
    return _data.size();
}

bool
YTSqlListModel::canFetchMore(const QModelIndex&) const
{
    return (_data.size() < _totalRowCount) && !_searchMode;
}

void
YTSqlListModel::fetchMore(const QModelIndex&)
{
    Q_ASSERT(!_searchMode);

    const QVector<QVariant>& v = _data.last();
    QSqlQuery q = getFetchMoreQuery(v, kResultPageSize);
    if (!q.exec()) {
        qWarning("Failed to fetch more data: %s",
                 qPrintable(q.lastError().text()));
        return;
    }

    handleNewData(q, true);
}

void
YTSqlListModel::handleNewData(QSqlQuery &q, bool append)
{
    QList<QVector<QVariant> > lst;
    if (append)
        lst.append(_data);

    while (q.next()) {
        QVector<QVariant> vec;
        QSqlRecord record = q.record();
        for (int i = 0; i < record.count(); ++i)
            vec.append(record.value(i));
        lst.append(vec);
    }

    int updateEnd = qMin(_data.size(), lst.size());

    if (lst.size() < _data.size()) {
        beginRemoveRows(QModelIndex(), lst.size(), _data.size() - 1);
        _data = lst;
        endRemoveRows();
    } else if (lst.size() > _data.size()) {
        beginInsertRows(QModelIndex(), _data.size(), lst.size() - 1);
        _data = lst;
        endInsertRows();
    }

    if (updateEnd > 0) {
        QModelIndex start = QAbstractItemModel::createIndex(0, 0);
        QModelIndex end = QAbstractItemModel::createIndex(updateEnd - 1, 0);
        emit dataChanged(start, end);
    }
}
