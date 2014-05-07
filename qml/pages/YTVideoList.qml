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

SilicaListView {
    id: root
    property alias count: videoListModel.count
    property alias busy: request.busy

    property variant videoResourceId: {"kind" : "", "id" : ""}
    property string nextPageToken: ""
    property bool hasNextPage: nextPageToken.length > 0

    model: ListModel {
        id: videoListModel
    }

    delegate: YTListItem {
        width: parent.width
        title: snippet.title
        thumbnails: snippet.thumbnails
        youtubeId: {
            var y = undefined;
            if (videoResourceId.kind === "youtube#videoCategory") {
                y = { "kind" : kind, "videoId" : id }
            } else if (videoResourceId.kind === "#channelPlaylist") {
                y = snippet.resourceId;
            } else {
                console.assert(false)
            }
            return y;
        }
    }

    YTRequest {
        id: request
        method: YTRequest.List

        onSuccess: {
            console.assert(response.kind === "youtube#playlistItemListResponse" ||
                           response.kind === "youtube#videoListResponse")
            if (response.nextPageToken !== undefined) {
                nextPageToken = response.nextPageToken
            } else {
                nextPageToken = ""
            }
            utilityWorkerScript.appendToModel(videoListModel, response.items)
        }
    }

    function loadNextResultsPage() {
        if (videoResourceId.kind === "youtube#videoCategory") {
            request.resource = "videos"
            request.params = {
                "part"            : "snippet",
                "chart"           : "mostPopular",
                "videoCategoryId" : videoResourceId.id,
            }
        } else if (videoResourceId.kind === "#channelPlaylist") {
            request.resource = "playlistItems"
            request.params = {
                "part"       : "snippet",
                "playlistId" : videoResourceId.id,
            }
        } else {
            Log.error("Unrecognized video listing types: " + videoResourceId.kind)
            return
        }

        if (nextPageToken.length > 0) {
            request.params.pageToken = nextPageToken
        }

        request.run()
    }

    function refresh() {
        videoListModel.clear()
        loadNextResultsPage()
    }
}
