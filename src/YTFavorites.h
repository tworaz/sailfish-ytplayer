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

#ifndef YTFAVORITES_H
#define YTFAVORITES_H

#include <QSqlQueryModel>
#include <QHash>

class YTFavorites : public QSqlQueryModel
{
    Q_OBJECT
public:
    explicit YTFavorites(QObject *parent = 0);

    Q_INVOKABLE bool isFavorite(QString videoId);
    Q_INVOKABLE void add(QString videoId, QString title,
                         QString thumbUrl, QString duration);
    Q_INVOKABLE void remove(QString videoId);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void reset() { clear(); }

    QHash<int, QByteArray> roleNames() const { return _roleNames; }
    QVariant data(const QModelIndex &item, int role) const;

private:
    enum {
        VideoIdRole = Qt::UserRole,
        TitleRole,
        ThumbnailUrlRole,
        VideoDurationRole,
    };

    QHash<int, QByteArray> _roleNames;

    Q_DISABLE_COPY(YTFavorites)
};

#endif // YTFAVORITES_H
