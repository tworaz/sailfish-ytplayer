# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-ytplayer

CONFIG += sailfishapp
QT += dbus

SOURCES += \
        src/YTPlayer.cpp \
        src/NativeUtil.cpp \
        src/Logger.cpp

HEADERS += \
        src/NativeUtil.h \
        src/Logger.h

OTHER_FILES += \
        scripts/generate-mcc-json.py \
        scripts/generate-config-h.py \
        scripts/get_version_str.sh \
        harbour-ytplayer.desktop \
        rpm/harbour-ytplayer.yaml \
        rpm/harbour-ytplayer.spec \
        qml/YTPlayer.qml \
        qml/common/KeyValueLabel.qml \
        qml/common/AsyncImage.qml \
        qml/common/StatItem.qml \
        qml/common/Helpers.js \
        qml/cover/Default.qml \
        qml/cover/VideoOverview.qml \
        qml/cover/VideoPlayer.qml \
        qml/cover/ChannelBrowser.qml \
        qml/cover/CategoryVideoList.qml \
        qml/pages/YoutubeClientV3.js \
        qml/pages/Settings.js \
        qml/pages/duration.js \
        qml/pages/VideoOverview.qml \
        qml/pages/VideoPlayer.qml \
        qml/pages/Search.qml \
        qml/pages/VideoCategories.qml \
        qml/pages/Settings.qml \
        qml/pages/About.qml \
        qml/pages/ConnectionRetryTimer.qml \
        qml/pages/ChannelBrowser.qml \
        qml/pages/VideoController.qml \
        qml/pages/CategoryVideoList.qml \
        qml/pages/YTListItem.qml \
        qml/pages/YTVideoList.qml \
        qml/pages/YTOAuth2.qml

include(third_party/notifications.pri)

!exists($${top_srcdir}/youtube-data-api-v3.key) {
    error("YouTube data api key file not found: youtube-data-api-v3.key")
}
!exists($${top_srcdir}/youtube-client-id.json) {
    warning("YouTube client ID file not found, client authotization won't work!")
}

# mobile county code json target
mcc_data.target = mcc-data.json
mcc_data.commands = \
    $$top_srcdir/scripts/generate-mcc-json.py \
            -i $$top_srcdir/mcc.txt \
            -o $$top_builddir/mcc-data.json
mcc_data.depends = $$top_srcdir/mcc.txt

# config.h target
config_h.target = config.h
config_h.commands = \
    $$top_srcdir/scripts/generate-config-h.py \
            --keyfile=$$top_srcdir/youtube-data-api-v3.key \
            --idfile=$$top_srcdir/youtube-client-id.json \
            --outfile=$$top_builddir/config.h
config_h.depends = \
    $$top_srcdir/youtube-data-api-v3.key \
    $$top_srcdir/youtube-client-id.json

QMAKE_EXTRA_TARGETS += config_h mcc_data
PRE_TARGETDEPS += config.h mcc-data.json

DEFINES += VERSION_STR=\\\"$$system($${top_srcdir}/scripts/get_version_str.sh)\\\"

mcc.files = $$top_builddir/mcc-data.json
mcc.path = /usr/share/$${TARGET}

artwork.files = $$files(images/*)
artwork.path = /usr/share/$${TARGET}/images

localization.files = $$files(languages/*.qm)
localization.path = /usr/share/$${TARGET}/languages

INSTALLS += localization mcc artwork

TRANSLATIONS += \
        languages/en.ts

lupdate_only{
SOURCES += \
        qml/*.qml \
        qml/cover/*.qml \
        qml/pages/*.qml \
        qml/pages/*.js
}
