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

#ifndef YTSQLLISTMODEL_H
#define YTSQLLISTMODEL_H

#include <QAbstractListModel>
#include <QVariant>
#include <QVector>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QDebug>

class QSqlQuery;

class YTSqlListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit YTSqlListModel(QObject *parent = 0);

    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void search(QString);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void clear();

    // QAbstractListModel overrides
    QVariant data(const QModelIndex &index, int role) const;
    int rowCount(const QModelIndex&) const;
    bool canFetchMore(const QModelIndex& parent) const;
    void fetchMore(const QModelIndex& parent);

protected:
    virtual QSqlQuery getTableSizeQuery() const = 0;
    virtual QSqlQuery getReloadDataQuery(int limit) const = 0;
    virtual QSqlQuery getSearchQuery(const QString& query, int limit) const = 0;
    virtual QSqlQuery getFetchMoreQuery(const QVector<QVariant>& lastRow, int limit) const = 0;
    virtual void removeFromDatabase(const QVector<QVariant>&) = 0;

    void handleNewData(QSqlQuery& q, bool append = false);

    QList<QVector<QVariant> > _data;
    int _totalRowCount;
    bool _canFetchMore;
    bool _searchMode;

    Q_DISABLE_COPY(YTSqlListModel)
};

#endif // YTSQLLISTMODEL_H
