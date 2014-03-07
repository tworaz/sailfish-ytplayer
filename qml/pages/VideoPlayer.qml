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
//import Sailfish.Media 1.0
import harbour.ytplayer.Media 1.0
import "YoutubeClientV3.js" as Yt

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: topDockPanel.open

    property string videoId
    property string title

    onOrientationChanged: {
        if (page.isLandscape) {
            showVideoControls(true)
        } else {
            showVideoControls(!videoController.playing)
        }
    }

    function showVideoControls(show) {
        if (show) {
            topDockPanel.show()
            videoController.show()
        } else {
            topDockPanel.hide()
            videoController.hide()
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
    }

    DockedPanel {
        id: topDockPanel
        dock: Dock.Top
        width: parent.width
        height: Theme.itemSizeMedium + Theme.paddingMedium
        z: video.z + 1

        Rectangle {
            anchors.fill: parent
            opacity: 0.5
            color: "black"
        }

        PageHeader {
            id: header
            title: page.title
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: topDockPanel.margin
        anchors.bottomMargin: videoController.margin

        // TODO: Use VideoOutput once it's working
        GStreamerVideoOutput {
            id: video
            source: videoController.mediaPlayer
            anchors.fill: parent

            BusyIndicator {
                id: indicator
                anchors.centerIn: parent
                running: videoController.showIndicator
                size: BusyIndicatorSize.Large
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: page.isLandscape

            onClicked: {
                console.debug("Video player screen clicked")
                showVideoControls(true)
                controlsTimer.restart()
            }

            Timer {
                id: controlsTimer
                interval: 4000
                repeat: false
                onTriggered: {
                    if (!videoController.playbackFinished &&
                        videoController.playing && page.isLandscape) {
                        console.debug("Video controls timeout, hiding")
                        showVideoControls(false)
                    }
                }
            }
        }
    }

    VideoController {
        id: videoController
        width: parent.width
        height: Theme.itemSizeLarge + Theme.paddingLarge
        dock: Dock.Bottom

        onSeekingChanged: {
            if (page.isLandscape) {
                seeking ? controlsTimer.stop() : controlsTimer.start()
            }
        }

        onPlaybackFinishedChanged: {
            if (playbackFinished && page.isLandscape){
                showVideoControls(true)
            }
        }

        onPlayingChanged: {
            NativeUtil.preventScreenBlanking = playing
            if (playing && page.isLandscape) {
                controlsTimer.restart()
            }
        }
    }

    function onFailure(error) {
        errorNotification.show(error)
        videoController.showIndicator = false
    }

    function onVideoUrlObtained(url) {
        console.debug("Selected URL: " + url)
        videoController.mediaPlayer.source = url

    }

    Component.onCompleted: {
        console.debug("Video player page created, video ID: " + videoId)
        Yt.getVideoUrl(videoId, onVideoUrlObtained, onFailure)
        showVideoControls(true)
    }
}
