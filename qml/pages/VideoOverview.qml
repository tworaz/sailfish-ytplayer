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
import "YoutubeClientV3.js" as Yt
import "duration.js" as DUtil


Page {
    id: page
    property string videoId
    readonly property string coverFile: "VideoOverview.qml"
    readonly property alias title: header.title
    readonly property alias thumbnailUrl: poster.source

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: wrapper.height

        PullDownMenu {
            MenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                //: Label of menu action starting video playback
                //% "Play"
                text: qsTrId("ytplayer-action-play")
                onClicked: pageStack.push(Qt.resolvedUrl("VideoPlayer.qml"),
                                          {"videoId" : videoId, "title": header.title})
            }
        }

        Column {
            id: wrapper
            width: parent.width - 2 * Theme.paddingMedium
            x: Theme.paddingMedium
            spacing: Theme.paddingLarge

            PageHeader {
                id: header
            }

            Image {
                id: poster
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: width * 9 / 16
                fillMode: Image.PreserveAspectCrop
            }

            Row {
                width: parent.width

                KeyValueLabel {
                    id: publishDate
                    width: parent.width * 2 / 3
                    pixelSize: Theme.fontSizeExtraSmall
                    //: Label for video upload date field
                    //% "Published on"
                    key: qsTrId("ytplayer-label-publish-date")
                }

                KeyValueLabel {
                    id: duration
                    width: parent.width / 3
                    pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignRight
                    //: Label for video duration field
                    //% "Duration"
                    key: qsTrId("ytplayer-label-duration")
                }
            }

            Row {
                width: parent.width
                spacing: Theme.paddingLarge

                StatItem {
                    id: viewCount
                    image: "image://theme/icon-s-cloud-download?" + Theme.highlightColor
                }

                StatItem {
                    id: likeCount
                    image: "image://theme/icon-s-like?" + Theme.highlightColor
                }

                StatItem {
                    id: dislikeCount
                    image: "image://theme/icon-s-like?" + Theme.highlightColor
                    imageRotation: 180.0
                }
            }

            Separator {
                color: Theme.highlightColor
                width: parent.width;
            }

            KeyValueLabel {
                id: description
                width: parent.width
                //: Label for the description field
                //% "Description"
                key: qsTrId("ytplayer-label-description")
            }
        }

        function onVideoDetailsLoaded(details) {
            //console.debug("Have video details: " + JSON.stringify(details, undefined, 2))
            var thumbnails = details.snippet.thumbnails;
            if (thumbnails.standard) {
                poster.source = thumbnails.standard.url
            } else if (thumbnails.high) {
                poster.source = thumbnails.high.url;
            } else {
                poster.source = thumbnails.default.url
            }

            if (details.snippet.description) {
                description.value = details.snippet.description
            } else {
                description.visible = false
            }

            viewCount.text = details.statistics.viewCount
            likeCount.text = details.statistics.likeCount
            dislikeCount.text = details.statistics.dislikeCount

            var pd = new Date(details.snippet.publishedAt)
            publishDate.value = Qt.formatDateTime(pd, "d MMMM yyyy")

            var dur = new DUtil.Duration(details.contentDetails.duration)
            duration.value = dur.asClock();

            header.title = details.snippet.title
            indicator.running = false
        }

        function onFailure(error) {
            errorNotification.show(error);
            indicator.running = false
        }

        Component.onCompleted: {
            console.debug("Video overview page created, video ID:" + videoId)
            Yt.getVideoDetails(videoId, onVideoDetailsLoaded, onFailure)
        }

        VerticalScrollDecorator {}
    }
}
