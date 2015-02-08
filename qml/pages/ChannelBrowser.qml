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
import harbour.ytplayer.notifications 1.0
import "../common"

Page {
    id: page
    objectName: "ChannelBrowser"
    allowedOrientations: Orientation.All

    property string channelId
    property string title
    property bool isUserChannel: false

    QtObject {
        id: priv
        property bool channelSubscribed: false
        property string subscriptionId: ""
        property string mobileBannerUrl
        property string normalBannerUrl
        property string currentPosterUrl: ""
        property bool coverDataReady: false
        property variant coverData: {
            "title" : page.title
        }
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: channelVideoList.busy
        size: BusyIndicatorSize.Large
    }

    onOrientationChanged: {
        if (priv.normalBannerUrl && priv.mobileBannerUrl) {
            priv.currentPosterUrl = page.isLandscape ?
                priv.mobileBannerUrl : priv.normalBannerUrl
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (priv.coverDataReady) {
                requestCoverPage("ChannelBrowser.qml", priv.coverData)
            }
            subscriptionMenu.visible = Prefs.isAuthEnabled() && !page.isUserChannel
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

    RemorsePopup {
        id: remorse
    }

    Notification {
        id: subscriptionNotification
        previewBody: page.title
    }

    YTRequest {
        id: subscriptionRequest
        resource: "subscriptions"

        onSuccess: {
            switch (method) {
            case YTRequest.List:
                priv.channelSubscribed = response.items.length > 0 ? true : false
                if (priv.channelSubscribed) {
                    console.assert(response.items.length === 1)
                    priv.subscriptionId = response.items[0].id
                    Log.info("Channel " + channelId + " is subscribed by the user")
                } else {
                    priv.subscriptionId = ""
                    Log.info("Channel " + channelId + " is not subscribed by the user")
                }
                break
            case YTRequest.Post:
                Log.info("Channel subscribed successfully: " + response.id)
                priv.channelSubscribed = true
                priv.subscriptionId = response.id
                //: Notification summary telling the user channel was succesfully subscribed
                //% "Channel subscribed"
                subscriptionNotification.previewSummary = qsTrId("ytplayer-msg-channel-subscribed")
                subscriptionNotification.publish()
                break
            case YTRequest.Delete:
                Log.info("Channel unsubscribed successfully")
                priv.channelSubscribed = false
                priv.subscriptionId = ""
                //: Notification summary telling the user channel was succesfully unsubscribed
                //% "Channel unsubscribed"
                subscriptionNotification.previewSummary = qsTrId("ytplayer-msg-channel-unsubscribed")
                subscriptionNotification.publish()
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
        indicatorCenterInlistview: true

        property string channelPlaylistId: ""

        onChannelPlaylistIdChanged: {
            videoResourceId = { "kind" : "#channelPlaylist", "id" : channelPlaylistId }
        }

        onRequestComplete: {
            if (priv.coverDataReady)
                return

            var d = priv.coverData
            d.thumbnails = []
            var maxThumbs = Math.min(kMaxCoverThumbnailCount, response.items.length)
            for (var i = 0; i < maxThumbs; ++i)
                d.thumbnails.push(response.items[i].snippet.thumbnails)
            priv.coverData = d
            priv.coverDataReady = true
            requestCoverPage("ChannelBrowser.qml", priv.coverData)
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
                Log.debug("Unsubscribing channel: " + priv.subscriptionId)
                console.assert(priv.subscriptionId.length > 0)
                subscriptionRequest.method = YTRequest.Delete
                subscriptionRequest.params = { "id" : priv.subscriptionId };
                subscriptionRequest.run()
            }
        }

        PullDownMenu {
            visible: subscriptionMenu.visible
            MenuItem {
                id: subscriptionMenu
                visible: false
                text: priv.channelSubscribed ?
                          //: Menu option to unsubscribe from YouTube channel
                          //% "Unsubscribe"
                          qsTrId("ytplayer-channel-unsubscribe") :
                          // Menu option to subscribe to YouTube channel
                          //% "Subscribe"
                          qsTrId("ytplayer-channel-subscribe")

                onClicked: {
                    if (priv.channelSubscribed) {
                        //: Remorse popup message telling the user channel is about to be unsubscribed
                        //% "Unsubscribing channel"
                        remorse.execute(qsTrId("ytplayer-msg-unsubscribing-channel"), function() {
                            channelVideoList.changeChanelSubscription(false)
                        })
                    } else {
                        channelVideoList.changeChanelSubscription(true)
                    }
                }
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
                    "part" : "snippet,statistics,contentDetails,brandingSettings",
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
                    indicator.running = false

                    var banner = undefined
                    var brandingSettings = response.items[0].brandingSettings
                    if (brandingSettings.image.bannerMobileImageUrl) {
                        priv.mobileBannerUrl = brandingSettings.image.bannerMobileImageUrl
                        priv.normalBannerUrl = brandingSettings.image.bannerImageUrl
                        priv.currentPosterUrl = page.isPortrait ?
                            priv.mobileBannerUrl : priv.normalBannerUrl
                    } else {
                        if (response.items[0].snippet.thumbnails.high) {
                            poster.source = response.items[0].snippet.thumbnails.high.url
                        } else {
                            poster.source = response.items[0].snippet.thumbnails.default.url
                        }
                    }

                    var coverData = priv.coverData
                    if (priv.mobileBannerUrl)
                        coverData.bannerUrl = priv.mobileBannerUrl
                    priv.coverData = coverData

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
                fillMode: Image.PreserveAspectFit
                height: status === Image.Ready ?
                            priv.currentPosterUrl ?
                                sourceSize.height * width / sourceSize.width :
                                sourceSize.height :
                            154
                indicatorSize: BusyIndicatorSize.Medium
                source: priv.currentPosterUrl
                cache: false
            }

            Flow {
                width: parent.width

                KeyValueLabel {
                    id: creationDate
                    horizontalAlignment: Text.AlignLeft
                    pixelSize: Theme.fontSizeExtraSmall
                    //: Label for youtube channel creation date field
                    //% "Created on"
                    key: qsTrId("ytplayer-label-created-on")
                }

                KeyValueLabel {
                    id: videoCount
                    width: parent.width - creationDate.width
                    pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignRight
                    //: Label for channel video count field
                    //% "Video count"
                    key: qsTrId("ytplayer-label-video-count")
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
