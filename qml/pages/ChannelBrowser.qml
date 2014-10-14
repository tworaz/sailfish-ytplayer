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
import "../common"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string channelId
    property string title
    property variant thumbnails
    property variant coverData

    property bool channelSubscribed: false
    property string subscriptionId: ""

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: channelVideoList.busy
        size: BusyIndicatorSize.Large
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (coverData) {
                requestCoverPage("ChannelBrowser.qml", coverData)
            }
            subscriptionMenu.visible = Prefs.isAuthEnabled()
        }
    }

    onChannelIdChanged: {
        if (Prefs.isAuthEnabled()) {
            Log.info("YouTube account integration enabled, checking channel subscription status")
            subscriptionRequest.params = {
                "part"         : "snippet",
                "forChannelId" : channelId,
                "mine"         : true,
            }
            subscriptionRequest.method = YTRequest.List
            subscriptionRequest.run()
        }
    }

    YTRequest {
        id: subscriptionRequest
        resource: "subscriptions"

        onSuccess: {
            switch(method) {
            case YTRequest.List:
                page.channelSubscribed = response.items.length > 0 ? true : false
                if (page.channelSubscribed) {
                    console.assert(response.items.length === 1)
                    page.subscriptionId = response.items[0].id
                    Log.info("Channel " + channelId + " is subscribed by the user")
                } else {
                    page.subscriptionId = ""
                    Log.info("Channel " + channelId + " is not subscribed by the user")
                }
                break
            case YTRequest.Post:
                Log.info("Channel subscribed successfully: " + response.id)
                page.channelSubscribed = true
                page.subscriptionId = response.id
                break
            case YTRequest.Delete:
                Log.info("Channel unsubscribed successfully")
                page.channelSubscribed = false
                page.subscriptionId = ""
                break
            default:
                Log.error("Unrecognized method type: " + method)
                break
            }
        }
    }

    YTVideoList {
        id: channelVideoList
        anchors.fill: parent
        visible: !indicator.running

        property string channelPlaylistId: ""

        onChannelPlaylistIdChanged: {
            videoResourceId = { "kind" : "#channelPlaylist", "id" : channelPlaylistId }
        }

        function changeChanelSubscription(subscribe) {
            if (subscribe) {
                Log.debug("Subscribing channel: " + channelId)
                subscriptionRequest.method = YTRequest.Post
                subscriptionRequest.params = { "part" : "snippet" }
                subscriptionRequest.content = {
                    "snippet" : {
                        "resourceId" : {
                            "kind"      : "youtube#channel",
                            "channelId" : channelId,
                        }
                    }
                }
                subscriptionRequest.run()
            } else {
                Log.debug("Unsubscribing channel: " + page.subscriptionId)
                console.assert(page.subscriptionId.length > 0)
                subscriptionRequest.method = YTRequest.Delete
                subscriptionRequest.params = { "id" : subscriptionId };
                subscriptionRequest.run()
            }
        }

        PullDownMenu {
            MenuItem {
                id: subscriptionMenu
                visible: false
                text: channelSubscribed ?
                          //: Menu option to unsubscribe from YouTube channel
                          //% "Unsubscribe"
                          qsTrId("ytplayer-channel-unsubscribe") :
                          // Menu option to subscribe to YouTube channel
                          //% "Subscribe"
                          qsTrId("ytplayer-channel-subscribe")

                onClicked: channelVideoList.changeChanelSubscription(!page.channelSubscribed)
            }
        }

        PushUpMenu {
            visible: channelVideoList.busy
            busy: true
        }

        header: Column {
            id: channelOverview
            x: Theme.paddingMedium
            width: parent.width - 2 * Theme.paddingMedium
            spacing: Theme.paddingMedium

            YTRequest {
                id: channelRequest
                method: YTRequest.List
                resource: "channels"
                params: {
                    "part" : "snippet,statistics,contentDetails",
                    "id"   : channelId,
                }

                onSuccess: {
                    console.assert(response.kind ==="youtube#channelListResponse" &&
                                   response.items.length === 1 &&
                                   response.items[0].kind === "youtube#channel")

                    var d = new Date(response.items[0].snippet.publishedAt)
                    creationDate.value = Qt.formatDate(d, "d MMMM yyyy")

                    channelVideoList.channelPlaylistId =
                            response.items[0].contentDetails.relatedPlaylists.uploads

                    var stats = response.items[0].statistics
                    videoCount.value = stats.videoCount
                    subscribersCount.text = stats.subscriberCount
                    commentCount.text = stats.commentCount
                    viewCount.text = stats.viewCount
                    indicator.running = false

                    coverData = {
                        "thumbnails" : page.thumbnails,
                        "videoCount" : stats.videoCount,
                        "title"      : title
                    }
                    requestCoverPage("ChannelBrowser.qml", coverData)

                    channelVideoList.refresh()
                }
            }

            Component.onCompleted: {
                Log.info("Channel browser page created for: " + channelId)
                channelRequest.run()
            }

            PageHeader {
                title: page.title
            }

            AsyncImage {
                id: poster
                width: parent.width
                height: width * thumbnailAspectRatio
                indicatorSize: BusyIndicatorSize.Large
                source : {
                    if (thumbnails.high) {
                        return thumbnails.high.url
                    } else if (thumbnails.medium) {
                        return thumbnails.medium.url
                    } else {
                        return thumbnails.default.url
                    }
                }
            }

            Row {
                width: parent.width

                KeyValueLabel {
                    id: creationDate
                    width: parent.width * 2 / 3
                    pixelSize: Theme.fontSizeExtraSmall
                    //: Label for youtube channel creation date field
                    //% "Created on"
                    key: qsTrId("ytplayer-label-created-on")
                }

                KeyValueLabel {
                    id: videoCount
                    width: parent.width / 3
                    pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignRight
                    //: Label for channel video count field
                    //% "Video count"
                    key: qsTrId("ytplayer-label-video-count")
                }
            }

            Row {
                width: parent.width
                spacing: Theme.paddingLarge

                StatItem {
                    id: subscribersCount
                    image: "image://theme/icon-s-favorite?" + Theme.highlightColor
                }

                StatItem {
                    id: commentCount
                    image: "image://theme/icon-s-message?" + Theme.highlightColor
                }

                StatItem {
                    id: viewCount
                    image: "image://theme/icon-s-cloud-download?" + Theme.highlightColor
                }
            }

            Separator {
                color: Theme.highlightColor
                width: parent.width
            }

            Label {
                //: Label/Title for the list of latest videos in certain category
                //% "Latest videos"
                text: qsTrId("ytplayer-label-latest-videos")
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            VerticalScrollDecorator {}
        }
    }
}
