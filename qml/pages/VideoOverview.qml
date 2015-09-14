// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.ytplayer 1.0
import harbour.ytplayer.notifications 1.0
import "../common/Helpers.js" as Helpers
import "../common/duration.js" as DJS
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
        },
        State {
            name: "LANDSCAPE"
            PropertyChanges { target: content; columns: 2; spacing: Theme.paddingMedium }
        }
    ]

    QtObject {
        id: priv
        property variant channelBrowserData: ({})
        property string iso_duration: ""
        property Item playerPage: null
        property bool haveStreams: true
        property bool videoNoLongerAvailable: false
        property bool hasDirectVideoUrl: priv.playerPage !== null &&
                                         priv.playerPage.streams !== undefined
        readonly property real sideMargin: Theme.paddingMedium
    }

    Connections {
        target: priv.playerPage
        property bool addedToWatchedRecently: false
        onPlaybackStarted: {
            if (!addedToWatchedRecently) {
                Log.debug("Video " + videoId + " added to watched recently list")
                YTWatchedRecently.addVideo(videoId, title,
                    thumbnails.default.url, priv.iso_duration)
                addedToWatchedRecently = true
            }
        }
        onNoStreamsAvailable: {
            Log.debug("No video streams available, removing attached player page")
            if (priv.playerPage) {
                pageStack.popAttached(PageStackAction.Animated)
                priv.playerPage = null
            }
            priv.haveStreams = false
        }
    }

    function play() {
        if (priv.playerPage) {
            pageStack.navigateForward(PageStackAction.Animated)
        }
    }

    Component.onCompleted: {
        Log.debug("Video overview page for video ID: " + videoId + " created")
        channelBrowserMenuOption.visible = !pageStack.find(function(page) {
            if (page.objectName === "ChannelBrowser")
                return true
            return false
        })
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if (!request.loaded)
                request.run()
            rating.enabled = YTPrefs.isAuthEnabled()
        } else if (status === PageStatus.Active) {
            if (!priv.playerPage && priv.haveStreams) {
                priv.playerPage = pageStack.pushAttached(Qt.resolvedUrl("VideoPlayer.qml"), {
                    "videoId"      : videoId,
                    "title"        : title,
                    "localVideo"   : localVideo
                })
            }
            if (priv.videoNoLongerAvailable) {
                pageStack.pop()
                return
            }

            if (page.thumbnails.hasOwnProperty("default")) {
                requestCoverPage("VideoOverview.qml", {
                    "thumbnails" : page.thumbnails,
                    "title"      : page.title,
                    "parent"     : page
                })
            }
        }
    }

    Notification {
        id: videoNoLongerAvailableNotification
        //: Notification summary informing the user video is no longer available.
        //% "Video no longer available"
        previewSummary: qsTrId("ytplayer-msg-video-unavailable")
        //: Notification body explaining why video is no longer available.
        //% "Video was removed from YouTube"
        previewBody: qsTrId("ytplayer-msg-video-unavailable-desc")
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

            if (response.items.length === 0) {
                console.error("Video no longer available!")
                priv.videoNoLongerAvailable = true
                videoNoLongerAvailableNotification.publish()
                if (page.status === PageStatus.Active) {
                    pageStack.pop()
                }
                return
            }

            console.assert(response.items[0].kind === "youtube#video")

            var details = response.items[0]

            if (details.snippet.description) {
                description.text = Helpers.plainToStyledText(details.snippet.description)
            } else {
                description.visible = false
            }

            rating.likes = details.statistics.likeCount
            rating.dislikes = details.statistics.dislikeCount
            rating.dataValid = true

            var pd = new Date(details.snippet.publishedAt)
            var loc = Qt.locale(YTTranslations.language)
            publishDate.value = pd.toLocaleDateString(loc, Locale.ShortFormat)
            priv.iso_duration = details.contentDetails.duration
            duration.value = (new DJS.Duration(priv.iso_duration)).asClock()

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
                "title"      : page.title,
                "parent"     : page
            })
        }
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
                visible: localVideo.canDownload && priv.hasDirectVideoUrl
                //: Menu option triggering video preload
                //% "Download video"
                text: qsTrId("ytplayer-action-download-video")
                onClicked: localVideo.download(page.title)
            }
            MenuItem {
                visible: localVideo.status !== YTLocalVideo.Initial &&
                         localVideo.status !== YTLocalVideo.Downloaded
                //: Menu option canceling pending/in progress video preload
                //% "Cancel download"
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
                //: Menu option allowing the user to pause video download
                //% "Pause download"
                text: qsTrId("ytplayer-action-pause-download")
                onClicked: localVideo.pause()
            }
            MenuItem {
                visible: localVideo.status === YTLocalVideo.Paused
                //: Menu option allowing the user to resume video download
                //% "Resume download"
                text: qsTrId("ytplayer-action-resume-download")
                onClicked: localVideo.resume()
            }
            MenuItem {
                visible: localVideo.status === YTLocalVideo.Downloaded
                //: Menu option allowing the user to remove downloaded video
                //% "Remove download"
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
                //: Menu option copying video link to clipboard
                //% "Copy link to clipboard"
                text: qsTrId("ytplayer-action-copy-link-to-clipboard")
                onClicked: {
                    Clipboard.text = kYoutubeVideoUrlBase + videoId
                    clipboardNotification.publish()
                }
                Notification {
                    id: clipboardNotification
                    //: Notification summary informing the user link was copied to clipboard
                    //% "Link copied"
                    previewSummary: qsTrId("ytplayer-msg-link-copied")
                    previewBody: Clipboard.text
                }
            }
            MenuItem {
                //: Menu option opening YouTube video page in a web browser
                //% "Open in browser"
                text: qsTrId("ytplayer-action-open-in-browser")
                onClicked: openLinkInBrowser(kYoutubeVideoUrlBase + videoId)
            }

            MenuItem {
                id: channelBrowserMenuOption
                //: menu option allowing the user to browser YouTube channel
                //% "Browser channel"
                text: qsTrId("ytplayer-action-browse-channel")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("ChannelBrowser.qml"),
                        priv.channelBrowserData)
                    if (priv.playerPage) {
                        priv.playerPage.isAttached = false
                        priv.playerPage = null
                    }
                }
            }
        }

        HeaderButton {
            id: header
            anchors.top: parent.top
            anchors.right: parent.right
            isPortrait: page.isPortrait
            text: priv.haveStreams ?
                      //: Label for video play button.
                      //% "Play"
                      qsTrId("ytplayer-label-play") :
                      //: Label indicating current video has no valid streams. It
                      //: replaces Play button in the video overview page header.
                      //% "No streams!"
                      qsTrId("ytplayer-label-no-streams")
            onClicked: page.play()
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

                    function pickUrl() {
                        if (thumbnails.high) {
                            source = thumbnails.high.url
                        } else if (thumbnails.medium) {
                            source = thumbnails.medium.url
                        } else {
                            source = thumbnails.default.url
                        }
                    }

                    Component.onCompleted: {
                        if (page.thumbnails)
                            pickUrl();
                    }

                    Connections {
                        target: page
                        onThumbnailsChanged: poster.pickUrl()
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: childrenRect.width + 2 * Theme.paddingMedium
                        height: childrenRect.height
                        property bool enabled: localVideo.status !== YTLocalVideo.Initial &&
                                               parent.visible
                        opacity: enabled ? 1.0 : 0.0
                        visible: opacity !== 0.0
                        color: "#AA000000"
                        Behavior on opacity {
                            FadeAnimation {}
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

                    Row {
                        width: parent.width

                        Column {
                            width: parent.width - favButton.width
                            KeyValueLabel {
                                id: publishDate
                                pixelSize: Theme.fontSizeExtraSmall
                                //: Label for video upload date field
                                //% "Published on"
                                key: qsTrId("ytplayer-label-publish-date")
                            }
                            KeyValueLabel {
                                id: duration
                                pixelSize: Theme.fontSizeExtraSmall
                                //: Label for video duration field
                                //% "Duration"
                                key: qsTrId("ytplayer-label-duration")
                            }
                            KeyValueLabel {
                                id: channelName
                                pixelSize: Theme.fontSizeExtraSmall
                                //: Label for channel name text field
                                //% "Channel"
                                key: qsTrId("ytplayer-label-channel")
                            }
                        }

                        FavoriteVideoButton {
                            id: favButton
                            height: parent.height
                            width: height
                            videoId: page.videoId
                            title: page.title
                            thumbnails: page.thumbnails
                            duration: priv.iso_duration
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
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                linkColor: Theme.highlightColor
                onLinkActivated: openLinkInBrowser(link)
            }
        }

        VerticalScrollDecorator {}
    }
}
