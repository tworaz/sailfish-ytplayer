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

    states: [
        State {
            name: "SUBSCRIPTION_CHANNELS"
            PropertyChanges {
                target: priv
                //: YouTube subscribed channels page title
                //% "Subscribed channels"
                title: qsTrId("ytplayer-title-subscribed-channels")
                topPulleyVisible: true
            }
        },
        State {
            name: "SUBSCRIPTION_VIDEOS"
            PropertyChanges {
                target: priv
                //: YouTube latest subscribed videos page title
                //% "Latest videos"
                title: qsTrId("ytplayer-title-subscription-videos")
                topPulleyVisible: false
            }
        },
        State {
            name: "LIKES"
            PropertyChanges {
                target: priv
                //: YouTube likes page title
                //% "Likes"
                title: qsTrId("ytplayer-title-likes")
                topPulleyVisible: false
            }
        },
        State {
            name: "DISLIKES"
            PropertyChanges {
                target: priv
                //: YouTube dislikes page title
                //% "Dislikes"
                title: qsTrId("ytplayer-title-dislikes")
                topPulleyVisible: false
            }
        },
        State {
            name: "RECOMMENDED"
            PropertyChanges {
                target: priv
                //: YouTube recommendations page title
                //% "Recommended for you"
                title: qsTrId("ytplayer-title-recommended")
                topPulleyVisible: false
            }
        }
    ]

    QtObject {
        id: priv
        property string title: ""
        property alias topPulleyVisible: topPulley.visible
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            Log.info("Account page activated, state: " + state)
            if (!YTPrefs.isAuthEnabled()) {
                Log.info("YouTube authorization disabled, returning to categories page")
                pageStack.replaceAbove(null, Qt.resolvedUrl("VideoCategories.qml"))
                return
            }
            if (listModel.count === 0) {
                loadDataForCurrentState()
            }
            requestCoverPage("Default.qml")
        }
    }

    function loadDataForCurrentState(token) {
        var params = {}
        if (state === "SUBSCRIPTION_CHANNELS") {
            request.resource = "subscriptions"
            params = {
                "part" : "id,snippet",
                "mine" : true,
                "order": "alphabetical",
            }
        } else if (state === "LIKES") {
            request.resource = "videos"
            params = {
                "part"     : "snippet,contentDetails",
                "myRating" : "like"
            }
        } else if (state === "DISLIKES") {
            request.resource = "videos"
            params = {
                "part"     : "snippet,contentDetails",
                "myRating" : "dislike"
            }
        } else if (state === "RECOMMENDED") {
            request.resource = "activities"
            params = {
                "part"       : "id,snippet,contentDetails",
                "home"       : true,
            }
            listModel.filter.key = "snippet.type"
            listModel.filter.value = "recommendation"
        } else if (state === "SUBSCRIPTION_VIDEOS") {
            request.resource = "activities"
            params = {
                "part"       : "id,snippet,contentDetails",
                "home"       : true,
            }
            listModel.filter.key = "snippet.type"
            listModel.filter.value = "upload"
        } else {
            console.assert(false)
        }

        if (token) {
            params.pageToken = token
        }
        request.params = params

        request.run()
    }

    YTRequest {
        id: request
        method: YTRequest.List
        model: listModel
        onSuccess: {
            if (response.nextPageToken) {
                listView.nextPageToken = response.nextPageToken
            } else {
                listView.nextPageToken = ""
            }
        }
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: request.busy && (listModel.count === 0)
    }

    YTListView {
        id: listView
        anchors.fill: parent
        property string nextPageToken: ""

        PullDownMenu {
            id: topPulley
            busy: request.busy
            MenuItem {
                //: Sub-Menu option responsible for showing latest subsribed videos page
                //% "Latest videos"
                text: qsTrId("ytplayer-action-latest-subscribed-videos")
                visible: parent.visible
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                    { "state" : "SUBSCRIPTION_VIDEOS"  })
            }
        }

        header: PageHeader {
            title: priv.title
        }

        model: YTListModel {
            id: listModel
        }

        delegate: YTListItem {
            title: snippet.title
            thumbnails: snippet.thumbnails
            youtubeId: {
                if (snippet.hasOwnProperty("resourceId")) {
                    return snippet.resourceId
                } else if (kind && kind === "youtube#video") {
                    return { "kind" : kind, "videoId" : id }
                } else if (kind && kind === "youtube#activity") {
                    if (snippet.type === "upload") {
                        return { "kind"    : "youtube#video",
                                 "videoId" : contentDetails.upload.videoId }
                    } else if (snippet.type === "recommendation") {
                        return contentDetails.recommendation.resourceId;
                    } else {
                        Log.error("Unhandled activity type: " + snippet.type);
                        Log.error(JSON.stringify(contentDetails, undefined, 2))
                        return undefined;
                    }
                } else if (kind && kind === "youtube#channel") {
                    return { "kind": kind, "channelId": id }
                } else {
                    Log.error("Unknown item type in the list: " +
                              JSON.stringify(listModel.get(index), undefined, 2))
                    return undefined
                }
            }
            duration: {
                if (typeof contentDetails !== 'undefined' &&
                    contentDetails.hasOwnProperty("duration"))
                    return contentDetails.duration
                return ""
            }
        }

        onAtYEndChanged: {
            if (atYEnd && nextPageToken.length > 0 && !request.busy) {
                page.loadDataForCurrentState(nextPageToken)
            }
        }

        VerticalScrollDecorator {}
    }
}
