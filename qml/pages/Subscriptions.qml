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
    property bool initialLoad: false

    onStatusChanged: {
        if (status === PageStatus.Active) {
            Log.info("Subscriptions page activated, loading user subscriptions list")
            requestCoverPage("Default.qml")
            initialLoad = loadingData = true
            Yt.getSubscriptions(onSubscriptionsDataFetched, function(error) {
                loadingData = false
                errorNotification.show(error)
            })
        }
    }

    function onSubscriptionsDataFetched(response) {
        Log.info("User subscriptions data fetched")
        console.assert(response.kind === "youtube#subscriptionListResponse")

        if (initialLoad && listView.count > 0) {
            Log.debug("Initial page load, clearing list")
            listModel.clear()
        }
        initialLoad = false

        for (var i = 0; i < response.items.length; ++i) {
            listModel.append(response.items[i])
        }
        if (response.nextPageToken !== undefined) {
            listView.nextPageToken = response.nextPageToken
        } else {
            listView.nextPageToken = ""
        }
        loadingData = false
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

        property string nextPageToken: ""

        YTPagesTopMenu {
            busy: root.loadingData
            subscriptionsMenuVisible: false
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
                onClicked: {
                    root.loadingData = true
                    Yt.getSubscriptions(root.onSubscriptionsDataFetched, function (error) {
                        root.loadingData = false
                        errorNotification.show(error)
                    }, nextPageToken)
                }
            }
        }

        header: PageHeader {
            //: Title of user YouTube scubscriptions list page
            //% "Subscriptions"
            title: qsTrId("ytplayer-title-subscriptions")
        }

        model: ListModel {
            id: listModel
        }

        delegate: YTListItem {
            title: snippet.title
            thumbnails: snippet.thumbnails
            youtubeId: snippet.resourceId
        }

        VerticalScrollDecorator {}
    }
}
