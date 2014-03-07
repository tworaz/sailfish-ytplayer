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
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import "Helpers.js" as H


DockedPanel {
    property alias mediaPlayer: _mediaPlayer
    property alias seeking: progressSlider.down
    property bool playing: _mediaPlayer.playbackState === MediaPlayer.PlayingState
    property bool playbackFinished: _mediaPlayer.Status === MediaPlayer.EndOfMedia
    property bool applicationActive: Qt.application.active
    property bool showIndicator: false

    flickableDirection: Flickable.VerticalFlick

    onApplicationActiveChanged:  {
        if (!applicationActive) {
            _mediaPlayer.pause()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    MediaPlayer {
        id: _mediaPlayer
        autoPlay: true

        onStatusChanged: {
            console.debug("Media Player status changed to: " +
                          mediaPlayerStatusToString(status))
            switch (status) {
            case MediaPlayer.Loading:
            case MediaPlayer.Buffering:
            case MediaPlayer.Stalled:
                showIndicator = true
                break
            case MediaPlayer.Buffered:
                showIndicator = false
                break
            }

            playbackStatus.text = mediaPlayerStatusToString(status)
        }

        onPlaybackStateChanged: {
            switch(playbackState) {
            case MediaPlayer.PlayingState: return "Playing"
            case MediaPlayer.PausedState: return "Paused"
            case MediaPlayer.StoppedState: return "Stopped"
            }
        }

        onPositionChanged: {
            if (!progressSlider.down && status === MediaPlayer.Buffered) {
                progressSlider.value = position
            }
        }

        onDurationChanged: {
            console.debug("Media player duration changed: " + H.parseDuration(duration))
            progressSlider.value = 0
            progressSlider.maximumValue = duration
        }

        onError: {
            console.error(errorString)
            showIndicator = false
        }

        onBufferProgressChanged: {
            //console.debug("Buffering progress: " + Math.round(bufferProgress * 100))
            var b = Math.round(bufferProgress * 100)
            if (b < 100) {
                //% "Buffering: %1%"
                playbackStatus.text = qsTrId('ytplayer-status-buffering').arg(
                            Math.round(bufferProgress * 100))
            } else {
                playbackStatus.text = mediaPlayerStatusToString(MediaPlayer.Buffered)
            }
        }

        function mediaPlayerStatusToString(status) {
            // TODO: Translate status strings
            switch(status) {
            //: Media player status indicating there is no content to play
            //% "No media"
            case MediaPlayer.NoMedia: return qsTrId('ytplayer-status-no-media')
            //: Media player status indicating content is loading
            //% "Loading"
            case MediaPlayer.Loading: return qsTrId('ytplayer-status-loading')
            //: Media player status indicating content was loaded
            //% "Loaded"
            case MediaPlayer.Loaded: return qsTrId('ytplayer-status-loaded')
            case MediaPlayer.Buffering:
                //: Media player status indicating content is buffering
                //% "Buffering: %1%"
                return qsTrId('ytplayer-status-buffering').arg(
                            Math.round(bufferProgress * 100))
            //: Media player status indicating content loading has stalled
            //% "Stalled"
            case MediaPlayer.Stalled: return qsTrId('ytplayer-status-stalled')
            //: Media player status indicating content has been buffered
            //% "Buffered"
            case MediaPlayer.Buffered: return qsTrId('ytplayer-status-buffered')
            //: Media player status indicating end of content has been reached
            //% "End of media"
            case MediaPlayer.EndOfMedia: return qsTrId('ytplayer-status-end-of-media')
            //: Media player status indicating invalid content type
            //% "Invalid media"
            case MediaPlayer.InvalidMedia: return qsTrId('ytplayer-status-invalid-media')
            default: return "UnknownStatus"
            }
        }
    }

    Row {
        x: Theme.paddingLarge
        width: parent.width - Theme.paddingLarge
        height: parent.height

        IconButton {
            id: playPauseButton
            anchors.verticalCenter: parent.verticalCenter
            icon.source: {
                if (_mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    return "image://theme/icon-l-pause"
                } else {
                    return "image://theme/icon-l-play"
                }
            }
            onClicked: {
                console.debug("Play/Pause button clicked")
                if (_mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    _mediaPlayer.pause()
                } else {
                    _mediaPlayer.play()
                }
            }
        }

        Item {
            width: parent.width - playPauseButton.width
            height: parent.height

            Slider {
                id: progressSlider
                anchors.top: parent.top
                anchors.topMargin: -Theme.paddingMedium
                width: parent.width
                enabled: _mediaPlayer.seekable
                handleVisible: true
                minimumValue: 0
                maximumValue: 100
                valueText: H.parseDuration(value)

                onReleased: _mediaPlayer.seek(value)
            }
        }
    } // Row

    Label {
        id: playbackStatus
        width: parent.width
        height: Theme.paddingLarge
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: Theme.paddingMedium
        anchors.rightMargin: Theme.paddingMedium
        horizontalAlignment: Text.AlignRight
        font.pixelSize: Theme.fontSizeExtraSmall
    }

}
