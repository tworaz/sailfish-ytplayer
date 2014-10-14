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

#include "Prefs.h"

#include <QSettings>
#include <QDebug>

Prefs::Prefs(QObject *parent)
    : QObject(parent)
{
}

void
Prefs::Initialize()
{
    QSettings settings;
    qDebug("Initializing settings");
    if (!settings.contains("SafeSearch")) {
        settings.setValue("SafeSearch", 1);
    }
    if (!settings.contains("AccountIntegration")) {
        settings.setValue("AccountIntegration", false);
    }
}

void
Prefs::set(const QString& key, const QVariant &value)
{
    QSettings settings;
    settings.setValue(key, value);
}

QVariant
Prefs::get(const QString& key)
{
    QSettings settings;
    QVariant value = settings.value(key);
    return value;
}

bool
Prefs::isAuthEnabled()
{
    QVariant auth = get("AccountIntegration");
    return auth.isValid() && auth.toBool();
}

void
Prefs::disableAuth()
{
    QSettings settings;
    settings.remove("YouTube/AccessToken");
    settings.remove("YouTube/RefreshToken");
    settings.remove("YouTube/AccessTokenType");
    settings.setValue("AccountIntegration", false);
}
