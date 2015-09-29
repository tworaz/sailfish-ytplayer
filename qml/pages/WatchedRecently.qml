/*-
 * Copyright (c) 2015 Peter Tworek
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
import "../common"

Page {
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active)
            requestCoverPage("Default.qml")
    }

    Component.onCompleted: YTWatchedRecently.reload()
    Component.onDestruction: {
        // Can be null in case the application is closed
        // when the page is present on the stack.
        if (YTWatchedRecently) {
            YTWatchedRecently.clear()
        }
    }

    YTListView {
        id: listView
        anchors.fill: parent
        // Make sure adding items to list view does not steal focus
        // from SearchField in header.
        currentIndex: -1

        RemorsePopup {
            id: remorse
        }

        PullDownMenu {
            id: topPulley
            property bool changeSearchVisibility: false
            MenuItem {
                //: Menu option allowing the user to clear search history
                //% "Clear history"
                text: qsTrId("ytplayer-action-clear-history")
                visible: parent.visible
                onClicked: {
                    //: "Remorse popup message telling the user search history is about to be cleared"
                    //% "Clearing history"
                    remorse.execute(qsTrId("ytplayer-msg-clearing-history"), function() {
                        YTWatchedRecently.removeAll()
                    })
                }
            }
            MenuItem {
                text: listView.headerItem.searchVisible ?
                    //: Menu option allowing the user to hide search field
                    //% "Hide search"
                    qsTrId("ytplayer-action-hide-search") :
                    // Menu option allowing the user to show search field
                    //% "Search"
                    qsTrId("ytplayer-action-search")
                onClicked: topPulley.changeSearchVisibility = true
            }

            onActiveChanged: {
                if (!active && topPulley.changeSearchVisibility) {
                    listView.headerItem.searchVisible =
                        !listView.headerItem.searchVisible
                    topPulley.changeSearchVisibility = false
                    topPulley.close(true)
                }
            }
        }

        header: SearchHeader {
            width: parent.width
            //: Title for recently watched videos page
            //% "Watched recently"
            title: qsTrId("ytplayer-title-watched-recently")
            onSearchQueryChanged: YTWatchedRecently.search(text)
        }

        ViewPlaceholder {
            enabled: listView.count == 0
            //: Label informing the user there are no watched recently videos
            //% "No videos"
            text: qsTrId("ytplayer-label-no-videos")
        }

        model: YTWatchedRecently

        delegate: YTListItem {
            title: video_title
            duration: video_duration
            youtubeId: {
                "kind"     : "youtube#video",
                 "videoId" : video_id,
            }
            thumbnails: {
                "default": {
                    "url" : thumbnail_url,
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
