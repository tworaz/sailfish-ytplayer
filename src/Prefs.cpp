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
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

#include "YTLocalVideoManager.h"

const char kWiFiOnly[] = "WiFi";
const char kCellularOnly[] = "Cellular";
const char kWiFiAndCellular[] = "WiFi+Cellular";

const char kSearchSuggestionEngineKey[] = "Search/SuggestionEngine";
const char kHistorySuggestionEngine[] = "History";
const char kGoogleSuggestionEngine[] = "Google";

const char kLanguageKey[] = "Language";

Prefs::Prefs(QObject *parent)
    : QObject(parent)
{
}

void
Prefs::initialize()
{
    QSettings settings;
    qDebug("Initializing settings");

    if (!settings.contains("AccountIntegration"))
        settings.setValue("AccountIntegration", false);

    if (!settings.contains("Cache/ImageSize"))
        settings.setValue("Cache/ImageSize", 10);
    if (!settings.contains("Cache/YouTubeApiResponseSize"))
        settings.setValue("Cache/YouTubeApiResponseSize", 3);

    if (!settings.contains("Download/Quality"))
        settings.setValue("Download/Quality", "720p");
    if (!settings.contains("Download/ConnectionType"))
        settings.setValue("Download/ConnectionType", kWiFiOnly);
    if (!settings.contains("Download/ResumeOnStartup"))
        settings.setValue("Download/ResumeOnStartup", true);
    if (!settings.contains("Download/MaxConcurrentDownloads"))
        settings.setValue("Download/MaxConcurrentDownloads", 1);
    if (!settings.contains("Download/Location")) {
        QString dir = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
        dir += QDir::separator();
        dir += "YTPlayer";
        settings.setValue("Download/Location", dir);
    }

    if (!settings.contains(kSearchSuggestionEngineKey))
        settings.setValue(kSearchSuggestionEngineKey,
                          kHistorySuggestionEngine);
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
Prefs::getBool(const QString& key)
{
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Bool));
    return value.toBool();
}

int
Prefs::getInt(const QString& key)
{
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Int));
    return value.toInt();
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

void
Prefs::notifyDownloadSettingsChanged() const
{
    YTLocalVideoManager::instance().downloadSettingsChanged();
}
