// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import Sailfish.Media 1.0
import harbour.ytplayer 1.0
import Nemo.Notifications 1.0
import "../common/Helpers.js" as H
import "../common"

Page {
    id: page
    allowedOrientations: Qt.application.active ? Orientation.All : Orientation.Portrait
    showNavigationIndicator: header.opacity > 0

    // Set by parent page
    property string videoId
    property alias title: header.title
    property YTLocalVideo localVideo
    property bool isAttached: true

    // Set by this page, but used outside
    property variant streams

    signal playbackStarted()
    signal noStreamsAvailable()

    Component.onCompleted: {
        Log.debug("Video player page created")
        if (localVideo.status !== YTLocalVideo.Downloaded) {
            flickable.showStatusIndicator(true)
            //: Status message indicating video player is looking for audio/video streams
            //% "Looking for streams"
            statusIndicator.text = qsTrId("ytplayer-status-looking-for-streams")
            streamRequest.run()
        } else {
            page.streams = localVideo.streams
            bottomMenu.handleNewStreams(localVideo.streams)
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // Transparent cover
            requestCoverPage()
            controlsTimer.startIfNeeded()
            if (mediaPlayer.source)
                mediaPlayer.play()
        } else if (status === PageStatus.Deactivating) {
            if (mediaPlayer.playing)
                mediaPlayer.pause()
        }
    }

    onOrientationChanged: {
        controlsTimer.startIfNeeded()
        if ((page.orientation === Orientation.Portrait ||
             page.orientation === Orientation.PortraitInverted) &&
            Qt.application.active) {
            flickable.showControls(true)
        }
    }

    Connections {
        target: page.localVideo
        onStatusChanged: {
            if (localVideo.status === YTLocalVideo.Downloaded) {
                if (mediaPlayer.playing)
                    mediaPlayer.savePosition()
                bottomMenu.handleNewStreams(localVideo.streams)
            }
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (!Qt.application.active) {
                if (priv.pausePlayackOnDectivate && mediaPlayer.playing)
                    mediaPlayer.pause()
                flickable.showControls(false)
                screenBlanking.prevent(false)
            } else {
                flickable.showControls(true)
                controlsTimer.startIfNeeded()
                screenBlanking.prevent(mediaPlayer.playing)
            }
        }
    }

    QtObject {
        id: priv
        readonly property bool controlsVisible: progressSlider.opacity === 1.0
        readonly property int controlsHideDelay: YTPrefs.get("Player/ControlsHideDelay")
        readonly property bool pausePlayackOnDectivate: YTPrefs.getBool("Player/AutoPause")
    }

    Notification {
        id: noStreamsNotification
        //: Notification summary informing the user direct video playback is not possible
        //% "No video streams available"
        previewSummary: qsTrId("ytplayer-msg-direct-playback-impossible")
        //: Notification body explaining why direct video playback is not possible
        //% "YTPLayer failed to find usable video streams"
        previewBody: qsTrId("ytplayer-msg-direct-playback-impossible-desc")
    }

    YTRequest {
        id: streamRequest
        method: YTRequest.List
        resource: "video/url"
        params: {
            "video_id" : page.videoId,
        }
        onSuccess: {
            Log.info("Direct video streams found")
            page.streams = response
            bottomMenu.handleNewStreams(response)
        }
        onError: {
            Log.error("No video streams found!")
            if (details && details.hasOwnProperty("message") && details.message !== undefined) {
                noStreamsNotification.previewBody = details.message
            }
            if (page.isAttached) {
                noStreamsNotification.publish()
            }
            page.noStreamsAvailable()
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: page.height + bottomMenu.implicitHeight

        function showControls(show) {
            header.opacity = show
            headerBg.opacity = show / 2
            progressSlider.opacity = show
            progressSliderBg.opacity = show / 2
            bottomMenu.opacity = show
        }

        function showStatusIndicator(show) {
            statusIndicator.opacity = show
            statusIndicatorBg.opacity = show / 2
        }

        onDragStarted: showControls(true)
        onDragEnded: controlsTimer.startIfNeeded()

        Timer {
            id: controlsTimer
            interval: priv.controlsHideDelay
            repeat: false
            onTriggered: flickable.showControls(false)

            function startIfNeeded() {
                if (page.orientation === Orientation.Landscape ||
                    page.orientation === Orientation.LandscapeInverted) {
                    restart()
                } else {
                    stop()
                }
            }
        }

        PageHeader {
            id: header
            z: videoOutput.z + 2
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }
        Rectangle {
            id: headerBg
            x: header.x
            y: header.y
            width: header.width
            height: header.height
            color: "black"
            opacity: 0.5
            z: header.z - 1
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }

        Rectangle {
            color: Qt.application.active ? "black" : "transparent"
            Behavior on color {
                ColorAnimation {
                    duration: Qt.application.active ? 300 : 0
                }
            }
            width: page.width
            height: page.height
            Text {
                z: parent.z + 1
                anchors.top: parent.top
                height: (page.height - videoOutput.contentRect.height) / 2
                anchors.rightMargin: Theme.paddingLarge
                anchors.leftMargin: Theme.paddingLarge
                width: parent.width
                text: page.title
                font.pixelSize: 1.5 * Theme.fontSizeExtraLarge
                color: Theme.highlightColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 3
                wrapMode: Text.WordWrap
                visible: !Qt.application.active && page.isPortrait
                elide: Text.ElideRight
            }
            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                source: mediaPlayer
                fillMode: VideoOutput.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    onPressed: flickable.showControls(true)
                    onReleased: controlsTimer.startIfNeeded()
                    onCanceled: controlsTimer.startIfNeeded()
                    onClicked: {
                        if (!priv.controlsVisible)
                            return

                        if (mediaPlayer.playing) {
                            pauseButton.trigger()
                            mediaPlayer.pause()
                        } else {
                            playButton.trigger()
                            mediaPlayer.play()
                        }
                    }
                }
                YTIconButton {
                    id: playButton
                    anchors.centerIn: parent
                    source: "qrc:///icons/play-64-white.png"
                }
                YTIconButton {
                    id: pauseButton
                    anchors.centerIn: parent
                    source: "qrc:///icons/pause-64-white.png"
                }
            }
        }

        MediaPlayer {
            id: mediaPlayer
            autoLoad: {
                switch (YTPrefs.get("Player/AutoLoad")) {
                case "Always"   : return true
                case "Never"    : return false
                case "WiFi"     : return !YTNetworkManager.cellular
                case "Cellular" : return YTNetworkManager.cellular
                default         : console.assert(false)
                }
            }

            readonly property bool playing: playbackState === MediaPlayer.PlayingState
            property int savedPosition: 0

            function savePosition() {
                if (position > 0) {
                    Log.debug("Saving current playback position: " + H.parseDuration(position))
                    savedPosition = position
                }
            }

            onBufferProgressChanged: {
                var b = Math.round(bufferProgress * 100)
                if (b < 100) {
                    //% "Buffering: %1%"
                    statusIndicator.text = qsTrId('ytplayer-status-buffering').arg(
                        Math.round(bufferProgress * 100))
                }
            }

            onStatusChanged: {
                Log.debug("Media player status changed: " + status)
                switch (status) {
                case MediaPlayer.Loading:
                    //: Media player status indicating content is loading
                    //% "Loading"
                    statusIndicator.text = qsTrId("ytplayer-status-loading")
                    flickable.showStatusIndicator(true)
                    break;
                case MediaPlayer.Buffering:
                    //: Media player status indicating content is buffering
                    //% "Buffering: %1%"
                    statusIndicator.text = qsTrId('ytplayer-status-buffering').arg(
                        Math.round(bufferProgress * 100))
                    flickable.showStatusIndicator(true)
                    break;
                case MediaPlayer.Stalled:
                    //: Media player status indicating content loading has stalled
                    //% "Stalled"
                    statusIndicator.text =  qsTrId('ytplayer-status-stalled')
                    flickable.showStatusIndicator(true)
                    break;
                case MediaPlayer.Buffered:
                    flickable.showStatusIndicator(false)
                    break
                case MediaPlayer.InvalidMedia:
                    Log.error("Invalid media!")
                    //: Media player status indicating invalid content type
                    //% "Invalid media"
                    statusIndicator.text =  qsTrId('ytplayer-status-invalid-media')
                    flickable.showStatusIndicator(true)
                    break;
                case MediaPlayer.EndOfMedia:
                    savedPosition = 0
                    flickable.showStatusIndicator(false)
                    pageStack.navigateBack(PageStackAction.Animated)
                    break
                }
            }

            onPlaybackStateChanged: {
                screenBlanking.prevent(playbackState === MediaPlayer.PlayingState &&
                                       Qt.application.active)
                switch (playbackState) {
                case MediaPlayer.PlayingState:
                    Log.debug("Video is playing")
                    page.playbackStarted()
                    break
                case MediaPlayer.PausedState:
                    Log.debug("Video is paused")
                    break
                case MediaPlayer.StoppedState:
                    Log.debug("Video is stopped")
                    break
                }
            }

            onPositionChanged: {
                if (savedPosition > 0 && position <= savedPosition) {
                    return
                }

                if (!progressSlider.down && status === MediaPlayer.Buffered)
                    progressSlider.value = position
            }

            onDurationChanged: {
                Log.debug("Media player duration changed: " + H.parseDuration(duration))
                if (savedPosition === 0) {
                    progressSlider.value = 0
                }
                progressSlider.maximumValue = duration
            }

            onSeekableChanged: {
                Log.debug("Seekable changed: " + seekable)
                if (seekable && savedPosition) {
                    seek(savedPosition)
                    savedPosition = 0
                    if (page.status === PageStatus.Active)
                        play()
                }
            }

            onError: {
                // TODO: Do something in case of error
                Log.error(errorString)
                flickable.showStatusIndicator(false)
                pageStack.navigateBack(PageStackAction.Animated)
            }
        }

        Row {
            id: statusIndicator
            opacity: 0.0
            z: videoOutput.z + 2
            spacing: Theme.paddingMedium
            anchors.bottom: progressSlider.top
            anchors.bottomMargin: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            property alias text: statusLabel.text
            BusyIndicator {
                id: busyIndicator
                running: true
                size: BusyIndicatorSize.Small
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: statusLabel
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.lightPrimaryColor
            }
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }
        Rectangle {
            id: statusIndicatorBg
            x: statusIndicator.x - Theme.paddingMedium
            y: statusIndicator.y - Theme.paddingSmall
            z: statusIndicator.z - 1
            width: statusIndicator.width + 2 * Theme.paddingMedium
            height: statusIndicator.height + 2 * Theme.paddingSmall
            radius: 4.0
            color: "black"
            opacity: 0.0
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }
        Slider {
            id: progressSlider
            color: Theme.lightPrimaryColor
            backgroundColor: Theme.lightSecondaryColor
            highlightColor: Theme.highlightColor
            anchors.bottom: bottomMenu.top
            width: parent.width
            z: videoOutput.z + 2
            handleVisible: true;
            enabled: true
            minimumValue: 0
            valueText: H.parseDuration(value)
            valueLabelColor: Theme.lightPrimaryColor
            onPressed: controlsTimer.stop()
            onReleased: {
                mediaPlayer.seek(value)
                controlsTimer.startIfNeeded()
            }
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }
        Rectangle {
            id: progressSliderBg
            x: progressSlider.x
            y: progressSlider.y + Theme.paddingMedium
            width: progressSlider.width
            height: progressSlider.height - Theme.paddingMedium
            color: "black"
            opacity: 0.5
            z: progressSlider.z - 1
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }
        Text {
            color: Theme.lightPrimaryColor
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            anchors.rightMargin: Theme.paddingSmall
            font.pixelSize: Theme.fontSizeExtraSmall
            text: H.parseDuration(mediaPlayer.duration)
            opacity: mediaPlayer.duration > 0 ? progressSliderBg.opacity * 2 : 0.0
            z: progressSliderBg.z + 1
            visible: opacity > 0.0
            Behavior on opacity {
                FadeAnimation {}
            }
        }

        PushUpMenu {
            id: bottomMenu
            bottomMargin: Theme.paddingSmall
            visible: opacity > 0.0 && priv.controlsVisible && multipleQualitiesAvailable

            property bool multipleQualitiesAvailable: false
            property Item selectedItem

            onActiveChanged: {
                Log.debug("Bottom menu active: " + active)
                if (active) {
                    controlsTimer.stop()
                } else {
                    controlsTimer.startIfNeeded()
                }
            }

            function selectQuality(item) {
                if (item.font.bold) {
                    bottomMenu.close(false)
                    return;
                }
                if (selectedItem) {
                    selectedItem.font.bold = false
                }
                selectedItem = item
                selectedItem.font.bold = true
                mediaPlayer.savePosition()
                mediaPlayer.source = page.streams[item.text].url
                bottomMenu.close(false)
            }

            function handleNewStreams(streams) {
                var keys = Object.keys(streams)
                Log.debug("Available video stream qualities: " + keys)

                if (keys.length === 1) {
                    Log.debug("Only one video quality available")
                    mediaPlayer.source = streams[keys[0]].url
                    multipleQualitiesAvailable = false
                    return
                }
                multipleQualitiesAvailable = true

                var initialItem = null
                var _h = function (item, makeDefault) {
                    if (streams.hasOwnProperty(item.text)) {
                        item.visible = true
                        if (makeDefault)
                            initialItem = item
                    } else {
                        item.visible = false
                    }
                }

                var defaultQuality
                if (YTNetworkManager.cellular) {
                    defaultQuality = YTPrefs.get("Player/DefaultQualityCellular")
                } else {
                    defaultQuality = YTPrefs.get("Player/DefaultQualityWiFi")
                }
                console.assert(defaultQuality === "360p" ||
                               defaultQuality === "720p")

                _h(q360p, defaultQuality === "360p")
                _h(q720p, defaultQuality === "720p")

                // Don't change quality in case it was already selected
                if (selectedItem)
                    initialItem = selectedItem
                selectQuality(initialItem)
                if (page.status === PageStatus.Active)
                    mediaPlayer.play()
            }

            Behavior on opacity {
                FadeAnimation {}
            }

            MenuLabel {
                //: Label for menu option allowing the user to change video quality
                //% "Video quality"
                text: qsTrId("ytplayer-label-video-quality")
            }
            MenuItem {
                id: q720p
                text: "720p"
                onClicked: bottomMenu.selectQuality(q720p)
            }
            MenuItem {
                id: q360p
                text: "360p"
                onClicked: bottomMenu.selectQuality(q360p)
            }
        }
    } // SilicaFlickable

    CoverActionList {
        enabled: page.status === PageStatus.Active
        CoverAction {
            iconSource: mediaPlayer.playing ?
                "image://theme/icon-cover-pause" :
                "image://theme/icon-cover-play"
            onTriggered: {
                if (mediaPlayer.playing) {
                    mediaPlayer.pause()
                } else {
                    mediaPlayer.play()
                }
            }
        }
    } // CoverActionList

    Timer {
        id: screenBlanking
        interval: 30000
        repeat: true

        onTriggered: YTUtils.preventScreenBlanking(true)

        function prevent(block) {
            if (block) {
                YTUtils.preventScreenBlanking(true)
                start()
            } else {
                YTUtils.preventScreenBlanking(false)
                stop()
            }
        }
    } // Timer
}
