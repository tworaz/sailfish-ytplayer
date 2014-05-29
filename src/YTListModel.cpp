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

#include "YTListModel.h"

#include <QDebug>

YTListModel::YTListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

YTListModel::~YTListModel()
{
    clear();
}

int
YTListModel::rowCount(const QModelIndex&) const
{
    return _list.count();
}

QVariant
YTListModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= _list.size()) {
        return QVariant();
    }

    QByteArray roleName = _roles.value(role);
    if (roleName.isEmpty()) {
        qWarning() << "No item for role " << role << " found!";
        return QVariant();
    }

    QVariantMap map = _list.at(index.row()).toMap();
    Q_ASSERT(!map.isEmpty());
    return map.value(roleName);
}

QHash<int, QByteArray> YTListModel::roleNames() const
{
    Q_ASSERT(!_roles.isEmpty());
    return _roles;
}

void
YTListModel::append(QList<QVariant> list)
{
    if (list.isEmpty()) {
        return;
    }

    if (_roles.isEmpty()) {
        initializeRoles(list);
    }

    filter(list);

    beginInsertRows(QModelIndex(), _list.count(), _list.count() + list.count() - 1);
    _list.append(list);
    endInsertRows();

    emit countChanged(_list.size());
}

void
YTListModel::clear()
{
    if (_list.isEmpty()) {
        return;
    }

    _roles.clear();

    beginRemoveRows(QModelIndex(), 0, _list.size() - 1);
    _list.clear();
    endRemoveRows();
    emit countChanged(0);
}

QVariant
YTListModel::get(int i) const
{
    return _list.at(i);
}

void
YTListModel::initializeRoles(QList<QVariant>& list)
{
    Q_ASSERT(_roles.isEmpty());
    QList<QString> keys = list.first().toMap().keys();
    int idx = Qt::UserRole + 1;
    foreach (QString key, keys) {
        _roles[idx++] = key.toLocal8Bit();
    }
}

void
YTListModel::filter(QList<QVariant>& list)
{
    QString kind = list.first().toMap().value("kind").toString();

    if (kind == "youtube#videoCategory") {
        QList<QVariant>::iterator it = list.begin();
        while (it != list.end()) {
            QVariantMap map = it->toMap();
            QVariantMap snippet = map.value("snippet").toMap();
            Q_ASSERT(!snippet.isEmpty());
            if (!snippet.value("assignable").toBool()) {
                it = list.erase(it);
            } else {
                it++;
            }
        }
    }
}
