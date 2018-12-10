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

#ifndef YTLISTMODEL_H
#define YTLISTMODEL_H

#include <QAbstractListModel>
#include <QVariant>
#include <QHash>
#include <QList>
#include <QStringList>
#include <QDebug>

class YTListModelFilter: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString key READ key WRITE setKey)
    Q_PROPERTY(QVariant value READ value WRITE setValue)

public:
    YTListModelFilter(QObject *parent = 0) : QObject(parent) {}
    QString key() const { return _key; }
    QVariant value() const { return _value; }

private:
    void setKey(QString k) { _key = k; }
    void setValue(QVariant val) { _value = val; }

    QString _key;
    QVariant _value;
};

class YTListModel: public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(YTListModelFilter* filter READ filter CONSTANT)

public:
    explicit YTListModel(QObject *parent = 0);
    ~YTListModel();

    int rowCount(const QModelIndex& parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    void append(QList<QVariant>);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariant get(int i) const;

signals:
    void countChanged(int);

private:
    YTListModelFilter *filter() const { return _filter; }
    void initializeRoles(QList<QVariant>&);
    void filter(QList<QVariant>&);
    bool shouldFilterOut(QVariant item, QStringList tokens);

    QList<QVariant> _list;
    QHash<int, QByteArray> _roles;
    YTListModelFilter *_filter;

    Q_DISABLE_COPY(YTListModel)
};

#endif // YTLISTMODEL_H
