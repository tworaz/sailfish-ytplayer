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
import "../common/Helpers.js" as H
import "../common"

CoverBackground {
    property alias title: _title.text
    property variant thumbnails
    property MediaPlayer mediaPlayer

    Component.onCompleted: {
        title = coverData.title
        thumbnails = coverData.thumbnails
        mediaPlayer = coverData.mediaPlayer
    }

    Column {
        anchors.top: parent.top
        anchors.bottom: actions.top
        width: parent.width
        spacing: Theme.paddingMedium

        AsyncImage {
            width: parent.width
            height: width * thumbnailAspectRatio
            fillMode: Image.PreserveAspectCrop
            source: {
                if (thumbnails.hasOwnProperty("medium"))
                    return thumbnails.medium.url
                return thumbnails.default.url
            }
        }

        Label {
            id: _title
            width: parent.width
            color: Theme.primaryColor
            font.family: Theme.fontFamilyHeading
            font.pixelSize: Theme.fontSizeSmall
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            width: parent.width
            height: wrapper.height

            Rectangle {
                id: wrapper
                anchors.centerIn: parent
                width: progress.width + 2 * Theme.paddingSmall
                height: progress.height + 2 * Theme.paddingSmall
                color: Theme.secondaryHighlightColor
                opacity: 0.5
                radius: 10

                Label {
                    id: progress
                    property int _dur: mediaPlayer ? mediaPlayer.duration : 0
                    property int _pos: mediaPlayer ? mediaPlayer.position : 0

                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamilyHeading
                    color: Theme.primaryColor
                    text: H.parseDuration(_pos) + " / " + H.parseDuration(_dur)
                }
            }
        }
    }

    CoverActionList {
        id: actions
        property bool playing: (mediaPlayer != undefined &&
                                (mediaPlayer.playbackState === MediaPlayer.PlayingState))

        CoverAction {
            iconSource: {
                if (actions.playing)
                    return "image://theme/icon-cover-pause"
                return "image://theme/icon-cover-play"
            }
            onTriggered: {
                if (actions.playing) {
                    mediaPlayer.pause()
                } else {
                    mediaPlayer.play()
                }
            }
        }
    }
}

