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
import harbour.ytplayer 1.0
import "../common/Helpers.js" as H


DockedPanel {
    id: root
    flickableDirection: Flickable.VerticalFlick
    width: parent.width
    height: controls.height + 2 * Theme.paddingLarge
    contentHeight: height

    property alias mediaPlayer: _mediaPlayer
    property alias seeking: progressSlider.down
    property alias playing: _mediaPlayer.playing
    property alias playbackFinished: _mediaPlayer.finished
    property alias keepPlayingAferMinimize: autoPause.checked
    property bool showIndicator: false
    property string videoId
    property variant streams

    QtObject {
        id: priv
        property bool resumeOnActivate: true
        property bool active: false
    }

    function activate() {
        Log.debug("Video controller activated")
        priv.active = true

        if (!root.streams) {
            request.run()
        } else if (priv.resumeOnActivate && Qt.application.active) {
            Log.debug("Video player activated, resuming video playback")
            _mediaPlayer.play()
        }
    }

    function deactivate() {
        Log.debug("Video controller deactivated")
        priv.active = false
        priv.resumeOnActivate = _mediaPlayer.playing
        mediaPlayer.pause()
    }

    function hideBottomMenu() {
        menu.close(true)
    }

    onStreamsChanged: menu.handleNewStreams()

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    YTRequest {
        id: request
        method: YTRequest.List
        resource: "video/url"
        params: {
            "video_id" : videoId,
        }
        onSuccess: {
            root.streams = response
        }
    }

    Connections {
        target: root

        // Make sure video quality menu is closed together with the panel
        onOpenChanged: {
            if (!root.open) {
                Log.debug("Hiding video controls bottom menu")
                menu.close(false)
            }
        }
    }

    PushUpMenu {
        id: menu
        bottomMargin: Theme.paddingLarge
        topMargin: Theme.paddingLarge

        property bool qualitySelectionEnabled: false
        property Item selectedItem
        property int visibleChildren: 3
        property int switchWidth: width / visibleChildren

        MenuLabel {
            //: Label for menu option allowing the user to change video quality
            //% "Video quality"
            text: qsTrId("ytplayer-label-video-quality")
            visible: menu.qualitySelectionEnabled
        }
        Row {
            width: parent.width
            visible: menu.qualitySelectionEnabled
            TextSwitch {
                id: q360p
                text: "360p"
                automaticCheck: false
                width: menu.switchWidth
                onClicked: menu.handleClickOn(q360p)
            }
            TextSwitch {
                id: q720p
                text: "720p"
                automaticCheck: false
                width: menu.switchWidth
                onClicked: menu.handleClickOn(q720p)
            }
            TextSwitch {
                id: q1080p
                text: "1080p"
                automaticCheck: false
                width: menu.switchWidth
                onClicked: menu.handleClickOn(q720p)
            }
        }
        MenuLabel {
            //: Label for extra video player options section
            //% "Player options"
            text: qsTrId("ytplayer-label-extra-options")
        }
        TextSwitch {
            id: autoPause
            //: Menu option label allowing the user to disable video playback pausing on player minimization.
            //% "Keep playing after minimize
            text: qsTrId("ytplayer-label-keep-playing-after-minimize")
        }

        function handleClickOn(item) {
            if (item.checked) {
                menu.close(false)
                return;
            }
            if (selectedItem) {
                selectedItem.checked = false
            }
            selectedItem = item
            selectedItem.checked = true
            _mediaPlayer.savePosition()
            _mediaPlayer.source = root.streams[item.text].url
            menu.close(false)
        }

        function handleNewStreams() {
            var keys = Object.keys(root.streams)
            Log.debug("Available video stream qualities: " + keys)

            if (keys.length === 1) {
                Log.debug("Only one video quality available")
                _mediaPlayer.source = root.streams[keys[0]].url
                q1080p.visible = false
                q720p.visible = false
                q360p.visible = false
                return
            }
            menu.qualitySelectionEnabled = true

            var initialItem, visibleItems = 0
            var _h = function (item, makeDefault) {
                if (root.streams.hasOwnProperty(item.text)) {
                    item.visible = true
                    visibleItems++
                    if (makeDefault)
                        initialItem = item
                } else {
                    item.visible = false
                }
            }
            _h(q360p, true)
            _h(q720p, !networkManager.cellular)
            _h(q1080p)

            // Don't change quality in case it was already selected
            if (selectedItem)
                initialItem = selectedItem
            visibleChildren = visibleItems
            handleClickOn(initialItem)
        }
    }

    MediaPlayer {
        id: _mediaPlayer

        property int savedPosition: 0
        readonly property bool playing: playbackState === MediaPlayer.PlayingState
        readonly property bool finished: status === MediaPlayer.EndOfMedia

        function savePosition() {
            if (position > 0) {
                Log.debug("Saving current playback position: " + H.parseDuration(position))
                savedPosition = position
            }
        }

        onStatusChanged: {
            Log.debug("Media Player status changed to: " +
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
            case MediaPlayer.EndOfMedia:
                if (Math.round(position / 1000) < Math.round(duration / 1000)) {
                    Log.debug("End of media received, but positon < duration")
                    savePosition()
                    request.run()
                } else {
                    Log.debug("End of media")
                    savedPosition = 0
                }
                break
            }

            playbackStatus.text = mediaPlayerStatusToString(status)
        }

        onPlaybackStateChanged: {
            switch(playbackState) {
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
            if (savedPosition > 0 && position <= savedPosition) {
                return
            }

            if (!progressSlider.down && status === MediaPlayer.Buffered) {
                progressSlider.value = position
            }
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
                if (priv.active)
                    play()
            }
        }

        onError: {
            // TODO: Do something in case of error
            Log.error(errorString)
            showIndicator = false
        }

        onBufferProgressChanged: {
            //Log.debug("Buffering progress: " + Math.round(bufferProgress * 100))
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
            case MediaPlayer.Buffered:
                if (duration > 0) {
                    //: Video duration label with value
                    //% "Duration: %1"
                    return qsTrId("ytplayer-label-duration-with-value").arg(
                                H.parseDuration(duration))
                } else {
                    //: Media player status indicating content has been buffered
                    //% "Buffered"
                    return qsTrId('ytplayer-status-buffered')
                }
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
        id: controls
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
                Log.debug("Play/Pause button clicked")
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
