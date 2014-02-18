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

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import Sailfish.Media 1.0
import "YoutubeClientV3.js" as Yt

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: page.isPortrait || (page.isLandscape && controls.visible())

    property bool applicationActive: Qt.application.active
    property string videoId
    property string title

    Rectangle {
        id: background;
        anchors.fill: parent
        color: "black"
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent

        PageHeader {
            id: header
            title: page.title
            visible: page.isPortrait || (page.isLandscape && controls.visible())
            z: video.z + 2
        }

        // Simple background for PageHeader visible only when player is in landscape mode.
        // It's supposed to ensure header contents are always readeble, no matter what
        // video content is visible in the background.
        Rectangle {
            anchors {
                right: header.right
                left: header.left
                top: header.top
                bottom: header.bottom
            }

            visible: header.visible
            color: "black"
            opacity: 0.5
            z: header.z - 1
        }

        MediaPlayer {
            id: mediaPlayer
            autoPlay: true

            onStatusChanged: {
                console.debug("Media Player status changed to: " +
                              mediaPlayerStatusToString(status))
                switch (status) {
                case MediaPlayer.Loading:
                case MediaPlayer.Buffering:
                case MediaPlayer.Stalled:
                    indicator.running = true
                    break;
                case MediaPlayer.Buffered:
                    indicator.running = false
                    break;
                }
            }

            onPlaybackStateChanged: {
                switch(playbackState) {
                case MediaPlayer.PlayingState: return "Playing"
                case MediaPlayer.PausedState: return "Paused"
                case MediaPlayer.StoppedState: return "Stopped"
                }
            }

            onPositionChanged: {
                progressBar.setPosition(position)
            }

            onError: {
                console.error(errorString)
                indicator.running = false
            }

            function mediaPlayerStatusToString(status) {
                switch(status) {
                case MediaPlayer.NoMedia: return "NoMedia"
                case MediaPlayer.Loading: return "Loading"
                case MediaPlayer.Loaded: return "Loaded"
                case MediaPlayer.Buffering: return "Buffering"
                case MediaPlayer.Stalled: return "Stalled"
                case MediaPlayer.Buffered: return "Buffered"
                case MediaPlayer.EndOfMedia: return "EndOfMedia"
                case MediaPlayer.InvalidMedia: return "InvalidMedia"
                default: return "UnknownStatus"
                }
            }
        }

        GStreamerVideoOutput {
            id: video
            source: mediaPlayer
            anchors.fill: parent

            BusyIndicator {
                id: indicator
                anchors.centerIn: parent
                running: true
                size: BusyIndicatorSize.Large
            }
        }

        MouseArea {
            id: controls
            anchors.fill: parent;

            onClicked: {
                console.debug("Screen tapped, showing video controls")
                show()
            }

            function show() {
                playPauseButton.opacity = 1.0
                progressBar.opacity = 1.0
                controlsTimer.restart()
            }

            function visible() {
                return (playPauseButton.opacity == 1.0);
            }

            Timer {
                id: controlsTimer
                interval: 2500
                repeat: false
                onTriggered: {
                    console.debug("Video controls timeout, hiding")
                    playPauseButtonHide.start()
                    progressBarHide.start()
                }
            }

            Image {
                id: playPauseButton
                anchors.centerIn: parent
                opacity: 0.0
                visible: !indicator.running
                source: mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                            "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"

                NumberAnimation {
                    id: playPauseButtonHide
                    target: playPauseButton
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 500
                    easing.type: Easing.InOutQuad
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.debug("Play/Pause button clicked")
                        controls.show()
                        if (mediaPlayer.playbackState == MediaPlayer.PlayingState) {
                            mediaPlayer.pause()
                        } else {
                            mediaPlayer.play()
                        }
                    }
                }
            }

            Rectangle {
                id: progressBar
                anchors.bottom: parent.bottom
                width: parent.width
                color: Theme.secondaryHighlightColor
                opacity: 0.0
                height: 60

                Rectangle {
                    id: progressContent
                    height: parent.height
                    color: Theme.highlightColor
                    opacity: 0.95
                }

                NumberAnimation {
                    id: progressBarHide
                    target: progressBar
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 500
                    easing.type: Easing.InOutQuad
                }

                function setPosition(position) {
                    var p = position / mediaPlayer.duration;
                    progressContent.width = progressBar.width * p;
                }

                MouseArea {
                    anchors.fill: parent
                    drag {
                        target: controls
                        axis: Drag.XAxis
                        minimumX: 0
                        maximumX: controls.width
                    }

                    onPressed: {
                        console.debug("Progress pressed")
                        controls.show()
                    }

                    onReleased: {
                        var pos = (mouse.x / progressBar.width) * mediaPlayer.duration
                        console.debug("Seeking to: " + pos)
                        mediaPlayer.seek(pos);
                    }

                    onClicked: {
                        console.debug("Progress bar clicked");
                        controls.show()
                    }
                }
            }
        }
    }

    function onFailure(error) {
        networkErrorNotification.show(error);
        indicator.running = false;
    }

    function onVideoUrlObtained(url) {
        console.debug("Selected URL: " + url)
        mediaPlayer.source = url
    }

    onApplicationActiveChanged:  {
        if (!applicationActive) {
            mediaPlayer.pause()
        }
    }

    Component.onCompleted: {
        console.debug("Video player page created, video ID: " + videoId)
        Yt.getVideoUrl(videoId, onVideoUrlObtained, onFailure)
    }
}
