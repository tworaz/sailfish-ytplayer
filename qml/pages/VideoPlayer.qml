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
            visible: page.orientation === Orientation.Portrait ? true : false
        }

        Rectangle {
            id: controls
            anchors.fill: parent
            visible: false

            Rectangle {
                id: progress
                anchors {
                    right: parent.right
                    left: parent.left
                    bottom: parent.bottom
                }
                height: 400

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.debug("Progress bar clicked");
                    }
                }
            }
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
                console.debug("Media Player state changed to: " +
                              mediaPlayerStateToString(playbackState))
                switch (playbackState) {
                case MediaPlayer.PlayingState:
                    indicator.running = false
                    break;
                }
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

            function mediaPlayerStateToString(state) {
                switch(state) {
                case MediaPlayer.PlayingState: return "Playing"
                case MediaPlayer.PausedState: return "Paused"
                case MediaPlayer.StoppedState: return "Stopped"
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
    }

    function onFailure(msg) {
        console.error(msg);
    }

    function onVideoUrlObtained(url) {
        console.debug("Selected URL: " + url)
        mediaPlayer.source = url
    }

    Component.onCompleted: {
        console.debug("Video player page created")
        console.debug("Video ID: " + videoId)
        Yt.getVideoUrl(videoId, onVideoUrlObtained, onFailure)
    }
}
