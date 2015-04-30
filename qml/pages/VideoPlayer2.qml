// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import harbour.ytplayer 1.0
import "../common/Helpers.js" as H
import "../common"

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: header.opacity > 0

    // Set by parent page
    property string videoId
    property alias title: header.title
    //property variant thumbnails
    //property string iso_duration: ""
    property YTLocalVideo localVideo

    // Set by this page, but used outside
    property variant streams

    Component.onCompleted: {
        Log.debug("Video player page created")
        streamRequest.run()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // Transparent cover
            requestCoverPage()
            controlsTimer.restart()
            if (mediaPlayer.source)
                mediaPlayer.play()
        } else if (status === PageStatus.Deactivating) {
            if (mediaPlayer.playing)
                mediaPlayer.pause()
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (!Qt.application.active) {
                if (priv.pausePlayackOnDectivate && mediaPlayer.playing)
                    mediaPlayer.pause()
            }
        }
    }

    QtObject {
        id: priv
        readonly property bool controlsVisible: bottomControls.opacity === 1.0
        readonly property bool pausePlayackOnDectivate: true // TODO: Make this customizable via settings
        readonly property bool hideControlsWhenPaused: false // TODO: ditto
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
            mediaPlayer.source = response["360p"].url
            //handleStreamChange(response)
        }
        onError: {
            Log.error("No video streams found!")
            //noStreamsNotification.publish()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: childrenRect.height

        function showControls(show) {
            headerWrapper.opacity = show
            bottomControls.opacity = show
            bottomMenu.opacity = show
        }

        Timer {
            id: controlsTimer
            interval: 3000 // TODO: Make this customizable via settings
            repeat: false
            onTriggered: flickable.showControls(false)
        }

        Rectangle {
            id: headerWrapper
            z: videoOutput.z + 1
            color: "black"
            width: header.width
            height: header.height
            PageHeader {
                id: header
            }
            Behavior on opacity {
                FadeAnimation {}
            }
        }

        VideoOutput {
            id: videoOutput
            width: page.width
            height: page.height
            source: mediaPlayer

            MouseArea {
                anchors.fill: parent
                onPressed: flickable.showControls(true)
                onReleased: controlsTimer.restart()
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
                source: "qrc:///icons/play-64.png"
            }
            YTIconButton {
                id: pauseButton
                anchors.centerIn: parent
                source: "qrc:///icons/pause-64.png"
            }
        }

        MediaPlayer {
            id: mediaPlayer
            readonly property bool playing: playbackState === MediaPlayer.PlayingState

            onStatusChanged: {
                Log.debug("Media player status changed: " + status)
                //Log.debug("Media Player status changed to: " +
                //          mediaPlayerStatusToString(status))
                //switch (status) {
                //case MediaPlayer.Loading:
                //case MediaPlayer.Buffering:
                //case MediaPlayer.Stalled:
                //    showIndicator = true
                //    break
                //case MediaPlayer.Buffered:
                //    showIndicator = false
                //    break
                //case MediaPlayer.EndOfMedia:
                //    savedPosition = 0
                //    break
                //}

                //playbackStatus.text = mediaPlayerStatusToString(status)
            }

            onPlaybackStateChanged: {
                switch (playbackState) {
                case MediaPlayer.PlayingState:
                    Log.debug("Video is playing")
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
                //if (savedPosition > 0 && position <= savedPosition) {
                //    return
                //}

                if (!progressSlider.down && status === MediaPlayer.Buffered)
                    progressSlider.value = position
            }

            onDurationChanged: {
                Log.debug("Media player duration changed: " + H.parseDuration(duration))
                //if (savedPosition === 0) {
                //    progressSlider.value = 0
                //}
                progressSlider.maximumValue = duration
            }

            onSeekableChanged: {
                Log.debug("Seekable changed: " + seekable)
                if (seekable && page.status === PageStatus.Active)
                    play()

                //if (seekable && savedPosition) {
                //    seek(savedPosition)
                //    savedPosition = 0
                //    if (priv.active)
                //        play()
                //}
            }

            onError: {
                // TODO: Do something in case of error
                Log.error(errorString)
                //showIndicator = false
            }
        }

        Row {
            id: bottomControls
            anchors.bottom: bottomMenu.top
            width: parent.width
            height: 120
            Behavior on opacity {
                FadeAnimation {}
            }
            Slider {
                id: progressSlider
                handleVisible: true;
                enabled: true
                width: parent.width
                minimumValue: 0
                maximumValue: 10000
                valueText: H.parseDuration(value)
                onPressed: controlsTimer.stop()
                onReleased: {
                    mediaPlayer.seek(value)
                    controlsTimer.restart()
                }
            }
        }

        PushUpMenu {
            id: bottomMenu

            onActiveChanged: {
                Log.debug("Bottom menu active: " + active)
                if (active) {
                    controlsTimer.stop()
                } else {
                    controlsTimer.restart()
                }
            }

            Behavior on opacity {
                FadeAnimation {}
            }

            MenuLabel {
                //: Label for menu option allowing the user to change video quality
                //% "Video quality"
                text: qsTrId("ytplayer-label-video-quality")
            }
            Row {
                width: parent.width
                TextSwitch {
                    text: "360p"
                    width: parent.width / 2
                }
                TextSwitch {
                    text: "720p"
                    width: parent.width / 2
                }
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
