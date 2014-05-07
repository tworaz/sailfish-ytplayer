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
import harbour.ytplayer 1.0
import "../common/Helpers.js" as H

Page {
    id: page
    allowedOrientations: Orientation.All
    showNavigationIndicator: topDockPanel.open

    property alias mediaPlayer: videoController.mediaPlayer
    property alias title: header.title
    property variant thumbnails
    property bool applicationActive: Qt.application.active
    property string videoId
    property variant _streams

    Component.onCompleted: {
        Log.debug("Video player page created, video ID: " + videoId)
        showVideoControls(true)
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("VideoPlayer.qml", {
                "title"       : page.title,
                "thumbnails"  : thumbnails,
                "mediaPlayer" : mediaPlayer
            })
            request.run()
        } else if (status == PageStatus.Deactivating) {
            Log.debug("VidePlayer page deactivating");
            mediaPlayer.stop()
            videoOutput.source = null
        }
    }

    YTRequest {
        id: request
        method: YTClient.List
        resource: "video/url"
        params: {
            "video_id" : videoId,
        }

        onSuccess: {
            utilityWorkerScript.parseStreamsInfo(response, function(map) {
                Log.debug("Streams map: " + JSON.stringify(map, undefined, 2))
                if (H.isEmptyObject(map)) {
                    _streams = getFallbackUrls()
                } else {
                    _streams = map
                }
                selectStream()
            })
        }
    }

    function getFallbackUrls() {
        var base = "http://ytapi.com/?vid=" + videoId + "&format=direct&itag="
        return {
            "small"  : base + 36,
            "medium" : base + 18,
            "high"   : base + 22,
        }
    }

    function selectStream() {
        if (_streams.high) {
            mediaPlayer.source = _streams.high
        } else if (_streams.medium) {
            mediaPlayer.source = _streams.medium
        } else {
            mediaPlayer.source = _streams.small
        }
        Log.debug("Selected URL: " + mediaPlayer.source)
    }

    onApplicationActiveChanged:  {
        if (!applicationActive) {
            mediaPlayer.pause()
            screenBlanking.prevent(false)
        } else {
            screenBlanking.prevent(videoController.playing)
        }
    }

    onOrientationChanged: {
        if (page.orientation & (Orientation.Landscape | Orientation.LandscapeInverted)) {
            Log.debug("Video player orientation changed to landscape")
            showVideoControls(!videoController.playing)
            if (videoController.playing) {
                controlsTimer.restart()
            }
        } else {
            Log.debug("Video player orientation changed to portrait")
            showVideoControls(true)
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
        z: videoOutput.z + 1

        Rectangle {
            anchors.fill: parent
            opacity: 0.5
            color: "black"
        }

        PageHeader {
            id: header
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: topDockPanel.margin
        anchors.bottomMargin: videoController.margin

        // TODO: Use VideoOutput once it's working
        GStreamerVideoOutput {
            id: videoOutput
            source: mediaPlayer
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
                Log.debug("Video player screen clicked, showing controls")
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
                        Log.debug("Video controls timeout, hiding")
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

        onOpenChanged: {
            // Prevent the user from closing the panel in portrait mode
            if (!open && page.isPortrait) {
                open = true
                return
            }
            topDockPanel.open = open
        }

        onPlayingChanged: {
            if (Qt.application.active) {
                screenBlanking.prevent(playing)
            }
            if (playing && page.isLandscape) {
                controlsTimer.restart()
            }
        }
    }

    Timer {
        id: screenBlanking
        interval: 30000
        repeat: true

        onTriggered: {
            NativeUtil.preventScreenBlanking(true)
        }

        function prevent(block) {
            if (block) {
                NativeUtil.preventScreenBlanking(true)
                start()
            } else {
                NativeUtil.preventScreenBlanking(false)
                stop()
            }
        }
    }
}
