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

#include "YTPrefs.h"

#include "YTLocalVideoManager.h"

const char kWiFiOnly[] = "WiFi";
const char kCellularOnly[] = "Cellular";
const char kWiFiAndCellular[] = "WiFi+Cellular";

const char kSearchSuggestionEngineKey[] = "Search/SuggestionEngine";
const char kHistorySuggestionEngine[] = "History";
const char kGoogleSuggestionEngine[] = "Google";

const char kLanguageKey[] = "Language";

YTPrefs::YTPrefs(QObject *parent)
    : QObject(parent)
{
}

void
YTPrefs::initialize()
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

    if (!settings.contains("Player/ControlsHideDelay"))
        settings.setValue("Player/ControlsHideDelay", 3000);
    if (!settings.contains("Player/AutoPause"))
        settings.setValue("Player/AutoPause", true);
    if (!settings.contains("Player/DefaultQualityWiFi"))
        settings.setValue("Player/DefaultQualityWiFi", "720p");
    if (!settings.contains("Player/DefaultQualityCellular"))
        settings.setValue("Player/DefaultQualityCellular", "360p");
    if (!settings.contains("Player/AutoLoad"))
        settings.setValue("Player/AutoLoad", "WiFi");

    if (!settings.contains(kSearchSuggestionEngineKey))
        settings.setValue(kSearchSuggestionEngineKey,
                          kHistorySuggestionEngine);


    if (!settings.contains("YouTube/DataURL"))
        settings.setValue("YouTube/DataURL", "https://www.googleapis.com/youtube/v3/");
    if (!settings.contains("YouTube/VideoInfoURL"))
        settings.setValue("YouTube/VideoInfoURL","http://www.youtube.com/get_video_info");

    // Not the best place to read and handle the JSON code, but here it is.
    QFile keyFile(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + QDir::separator() + "youtube-data-api-v3.key");
    QFile dataApiFile(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + QDir::separator() + "youtube-client-id.json");
    if(keyFile.exists() && dataApiFile.exists() &&
            keyFile.open(QFile::ReadOnly) && dataApiFile.open(QFile::ReadOnly)) {
        qDebug() << "Trying to proccess youtube-client-id.json...";
        QJsonParseError jsonError;
        QByteArray bytes = dataApiFile.readAll();
        QJsonDocument dataJsonD = QJsonDocument::fromJson(bytes, &jsonError);
        qDebug() << "JSON parse result:" << jsonError.errorString();

        QJsonObject installed = dataJsonD.object().value(QString("installed")).toObject();
        settings.setValue("YouTube/AuthURI", installed["auth_uri"].toString());
        qDebug() << "AuthURI" << settings.value("YouTube/AuthURI");
        settings.setValue("YouTube/TokenUri",installed["token_uri"].toString());
        qDebug() << "TokenUri" <<  settings.value("YouTube/TokenUri");
        settings.setValue("YouTube/RedirectURI", installed["redirect_uris"].toArray()[0].toString());
        qDebug() << "RedirectURI" <<  settings.value("YouTube/RedirectURI");

        settings.setValue("YouTube/ClientID", installed["client_id"].toString());
        qDebug() << "ClientID" <<  settings.value("YouTube/ClientID");
        settings.setValue("YouTube/ClientSecret", installed["client_secret"].toString());
        qDebug() << "ClientSecret" <<  settings.value("YouTube/ClientSecret");

        QString oldKey = settings.value("YouTube/DataAPIv3Key","").toString();

        qDebug() << "Trying to proccess youtube-client-id.json...";
        settings.setValue("YouTube/DataAPIv3Key", QString(keyFile.readAll()).toUtf8());
        qDebug() << "DataAPIv3Key" <<  settings.value("YouTube/DataAPIv3Key");

        if(settings.value("YouTube/DataAPIv3Key").toString().count() == 0
                || settings.value("YouTube/ClientSecret").toString().count() == 0
                || settings.value("YouTube/ClientID").toString().count() == 0) {
            Notification notification;
            notification.setAppName("YTPlayer");
            notification.setAppIcon("harbour-ytplayer");
            //: Error while parsing user-supplied json and key files
            //% "Could not parse %1 or %2"
            notification.setPreviewBody(qtTrId("ytplayer-msg-error-parsing-json")
                                        .arg("youtube-client-id.json", "youtube-data-api-v3.key"));
            notification.publish();
        }
        else if(oldKey != settings.value("YouTube/DataAPIv3Key").toString()) {
            settings.remove("YouTube/AccessToken");
            settings.remove("YouTube/RefreshToken");
            settings.remove("YouTube/AccessTokenType");
            settings.setValue("AccountIntegration", false);
        }
    }
    else if(settings.value("YouTube/DataAPIv3Key").toString().count() == 0
            || settings.value("YouTube/ClientSecret").toString().count() == 0
            || settings.value("YouTube/ClientID").toString().count() == 0) {
        Notification notification;
        notification.setAppName("YTPlayer");
        //: User hasn't provided the .json and .key files in Downloads directory
        //% "Files %1 and %2 not found in Downloads folder"
        notification.setPreviewBody(qtTrId("ytplayer-msg-error-json-files-not-found")
                                    .arg("youtube-client-id.json", "youtube-data-api-v3.key"));
        notification.publish();
    }
    if(keyFile.isOpen())
        keyFile.close();
    if(dataApiFile.isOpen())
        dataApiFile.close();
}

void
YTPrefs::set(const QString& key, const QVariant &value)
{
    QSettings settings;
    settings.setValue(key, value);
}

QVariant
YTPrefs::get(const QString& key)
{
    QSettings settings;
    QVariant value = settings.value(key);
    return value;
}

bool
YTPrefs::getBool(const QString& key)
{
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Bool));
    return value.toBool();
}

int
YTPrefs::getInt(const QString& key)
{
    QVariant value = get(key);
    Q_ASSERT(value.canConvert(QVariant::Int));
    return value.toInt();
}

bool
YTPrefs::isAuthEnabled()
{
    QVariant auth = get("AccountIntegration");
    return auth.isValid() && auth.toBool();
}

void
YTPrefs::disableAuth()
{
    QSettings settings;
    settings.remove("YouTube/AccessToken");
    settings.remove("YouTube/RefreshToken");
    settings.remove("YouTube/AccessTokenType");
    settings.setValue("AccountIntegration", false);
}

void
YTPrefs::notifyDownloadSettingsChanged() const
{
    YTLocalVideoManager::instance().downloadSettingsChanged();
}
