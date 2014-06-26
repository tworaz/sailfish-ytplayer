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
import harbour.ytplayer 1.0
import "duration.js" as DJS
import "../common"

Dialog {
    id: page
    property string videoId
    property variant thumbnails
    property alias title: header.title

    acceptDestination: Qt.resolvedUrl("VideoPlayer.qml")
    acceptDestinationAction: PageStackAction.Push
    acceptDestinationProperties: {
        "thumbnails" : thumbnails,
        "videoId"    : videoId,
        "title"      : title,
    }

    Component.onCompleted: {
        Log.debug("Video overview page for video ID: " + videoId + " created")
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!request.loaded) {
                request.run()
            }

            rating.enabled = Prefs.isAuthEnabled()
            requestCoverPage("VideoOverview.qml", {
                "thumbnails" : thumbnails,
                "videoId"    : videoId,
                "title"      : title
            })
        }
    }

    YTRequest {
        id: request
        method: YTRequest.List
        resource: "videos"
        params: {
            "part" : "snippet,contentDetails,statistics",
            "id"   : videoId
        }

        onSuccess: {
            console.assert(response.kind === "youtube#videoListResponse")
            console.assert(response.items.length === 1)
            console.assert(response.items[0].kind === "youtube#video")
            var details = response.items[0]
            //Log.debug("Have video details: " + JSON.stringify(details, undefined, 2))
            if (details.snippet.description) {
                description.text = details.snippet.description
            } else {
                description.visible = false
            }

            rating.likes = details.statistics.likeCount
            rating.dislikes = details.statistics.dislikeCount
            rating.dataValid = true

            var pd = new Date(details.snippet.publishedAt)
            publishDate.value = Qt.formatDateTime(pd, "d MMMM yyyy")
            duration.value = (new DJS.Duration(details.contentDetails.duration)).asClock()

            header.title = details.snippet.title
            indicator.running = false
        }
    }

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

        Column {
            id: wrapper
            width: parent.width - 2 * Theme.paddingMedium
            x: Theme.paddingMedium
            spacing: Theme.paddingMedium

            DialogHeader {
                id: header
                //: Label for video play button
                //% "Play Video"
                acceptText: qsTrId('ytplayer-action-play')
                //: Label for back button in dialog
                //% "Back"
                cancelText: qsTrId('ytplayer-action-back')
            }

            AsyncImage {
                id: poster
                visible: !indicator.running
                width: parent.width
                height: width * thumbnailAspectRatio
                indicatorSize: BusyIndicatorSize.Medium
                source: {
                    if (thumbnails.high) {
                        return thumbnails.high.url
                    } else if (thumbnails.medium) {
                        return thumbnails.medium.url
                    } else {
                        return thymbnails.default.url
                    }
                }
            }

            Row {
                width: parent.width
                visible: !indicator.running

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

            YTLikeButtons {
                id: rating
                width: parent.width
                visible: !indicator.running
                videoId: page.videoId
            }

            Separator {
                color: Theme.highlightColor
                width: parent.width
                visible: !indicator.running
            }

            Label {
                id: description
                visible: !indicator.running
                width: parent.width
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
            }
        }
        VerticalScrollDecorator {}
    }
}
