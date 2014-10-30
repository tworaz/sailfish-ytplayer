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

    property alias videoId: localVideo.videoId
    property alias title: titleLabel.text
    property variant thumbnails

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
        property variant channelBrowserData: ({})
        property Item playerPage
        readonly property real sideMargin: Theme.paddingMedium
    }

    function handleStreamChange(streams) {
        if (!priv.playerPage) {
            Log.debug("Player page not attached, pushing it")
            console.assert(page.thumbnails.hasOwnProperty("default"))
            priv.playerPage = pageStack.pushAttached(Qt.resolvedUrl("VideoPlayer.qml"), {
                "thumbnails" : thumbnails,
                "videoId"    : videoId,
                "title"      : title,
                "streams"    : streams,
            })
        } else {
            console.assert(priv.playerPage.hasOwnProperty("streams"))
            priv.playerPage.streams = streams
        }
    }

    Component.onCompleted: {
        Log.debug("Video overview page for video ID: " + videoId + " created")
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if (!request.loaded)
                request.run()

            rating.enabled = Prefs.isAuthEnabled()
        } else if (status === PageStatus.Active) {
            if (!priv.playerPage) {
                if (localVideo.status === YTLocalVideo.Downloaded) {
                    if (!page.thumbnails.hasOwnProperty("default"))
                        page.thumbnails = localVideo.thumbnails
                    handleStreamChange(localVideo.streams)
                }
            }
        }
    }

    RemorsePopup {
        id: remorse
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

            page.thumbnails = details.snippet.thumbnails

            titleLabel.text = details.snippet.title
            indicator.running = false

            channelName.value = details.snippet.channelTitle
            priv.channelBrowserData = {
                "channelId" : details.snippet.channelId,
                "title"     : details.snippet.channelTitle,
            }

            requestCoverPage("VideoOverview.qml", {
                "thumbnails" : page.thumbnails,
                "videoId"    : page.videoId,
                "title"      : page.title
            })

            var browserPage = pageStack.find(function(page) {
                if (page.objectName === "ChannelBrowser")
                    return true
                return false
            })
            if (!browserPage)
                channelBrowserMenu.visible = true

            if (localVideo.status !== YTLocalVideo.Downloaded && !streamUrlRequest.loaded)
                streamUrlRequest.run()
        }
    }

    YTRequest {
        id: streamUrlRequest
        method: YTRequest.List
        resource: "video/url"
        params: {
            "video_id" : videoId,
        }
        onSuccess: handleStreamChange(response)
    }

    YTLocalVideo {
        id: localVideo

        onStatusChanged: {
            localVideoStatus.updateLabel(status)
            switch (status) {
            case YTLocalVideo.Initial:
                Log.info("Video is not stored locally")
                break
            case YTLocalVideo.Queued:
                Log.info("Video was queued for download")
                break
            case YTLocalVideo.Loading:
                Log.info("Video is loading")
                break
            case YTLocalVideo.Downloaded:
                Log.info("Video data storred locally and available for playback")
                page.thumbnails = localVideo.thumbnails
                if (!pageStack.busy && priv.playerPage)
                    handleStreamChange(localVideo.streams)
                break
            }
        }

        onDownloadProgressChanged: {
            localVideoStatus.progressChanged(downloadProgress)
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
                visible: localVideo.canDownload
                //: Label for menu option triggering video preload
                //% "Download video"
                text: qsTrId("ytplayer-action-download-video")
                onClicked: localVideo.download()
            }
            MenuItem {
                visible: localVideo.status !== YTLocalVideo.Initial &&
                         localVideo.status !== YTLocalVideo.Downloaded
                //: Label for menu option canceling pending/in progress video preload
                //% "Cancel video download"
                text: qsTrId("ytplayer-action-cancel-download")
                onClicked: {
                    //: Remorse popup message telling the user video download will be cancelled
                    //% "Cancelling download"
                    remorse.execute(qsTrId("ytplayer-msg-cancelling-download") , function() {
                        localVideo.remove()
                    })
                }
            }
            MenuItem {
                visible: localVideo.status === YTLocalVideo.Loading
                //: "Label for menu option allowing the user to pause video download"
                //% "Pause video download"
                text: qsTrId("ytplayer-action-pause-download")
                onClicked: localVideo.pause()
            }
            MenuItem {
                visible: localVideo.status === YTLocalVideo.Paused
                //: "Label for menu option allowing the user to resume video download"
                //% "Resume video download"
                text: qsTrId("ytplayer-action-resume-download")
                onClicked: localVideo.resume()
            }
            MenuItem {
                visible: localVideo.status === YTLocalVideo.Downloaded
                //: Label for menu option allowing the user to remove downloaded video
                //% "Remove video download"
                text: qsTrId("ytplayer-action-remove-download")
                onClicked: {
                    //: Remorse popup message telling the user video download will be removed
                    //% "Removing download"
                    remorse.execute(qsTrId("ytplayer-msg-removing-download") , function() {
                        localVideo.remove()
                    })
                }
            }
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

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: childrenRect.width + 2 * Theme.paddingMedium
                        height: childrenRect.height
                        property bool enabled: localVideo.status !== YTLocalVideo.Initial
                        opacity: enabled ? 1.0 : 0.0
                        visible: opacity !== 0.0
                        color: "#AA000000"
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                            }
                        }

                        Label {
                            id: localVideoStatus
                            x: Theme.paddingMedium
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall

                            function updateLabel(status) {
                                switch (status) {
                                case YTLocalVideo.Downloaded:
                                    //: Label indicating the video was downloaded to local device storage
                                    //% "Downloaded"
                                    text = qsTrId("ytplayer-label-video-downloaded")
                                    break
                                case YTLocalVideo.Queued:
                                    //: "Label indicating video was queued for preload"
                                    //% "Download queued"
                                    text = qsTrId("ytplayer-label-video-queued")
                                    break
                                case YTLocalVideo.Loading:
                                    ////: "Label indicating video download is in progress"
                                    ////% "Downloading"
                                    //text = qsTrId("ytplayer-label-video-downloading")
                                    progressChanged(localVideo.downloadProgress)
                                    break
                                case YTLocalVideo.Paused:
                                    //: "Label indicating video download was paused"
                                    //% "Download paused"
                                    text = qsTrId("ytplayer-label-video-download-paused")
                                    break
                                }
                            }

                            function progressChanged(progress) {
                                //: "Label indicating video download progress with actual percentage value"
                                //% "Downloading: %1%"
                                text = qsTrId("ytplayer-label-video-downloading-percentage").arg(progress)
                            }
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
