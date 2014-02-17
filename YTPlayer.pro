# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = YTPlayer

CONFIG += sailfishapp

SOURCES += \
        src/YTPlayer.cpp \
        src/NativeUtil.cpp

HEADERS += \
        src/NativeUtil.h

OTHER_FILES += \
        rpm/YTPlayer.spec \
        rpm/YTPlayer.yaml \
        YTPlayer.desktop \
        generate-mcc-json.py \
        qml/pages/YoutubeClientV3.js \
        qml/pages/Settings.js \
        qml/YTPlayer.qml \
        qml/cover/Default.qml \
        qml/cover/VideoOverview.qml \
        qml/pages/VideoListPage.qml \
        qml/pages/VideoOverview.qml \
        qml/pages/VideoPlayer.qml \
        qml/pages/YoutubeListItem.qml \
        qml/pages/Search.qml \
        qml/pages/VideoCategories.qml \
        qml/pages/Settings.qml \
        qml/pages/About.qml \
        qml/pages/DisplaySettings.qml

MCC_DATA = mcc.txt
mcc_data.input = MCC_DATA
mcc_data.output = mcc.json
mcc_data.variable_out = OTHER_FILES
mcc_data.commands = \
        $$top_srcdir/generate-mcc-json.py \
                -i mcc.txt -o mcc.json

QMAKE_EXTRA_COMPILERS += mcc_data

exists($${top_srcdir}/youtube-data-api-v3.key) {
        message("Using contents of yotube-data-api-v3.key")
        DEFINES += YOUTUBE_DATA_API_V3_KEY=\\\"$$cat(youtube-data-api-v3.key)\\\"
}

mcc.files = mcc.json
mcc.path = /usr/share/$${TARGET}

localization.files = $$files(languages/*.qm)
localization.path = /usr/share/$${TARGET}/languages

INSTALLS += localization mcc

TRANSLATIONS += \
        languages/en.ts

lupdate_only {
SOURCES += \
        qml/pages/YoutubeClientV3.js \
        qml/pages/Settings.js \
        qml/YTPlayer.qml \
        qml/cover/Default.qml \
        qml/cover/VideoOverview.qml \
        qml/pages/VideoListPage.qml \
        qml/pages/VideoOverview.qml \
        qml/pages/VideoPlayer.qml \
        qml/pages/YoutubeListItem.qml \
        qml/pages/Search.qml \
        qml/pages/VideoCategories.qml \
        qml/pages/Settings.qml \
        qml/pages/About.qml \
        qml/pages/DisplaySettings.qml
}
