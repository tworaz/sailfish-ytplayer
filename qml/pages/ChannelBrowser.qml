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
import "../common"

Page {
    id: page
    property string channelId
    property string title
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
            subscriptionMenu.visible = Yt.isAuthEnabled()
        }
    }

    onChannelIdChanged: {
        if (Yt.isAuthEnabled()) {
            console.debug("Authorization enabled, checking channel subscription status")
            Yt.isChannelSubscribed(channelId, function(response) {
                page.channelSubscribed = response ? true : false
                console.debug("Channel subscribed: " + page.channelSubscribed)
                if (page.channelSubscribed) {
                    page.subscriptionId = response.id
                    console.debug("Subscription ID: " + page.subscriptionId)
                } else {
                    page.subscriptionId = "";
                }
            }, function(error) {
                errorNotification.show(error)
            });
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
                console.debug("Subscribing channel: " + channelId)
                Yt.subscribeChannel(channelId, function(response) {
                    console.debug("Channel subscribed successfully: " + response.id)
                    page.channelSubscribed = true
                    page.subscriptionId = response.id
                }, function(error) {
                    errorNotification.show(error)
                })
            } else {
                console.debug("Unsubscribing channel: " + page.subscriptionId);
                console.assert(page.subscriptionId.length > 0)
                Yt.unsubscribe(page.subscriptionId, function(response) {
                    console.debug("Channel unsubscribed successfully")
                    page.channelSubscribed = false
                    page.subscriptionId = ""
                }, function (error) {
                    errorNotification.show(error);
                });
            }
        }

        PullDownMenu {
            MenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                id: subscriptionMenu
                visible: false
                // TODO: translate
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
            visible: (channelVideoList.hasNextPage || channelVideoList.busy)
            busy: channelVideoList.busy
            quickSelect: true
            MenuItem {
                //: Menu option show/load additional list elements
                //% "Show more"
                text: qsTrId("ytplayer-action-show-more")
                onClicked: channelVideoList.loadNextResultsPage()
            }
        }

        header: Column {
            id: channelOverview
            x: Theme.paddingMedium
            width: parent.width - 2 * Theme.paddingMedium
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.title
            }

            AsyncImage {
                id: poster
                width: parent.width
                height: width * thumbnailAspectRatio
                indicatorSize: BusyIndicatorSize.Large
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

            Component.onCompleted: {
                console.debug("Channel browser page created for: " + channelId)
                Yt.getChannelDetails(channelId, onChannelDetailsFetched, onChannelDetailsFetchFailed)
            }

            function onChannelDetailsFetched(result) {
                console.assert(result.items[0].kind === "youtube#channel")

                var details = result.items[0].snippet
                if (details.thumbnails.hasOwnProperty("high")) {
                    poster.source = details.thumbnails.high.url
                } else if (details.thumbnails.hasOwnProperty("medium")) {
                    poster.source = details.thumbnails.medium.url
                } else {
                    console.debug("No appropriate channel thumbnail found: " +
                                  JSON.stringify(details.thumbnail, undefined, 2))
                    poster.visible = false
                }
                var d = new Date(details.publishedAt)
                creationDate.value = Qt.formatDate(d, "d MMMM yyyy")

                channelVideoList.channelPlaylistId = result.items[0].contentDetails.relatedPlaylists.uploads

                var stats = result.items[0].statistics
                videoCount.value = stats.videoCount
                subscribersCount.text = stats.subscriberCount
                commentCount.text = stats.commentCount
                viewCount.text = stats.viewCount
                indicator.running = false

                coverData = { "title" : title, "thumbnailUrl" : poster.source, "videoCount" : stats.videoCount }
                requestCoverPage("ChannelBrowser.qml", coverData)

                channelVideoList.refresh()
            }

            function onChannelDetailsFetchFailed(error) {
                errorNotification.show(error)
                indicator.running = false
            }
        }
    }
}
