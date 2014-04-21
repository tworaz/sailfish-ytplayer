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

Page {
    id: root

    property bool loadingData: false
    property bool reloadOnActivate: false
    state: "SUBSCRIPTIONS"

    states: [
        State {
            name: "SUBSCRIPTIONS"
        },
        State {
            name: "LIKES"
        },
        State {
            name: "DISLIKES"
        }
    ]

    onStateChanged: {
        Log.debug("Now showing: " + state)
        listModel.clear()
        listView.etag = ""
        listView.nextPageToken = ""
        fetchDataForCurrentState()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!Prefs.isAuthEnabled()) {
                Log.info("YouTube authorization disabled, returning to categories page")
                pageStack.replace(Qt.resolvedUrl("VideoCategories.qml"))
                return
            }

            Log.info("Subscriptions page activated, loading user subscriptions list")
            requestCoverPage("Default.qml")
            if (reloadOnActivate) {
                fetchDataForCurrentState()
            }
        } else if (status === PageStatus.Inactive) {
            reloadOnActivate = true
        }
    }

    function fetchDataForCurrentState(token) {
        loadingData = true
        if (state === "SUBSCRIPTIONS") {
            Yt.getSubscriptions(onVideoListFetched, onError, token)
        } else if (state === "LIKES") {
            Yt.getVideosForRanking(Yt.VIDEO_RANKING_LIKE, onVideoListFetched, onError, token)
        } else if (state === "DISLIKES") {
            Yt.getVideosForRanking(Yt.VIDEO_RANKING_DISLIKE, onVideoListFetched, onError, token)
        }
    }

    function onVideoListFetched(response) {
        loadingData = false

        if (reloadOnActivate) {
            reloadOnActivate = false
            if (response.etag === listView.etag) {
                return
            }
            listView.etag = ""
            listView.nextPageToken = ""
            listModel.clear()
        }

        for (var i = 0; i < response.items.length; ++i) {
            listModel.append(response.items[i])
        }
        if (response.nextPageToken !== undefined) {
            listView.nextPageToken = response.nextPageToken
        } else {
            listView.nextPageToken = ""
        }
        listView.etag = response.etag
    }

    function onError(error) {
        loadingData = false
        errorNotification.show(error)
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: loadingData && (listModel.count === 0)
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        property string etag: ""
        property string nextPageToken: ""
        property Item contextMenu

        Label {
            anchors.centerIn: parent
            color: Theme.secondaryHighlightColor
            //: Background text informing the user there are no videos in a given category
            //% "No content"
            text: qsTrId("ytplayer-account-no-content")
            visible: listModel.count === 0 && loadingData === false
        }

        YTPagesTopMenu {
            busy: root.loadingData
            accountMenuVisible: false
        }

        PushUpMenu {
            visible: listView.nextPageToken.length > 0
            busy: root.loadingData
            quickSelect: true
            MenuItem {
                visible: parent.visible
                //: Menu option show/load additional list elements
                //% "Show more"
                text: qsTrId("ytplayer-action-show-more")
                onClicked: root.fetchDataForCurrentState(nextPageToken)
            }
        }

        header: Column {
            width: parent.width
            PageHeader {
                //: Title of user's YouTube accound details page
                //% "My Account"
                title: qsTrId("ytplayer-account-page-title")
            }
            ComboBox {
                width: parent.width
                //: Label for combo box allowing the user to view different video categories
                //: on uesr account page. The possible categires are, subscriptions, likes, dislikes
                //% "My"
                label: qsTrId("ytplayer-account-video-categories-label")
                menu: ContextMenu {
                    MenuItem {
                        //: Label for combo box item responsible for showing user's YouTube ChannelBrowser
                        //: subscriptions
                        //% "Subscriptions"
                        text: qsTrId("ytplayer-account-subscriptions-label")
                        onClicked: root.state = "SUBSCRIPTIONS"
                    }
                    MenuItem {
                        //: Label for combo box item repsonsible for displaying user's YouTube liked videos
                        //% "Likes"
                        text: qsTrId("ytplayer-account-likes-label")
                        onClicked: root.state = "LIKES"
                    }
                    MenuItem {
                        //: Label for combo box item responsible for displaying user's YouTube disliked videos
                        //% "Dislikes"
                        text: qsTrId("ytplayer-account-dislikes-label")
                        onClicked: root.state = "DISLIKES"
                    }
                }
            }
        }

        model: ListModel {
            id: listModel
        }

        delegate: YTListItem {
            title: snippet.title
            thumbnails: snippet.thumbnails
            //youtubeId: snippet.resourceId
            youtubeId: {
                if (snippet.hasOwnProperty("resourceId")) {
                    return snippet.resourceId
                } else if (kind && kind === "youtube#video") {
                    return { "kind" : kind, "videoId" : id }
                } else {
                    Log.error("Unknown item in the list!")
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
