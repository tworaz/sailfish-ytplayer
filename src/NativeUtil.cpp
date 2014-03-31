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
#include <QDBusMessage>
#include <QDBusArgument>
#include <sailfishapp.h>
#include <QDebug>

#include "config.h"
#include "NativeUtil.h"

static QString FALLBACK_COUNTRY_CODE = QString("US");

NativeUtil::NativeUtil(QObject *parent) :
    QObject(parent)
{
}

QString
NativeUtil::getRegionCode() const
{
	QDBusConnection systemBus = QDBusConnection::connectToBus(QDBusConnection::SystemBus, "system");
	if (systemBus.isConnected()) {
		QDBusObjectPath modem = getModemPath(systemBus);
		if (modem.path().isEmpty()) {
			qDebug() << "Failed to find modem";
			return FALLBACK_COUNTRY_CODE;
		}
		qDebug() << "Modem Path: " << modem.path();

		unsigned mcc = getMobileCountryCode(systemBus, modem);
		qDebug() << "Mobile Country Code: " << mcc;

		QJsonObject mccMap = getMobileCountryCodeMap();
		QJsonObject::Iterator iter =  mccMap.find(QString::number(mcc));
		if (iter == mccMap.end()) {
			qDebug() << "No country could be found for code " << mcc;
			return FALLBACK_COUNTRY_CODE;
		}
		QString countryCode = static_cast<QJsonValue>(*iter).toString();
		qDebug() << "Country code: " << countryCode;
		return countryCode;
	} else {
		qDebug("Failed to connect to system bus!");
	}
	return FALLBACK_COUNTRY_CODE;
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

QString
NativeUtil::getVersion() const
{
#ifdef VERSION_STR
	return QString(VERSION_STR);
#else
	return QString("Unknown");
#endif
}

QDBusObjectPath
NativeUtil::getModemPath(QDBusConnection connection)
{
	QDBusMessage msg = QDBusMessage::createMethodCall("org.ofono", "/", "org.ofono.Manager", "GetModems");
	QDBusMessage reply = connection.call(msg);

	if (reply.arguments().length() == 0)
		return QDBusObjectPath();

	if (!reply.arguments().at(0).canConvert<QDBusArgument>())
		return QDBusObjectPath();

	const QDBusArgument replyArg = reply.arguments().at(0).value<QDBusArgument>();
	Q_ASSERT(replyArg.currentType() == QDBusArgument::ArrayType);
	replyArg.beginArray();
	QDBusVariant pathVariant;
	replyArg >> pathVariant;
	replyArg.endArray();

	if (!pathVariant.variant().canConvert<QDBusObjectPath>()) {
		return QDBusObjectPath();
	}

	return pathVariant.variant().value<QDBusObjectPath>();
}

unsigned
NativeUtil::getMobileCountryCode(QDBusConnection conn, QDBusObjectPath modem)
{
	QDBusMessage msg = QDBusMessage::createMethodCall("org.ofono", modem.path(),
	                                                  "org.ofono.SimManager", "GetProperties");
	QDBusMessage reply = conn.call(msg);
	unsigned mcc = 0;

	if (reply.arguments().length() == 0)
		return 0;
	if (!reply.arguments().at(0).canConvert<QDBusArgument>())
		return 0;

	const QDBusArgument replyArg = reply.arguments().at(0).value<QDBusArgument>();
	Q_ASSERT(replyArg.currentType() == QDBusArgument::MapType);

	replyArg.beginMap();
	while (!replyArg.atEnd()) {
		QString key;
		QVariant value;
		replyArg.beginMapEntry();
		replyArg >> key >> value;
		if (key == "MobileCountryCode") {
			Q_ASSERT(value.type() == QVariant::String);
			mcc = value.toUInt();
			replyArg.endMapEntry();
			break;
		}
		replyArg.endMapEntry();
	}
	replyArg.endMap();

	return mcc;
}

QJsonObject
NativeUtil::getMobileCountryCodeMap()
{
	QString mccPath = SailfishApp::pathTo(QString("mcc-data.json")).toLocalFile();
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
	}
	return QJsonObject();
}

void
NativeUtil::preventScreenBlanking(bool prevent)
{
	QDBusConnection systemBus = QDBusConnection::connectToBus(QDBusConnection::SystemBus, "system");
	Q_ASSERT(systemBus.isConnected());
	QString request;
	if (prevent) {
		request = "req_display_blanking_pause";
		qDebug() << "Disabling display blanking";
	} else {
		request = "req_display_cancel_blanking_pause";
		qDebug() << "Enabling display blanking";
	}
	QDBusMessage msg = QDBusMessage::createMethodCall("com.nokia.mce", "/com/nokia/mce/request",
	                                                  "com.nokia.mce.request", request);
	(void)systemBus.call(msg);
}
