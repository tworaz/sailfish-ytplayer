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

#include "Logger.h"

#include <QDebug>

#define LOG_CACHE_SIZE 200

static QString _log_str_arr[] = {
    QString("[DEBUG] "),
    QString("[ERROR] "),
    QString("[WARN]  "),
    QString("[INFO]  ")
};

QtMessageHandler Logger::_original_handler = NULL;
QContiguousCache<QVariantMap> *Logger::_log_cache =
        new QContiguousCache<QVariantMap>(LOG_CACHE_SIZE);

Logger::Logger(QObject *parent)
    : QObject(parent)
{
}

void
Logger::Register()
{
    _original_handler = qInstallMessageHandler(Logger::_messageHandler);
}

QVariant
Logger::getHistory() const
{
    QList<QVariant> list;
    for (int i = _log_cache->firstIndex(); i <= _log_cache->lastIndex(); ++i) {
        list.append(_log_cache->at(i));
    }
    return QVariant(list);
}

void
Logger::_log(LogType type, QString message)
{
    const QString& prefix = _log_str_arr[type];
    QString fullMessage = prefix + message;

    QVariantMap entry;
    entry.insert("type", type);
    entry.insert("message", message);
    _log_cache->append(entry);

    switch (type) {
    case LOG_DEBUG:
    case LOG_INFO:
        _original_handler(QtDebugMsg, QMessageLogContext(), fullMessage);
        return;
    case LOG_ERROR:
        _original_handler(QtCriticalMsg, QMessageLogContext(), fullMessage);
        return;
    case LOG_WARN:
        _original_handler(QtWarningMsg, QMessageLogContext(), fullMessage);
        return;
    }
}

void
Logger::_messageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
    QVariantMap entry;
    LogType type_;

    switch (type) {
    case QtDebugMsg:
        type_ = LOG_DEBUG;
        break;
    case QtWarningMsg:
        type_ = LOG_WARN;
        break;
    case QtSystemMsg:
        type_ = LOG_INFO;
        break;
    case QtFatalMsg:
    default:
        type_ = LOG_ERROR;
        break;
    }
    entry.insert("type", type_);
    entry.insert("message", msg);
    _log_cache->append(entry);

    _original_handler(type, context, msg);
}
