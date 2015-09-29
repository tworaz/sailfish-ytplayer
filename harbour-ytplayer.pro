# Copyright (c) 2015 Piotr Tworek. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.YTPlayer file.

TARGET = harbour-ytplayer

CONFIG += sailfishapp sailfishapp_no_deploy_qml c++11
QT += dbus sql concurrent

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
        src/YTSqlListModel.cpp

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
        src/YTSqlListModel.h

QML_SOURCES = \
        qml/*.qml \
        qml/pages/*.qml \
        qml/cover/*.qml \
        qml/common/*.qml \
        qml/common/*.js

OTHER_FILES += \
        $$QML_SOURCES \
        harbour-ytplayer.desktop \
        scripts/mcc-data-util.py \
        scripts/generate-config-h.py \
        scripts/get_version_str.sh \
        rpm/harbour-ytplayer.spec

include(third_party/youtube_dl.pri)
include(languages/translations.pri)

KEY_FILE = $$top_srcdir/youtube-data-api-v3.key
CLIENT_ID_FILE = $$top_srcdir/youtube-client-id.json

!exists($$KEY_FILE) {
    error("YouTube data api key file not found: youtube-data-api-v3.key")
}
!exists($$CLIENT_ID_FILE) {
    warning("YouTube client ID file not found, client authotization won't work!")
}

configh.input = KEY_FILE
configh.output = $$top_builddir/config.h
configh.commands = \
    $$top_srcdir/scripts/generate-config-h.py \
            --keyfile=$$KEY_FILE \
            --idfile=$$CLIENT_ID_FILE \
            --outfile=$$top_builddir/config.h
configh.CONFIG += no_link

QMAKE_EXTRA_COMPILERS += configh
PRE_TARGETDEPS += compiler_configh_make_all

DEFINES += VERSION_STR=\\\"$$system($${top_srcdir}/scripts/get_version_str.sh)\\\"

licenses.files = $$files($$top_srcdir/LICENSE.*)
licenses.path = /usr/share/$${TARGET}/licenses
INSTALLS += licenses

lupdate_only {
SOURCES += $$QML_SOURCES
}

RESOURCES += \
    YTPlayer.qrc

mcc_data.target = mcc-data
mcc_data.commands = \
    $$top_srcdir/scripts/mcc-data-util.py \
        --keyfile=$$top_srcdir/youtube-data-api-v3.key \
        --mccfile=$$top_srcdir/resources/mcc-data.json \
        --verbose --mode check

QMAKE_EXTRA_TARGETS += mcc-data
PRE_TARGETDEPS += mcc-data
