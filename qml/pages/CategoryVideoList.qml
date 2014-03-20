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
import "../common/Helpers.js" as H


Page {
    id: page
    property alias categoryResourceId: videoListView.videoResourceId
    property string title
    property variant coverData

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!videoListView.count) {
                videoListView.refresh()
            }
            if (coverData) {
                requestCoverPage("CategoryVideoList.qml", coverData)
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: (videoListView.busy && videoListView.count === 0)
        size: BusyIndicatorSize.Large
    }

    YoutubeVideoList {
        id: videoListView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                //: Menu option to refresh content of the list
                //% "Refresh"
                text: qsTrId("ytplayer-action-refresh")
                onClicked: videoListView.refresh()
            }
        }

        PushUpMenu {
            visible: videoListView.hasNextPage
            busy: videoListView.busy
            quickSelect: true
            MenuItem {
                //: Menu option show/load additional list elements
                //% "Show more"
                text: qsTrId("ytplayer-action-show-more")
                onClicked: videoListView.loadNextResultsPage()
            }
        }

        header: PageHeader {
            title: page.title
        }

        onBusyChanged: {
            if (!busy && count > 0) {
                var _f = function(m) {
                    if (m.snippet.thumbnails.medium) {
                        return m.snippet.thumbnails.medium.url
                    } else if (m.snippet.thumbnails.high) {
                        return m.snippet.thumbnails.high.url
                    } else {
                        return m.snippet.thumbnails.default.url
                    }
                }

                var r1 = Math.floor(Math.random() * count)
                var r2 = Math.floor(Math.random() * count)
                if (r1 == r2) {
                    if (r1 == count) {
                        r2 = r1 - 1
                    } else {
                        r2 = r1 + 1
                    }
                }

                coverData = {
                    "img1" : _f(model.get(r1)),
                    "img2" : _f(model.get(r2)),
                    "title": H.getYouTubeIconForCategoryId(categoryResourceId.id) + " " + title
                }
                requestCoverPage("CategoryVideoList.qml", coverData)
            }
        }

        VerticalScrollDecorator {}
    }
}
