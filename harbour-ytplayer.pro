# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

TARGET = harbour-ytplayer

CONFIG += sailfishapp sailfishapp_no_deploy_qml # sailfishapp_i18n

QT += dbus sql concurrent qml core multimedia

SOURCES += \
    src/YTPlayer.cpp \
    src/YTUtils.cpp \
    src/YTLogger.cpp \
    src/YTPrefs.cpp  \
    src/YTRequest.cpp \
    src/YTListModel.cpp \
    src/YTNetworkManager.cpp \
    src/YTLocalVideo.cpp \
    src/YTLocalVideoData.cpp \
    src/YTLocalVideoManager.cpp \
    src/YTLocalVideoListModel.cpp \
    src/YTVideoDownloadNotification.cpp \
    src/YTVIdeoUrlFetcher.cpp \
    src/YTSuggestionEngine.cpp \
    src/YTTranslations.cpp \
    src/YTWatchedRecently.cpp \
    src/YTFavorites.cpp \
    src/YTSqlListModel.cpp \
    src/YTUpdater.cpp \
    src/YTUpdateWorker.cpp

HEADERS += \
    src/YTPlayer.h \
    src/YTUtils.h  \
    src/YTLogger.h \
    src/YTPrefs.h \
    src/YTRequest.h \
    src/YTListModel.h \
    src/YTNetworkManager.h \
    src/YTLocalVideo.h \
    src/YTLocalVideoData.h \
    src/YTLocalVideoManager.h \
    src/YTLocalVideoListModel.h \
    src/YTVideoDownloadNotification.h \
    src/YTVideoUrlFetcher.h \
    src/YTSuggestionEngine.h \
    src/YTTranslations.h \
    src/YTWatchedRecently.h \
    src/YTFavorites.h \
    src/YTSqlListModel.h \
    src/YTUpdater.h \
    src/YTUpdateWorker.h

QML_SOURCES = \
    qml/*.qml \
    qml/pages/*.qml \
    qml/cover/*.qml \
    qml/common/*.qml \
    qml/common/*.js

OTHER_FILES += \
    $$QML_SOURCES \
    harbour-ytplayer.desktop \
    scripts/get_version_str.sh \
    translations/*.ts

DISTFILES += \
    rpm/harbour-ytplayer.spec \
    rpm/harbour-ytplayer.yaml \
    translations/*.qm \
    rpm/harbour-ytplayer.changes \
    youtube-dl-lite/youtube-dl.py \
    youtube-dl-lite/youtube_dl/*.py \
    youtube-dl-lite/youtube_dl/downloader/*.py \
    youtube-dl-lite/youtube_dl/postprocessor/*.py \
    youtube-dl-lite/youtube_dl/extractor/*.py

ytdl.files = $$files($$top_srcdir/youtube-dl-lite/youtube-dl)
ytdl-y.files = $$files($$top_srcdir/youtube-dl-lite/youtube_dl/*.py)
ytdl-d.files = $$files($$top_srcdir/youtube-dl-lite/youtube_dl/downloader/*.py)
ytdl-p.files = $$files($$top_srcdir/youtube-dl-lite/youtube_dl/postprocessor/*.py)
ytdl-e.files = $$files($$top_srcdir/youtube-dl-lite/youtube_dl/extractor/*.py)
ytdl.path = /usr/share/$${TARGET}/youtube-dl-lite
ytdl-y.path = /usr/share/$${TARGET}/youtube-dl-lite/youtube_dl
ytdl-d.path = /usr/share/$${TARGET}/youtube-dl-lite/youtube_dl/downloader
ytdl-p.path = /usr/share/$${TARGET}/youtube-dl-lite/youtube_dl/postprocessor
ytdl-e.path = /usr/share/$${TARGET}/youtube-dl-lite/youtube_dl/extractor
INSTALLS += ytdl ytdl-y ytdl-d ytdl-p ytdl-e

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

include(translations/translations.pri)

VERSION_RUN = $$system(bash $${top_srcdir}/scripts/get_version_str.sh)
DEFINES += VERSION_STR=\\\"$$system(cat $${top_srcdir}/scripts/version-str)\\\"

licenses.files = $$files($$top_srcdir/LICENSE.*)
licenses.path = /usr/share/$${TARGET}/licenses
INSTALLS += licenses

lupdate_only {
SOURCES += $$QML_SOURCES
}

RESOURCES += \
    YTPlayer.qrc
