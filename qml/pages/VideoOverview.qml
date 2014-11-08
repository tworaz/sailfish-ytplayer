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

Page {
    id: page
    allowedOrientations: Orientation.All
    state: page.isPortrait ? "PORTRAIT" : "LANDSCAPE"

    property string videoId
    property variant thumbnails
    property alias title: titleLabel.text

    states: [
        State {
            name: "PORTRAIT"
            PropertyChanges { target: content; columns: 1; spacing: 0}
            PropertyChanges { target: videoDetails; columns: 2}
        },
        State {
            name: "LANDSCAPE"
            PropertyChanges { target: content; columns: 2; spacing: Theme.paddingMedium }
            PropertyChanges { target: videoDetails; columns: 1}
        }
    ]

    QtObject {
        id: priv
        property bool playerPushed: false
        property variant channelBrowserData: ({})
        readonly property real sideMargin: Theme.paddingMedium
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
            if (!priv.playerPushed) {
                pageStack.pushAttached(Qt.resolvedUrl("VideoPlayer.qml"), {
                    "thumbnails" : thumbnails,
                    "videoId"    : videoId,
                    "title"      : title,
                })
                priv.playerPushed = true
            }
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

            titleLabel.text = details.snippet.title
            indicator.running = false

            channelName.value = details.snippet.channelTitle
            priv.channelBrowserData = {
                "channelId" : details.snippet.channelId,
                "title"     : details.snippet.channelTitle,
            }

            var browserPage = pageStack.find(function(page) {
                if (page.objectName === "ChannelBrowser")
                    return true
                return false
            })
            if (!browserPage)
                channelBrowserMenu.visible = true
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
        contentHeight: header.height + wrapper.height

        PullDownMenu {
            MenuItem {
                //: Label for menu option opening YouTube web page for a video
                //% "Open in browser"
                text: qsTrId("ytplayer-label-open-in-browser")
                onClicked: Qt.openUrlExternally("https://youtube.com/watch?v=" + videoId)
            }
            MenuItem {
                id: channelBrowserMenu
                visible: false
                //: Label for menu option allwoing the user to browser YouTube ChannelBrowser
                //% "Browser channel"
                text: qsTrId("ytplayer-label-browse-channel")
                onClicked: {
                    pageStack.replaceAbove(pageStack.previousPage(),
                        Qt.resolvedUrl("ChannelBrowser.qml"),
                        priv.channelBrowserData)
                }
            }
        }

        HeaderButton {
            id: header
            anchors.top: parent.top
            anchors.right: parent.right
            //: Label for video play button
            //% "Play"
            text: qsTrId("ytplayer-label-play")
            icon: "qrc:///icons/play-48.png"
            onClicked: {
                pageStack.navigateForward(PageStackAction.Animated)
            }
        }

        Column {
            id: wrapper
            visible: !indicator.running
            anchors.top: header.bottom
            width: parent.width - 2 * priv.sideMargin
            x: priv.sideMargin
            spacing: Theme.paddingMedium

            Grid {
                id: content
                width: parent.width
                columns: 1

                property int childWidth: (width - spacing) / columns

                AsyncImage {
                    id: poster
                    width: parent.childWidth
                    height: width * thumbnailAspectRatio
                    indicatorSize: BusyIndicatorSize.Medium
                    source: {
                        if (thumbnails.high) {
                            return thumbnails.high.url
                        } else if (thumbnails.medium) {
                            return thumbnails.medium.url
                        } else {
                            return thumbnails.default.url
                        }
                    }
                }

                Column {
                    spacing: Theme.paddingMedium
                    width: parent.childWidth

                    Label {
                        id: titleLabel
                        width: parent.width
                        font.family: Theme.fontFamilyHeading
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }

                    Separator {
                        color: Theme.highlightColor
                        width: parent.width
                    }

                    Flow {
                        id: videoDetails
                        width: parent.width
                        property int columns: 2

                        KeyValueLabel {
                            id: publishDate
                            width: parent.columns === 2 ? parent.width * 2 / 3 : parent.width
                            pixelSize: Theme.fontSizeExtraSmall
                            //: Label for video upload date field
                            //% "Published on"
                            key: qsTrId("ytplayer-label-publish-date")
                        }
                        KeyValueLabel {
                            id: duration
                            width: parent.columns === 2 ? parent.width * 1 / 3 : parent.width
                            pixelSize: Theme.fontSizeExtraSmall
                            horizontalAlignment: parent.columns === 2 ? Text.AlignRight : Text.AlignLeft
                            //: Label for video duration field
                            //% "Duration"
                            key: qsTrId("ytplayer-label-duration")
                        }
                        KeyValueLabel {
                            id: channelName
                            visible: value.length > 0
                            width: parent.width
                            pixelSize: Theme.fontSizeExtraSmall
                            horizontalAlignment: Text.AlignLeft
                            //: Label for channel name text field
                            //% "Channel"
                            key: qsTrId("ytplayer-label-channel")
                        }
                    }

                    YTLikeButtons {
                        id: rating
                        width: parent.width
                        visible: !indicator.running
                        videoId: page.videoId
                    }
                }
            }

            Separator {
                color: Theme.highlightColor
                width: parent.width
            }

            Label {
                id: description
                width: parent.width
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }

        VerticalScrollDecorator {}
    }
}
