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

#include "YTTranslations.h"

#include <QGuiApplication>
#include <QJsonDocument>
#include <QSettings>
#include <QLocale>
#include <QDebug>
#include <QFile>
#include <sailfishapp.h>

#include "Prefs.h"

namespace {
QVariantMap
GetTranslationsMap()
{
    QFile file(":/translations.json");

    file.open(QIODevice::ReadOnly);
    Q_ASSERT(file.isOpen());

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    Q_ASSERT(error.error == QJsonParseError::NoError);

    file.close();

    return doc.toVariant().toMap();
}

bool
ContainsTranslation(QVariantList list, QString language)
{
    foreach(QVariant item, list) {
        QVariantMap map = item.toMap();
        Q_ASSERT(!map.isEmpty() && map.contains("code"));
        if (map["code"].toString() == language)
            return true;
    }
    return false;
}
}

QTranslator YTTranslations::_translator;
QString YTTranslations::_language;

YTTranslations::YTTranslations(QObject *parent) :
    QObject(parent)
{
}

bool
YTTranslations::initialize()
{
    QString locale = QLocale::system().name();
    QString dir = SailfishApp::pathTo(QString("languages")).toLocalFile();

    qDebug() << "System locale is:" << locale;

    QVariantMap top = GetTranslationsMap();
    Q_ASSERT(!top.isEmpty() && top.contains("default") && top.contains("items"));

    QVariantList translations = top["items"].toList();

    _language = top["default"].toString();
    QVariant user_lang = QSettings().value(kLanguageKey);

    if (user_lang.isValid() &&
        ContainsTranslation(translations, user_lang.toString())) {
        _language = user_lang.toString();
    } else if (ContainsTranslation(translations, locale)) {
        _language = locale;
    }

    if (!_translator.load(_language, dir)) {
        qCritical() << "Failed to load translation:" << _language;
        return false;
    }

    return QGuiApplication::installTranslator(&_translator);
}

QVariantList
YTTranslations::items() const
{
    QVariantMap top = GetTranslationsMap();
    Q_ASSERT(top.contains("items"));

    QVariantList items = top["items"].toList();
    Q_ASSERT(!items.isEmpty());

    return items;
}

QString
YTTranslations::language()
{
    Q_ASSERT(!_language.isEmpty());
    return _language;
}

void
YTTranslations::setLanguage(QString lang)
{
    QString locale = QLocale::system().name();

    qDebug() << "Language changed to:" << lang << ", system locale:" << locale;
    _language = lang;

    if (locale == lang) {
        qDebug() << "Selected language matches current system one";
        QSettings().remove(kLanguageKey);
    } else {
        QSettings().setValue(kLanguageKey, lang);
    }

    QString dir = SailfishApp::pathTo(QString("languages")).toLocalFile();
    _translator.load(lang, dir);

    emit languageChanged(lang);
}
