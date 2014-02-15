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
    id: page
    property string videoCategoryId
    property string title
    property string nextPageToken

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    SilicaListView {
        id: videoListView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //: Menu option to refresh content of the list
                //% "Refresh"
                text: qsTrId("ytplayer-action-refresh")
                onClicked: videoListView.refresh()
            }
        }

        PushUpMenu {
            visible: page.nextPageToken.length > 0;
            MenuItem {
                //: Menu option load additional list elements
                //% "Load More"
                text: qsTrId("ytplayer-action-load-more")
                onClicked: {
                    videoListView.loadNextResultsPage()
                    indicator.running = true;
                }
            }
        }

        header: PageHeader {
            title: page.title
        }

        model: ListModel {
            id: videoListModel
        }

        delegate: YoutubeListItem {
            width: parent.width
            title: snippet.title
            thumbnailUrl: snippet.thumbnails.default.url
            youtubeId: {"kind" : kind, "videoId" : id}
        }

        function onFailure(error) {
            networkErrorNotification.show(error);
            indicator.running = false
        }

        function onVideoListLoaded(response) {
            for (var i = 0; i < response.items.length; i++) {
                videoListModel.append(response.items[i]);
            }
            if (response.nextPageToken !== undefined) {
                nextPageToken = response.nextPageToken
            } else {
                nextPageToken = "";
            }
            indicator.running = false
        }

        function loadNextResultsPage() {
            Yt.getVideosInCategory(page.videoCategoryId, onVideoListLoaded, onFailure, nextPageToken);
        }

        function refresh() {
            indicator.running = true
            videoListModel.clear()
            Yt.getVideosInCategory(page.videoCategoryId, onVideoListLoaded, onFailure)
        }

        Component.onCompleted: {
            console.debug("Video list page created")
            Yt.getVideosInCategory(page.videoCategoryId, onVideoListLoaded, onFailure)
        }

        VerticalScrollDecorator {}
    }
}
