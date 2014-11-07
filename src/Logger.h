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

#ifndef _LOGGER_H_
#define _LOGGER_H_

#include <QPair>
#include <QObject>
#include <QString>
#include <QMessageLogContext>
#include <QVariantMap>
#include <QContiguousCache>
#include <QScopedPointer>
#include <QAbstractListModel>

class Logger : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(LogType)

public:
    enum LogType {
        LOG_DEBUG = 0,
        LOG_ERROR,
        LOG_WARN,
        LOG_INFO
    };

    explicit Logger(QObject *parent = 0);

    static void Register();

    Q_INVOKABLE void debug(QString msg) { _log(LOG_DEBUG, msg); }
    Q_INVOKABLE void error(QString msg) { _log(LOG_ERROR, msg); }
    Q_INVOKABLE void warn(QString msg)  { _log(LOG_WARN, msg); }
    Q_INVOKABLE void info(QString msg)  { _log(LOG_INFO, msg); }

    // QAbstractListModel
    int rowCount(const QModelIndex& parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

private:
    void _log(LogType, QString);
    static void _messageHandler(QtMsgType, const QMessageLogContext&, const QString&);

    static QtMessageHandler _original_handler;
    static QScopedPointer<QContiguousCache<QVariantMap> > _log_cache;
};

#endif // _LOGGER_H_
