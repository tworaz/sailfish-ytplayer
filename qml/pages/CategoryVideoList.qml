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
import "../common/Helpers.js" as H

Page {
    id: page
    allowedOrientations: Orientation.All

    property alias categoryResourceId: videoListView.videoResourceId
    property string title
    property variant savedCoverData

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!videoListView.count) {
                videoListView.refresh()
            }
            if (savedCoverData) {
                requestCoverPage("CategoryVideoList.qml", savedCoverData)
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: (videoListView.busy && videoListView.count === 0)
        size: BusyIndicatorSize.Large
    }

    YTVideoList {
        id: videoListView
        anchors.fill: parent

        PullDownMenu {
            visible: videoListView.busy
            busy: true
        }

        PushUpMenu {
            visible: videoListView.busy
            busy: true
        }

        header: PageHeader {
            title: page.title
        }

        onCountChanged: {
            if (count > 0 && !savedCoverData) {
                Log.info("Category videos loaded, building cover page")
                var data = {
                    "images" : [],
                    "title":  H.getYouTubeIconForCategoryId(categoryResourceId.id) + " " + title,
                };

                var start = Math.floor(Math.random() * count)
                for (var i = 0; i < kMaxCoverThumbnailCount; ++i) {
                    data.images.push(model.get((start + i) % count).snippet.thumbnails)
                }
                requestCoverPage("CategoryVideoList.qml", data)
                savedCoverData = data
            }
        }

        VerticalScrollDecorator {}
    }
}
