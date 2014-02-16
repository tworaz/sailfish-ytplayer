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

#include <QFile>
#include <QJsonDocument>
#include <sailfishapp.h>

#include "NativeUtil.h"

NativeUtil::NativeUtil(QObject *parent) :
    QObject(parent)
{
}

QJsonObject
NativeUtil::getMcc() const
{
	QString mccPath = SailfishApp::pathTo(QString("mcc.json")).toLocalFile();
	QFile mccFile(mccPath);

	if (!mccFile.open(QIODevice::ReadOnly)) {
		qDebug("Mobile Country Code file not found, please check your installation");
		return QJsonObject();
	}

	QByteArray mccData = mccFile.readAll();
	mccFile.close();

	QJsonDocument doc = QJsonDocument::fromJson(mccData);
	if (doc.isObject()) {
		return doc.object();
	} else {
		qDebug("Invalid Mobile Country Code dictionary, please check your installation!");
		return QJsonObject();
	}
}

QString
NativeUtil::getYouTubeDataKey() const
{
#ifndef YOUTUBE_DATA_API_V3_KEY
#error "Please define YOUTUBE_DATA_API_V3_KEY"
#else
	return QString(YOUTUBE_DATA_API_V3_KEY);
#endif
}
