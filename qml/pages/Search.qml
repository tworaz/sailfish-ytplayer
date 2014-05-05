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

Page {
    id: page

    property string nextPageToken: ""

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: false
        size: BusyIndicatorSize.Large
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
            topMenu.accountMenuVisible = Prefs.isAuthEnabled()
        }
    }

    function _getSafeSearchValue() {
        switch(parseInt(Prefs.get("SafeSearch"))) {
        case 0: return "none"
        case 1: return "moderate"
        case 2: return "strict"
        }
    }

    function performSearch(queryStr, pageToken) {
        var params = {
            "q"          : queryStr,
            "part"       : "snippet",
            "type"       : "video,channel",
            "safeSearch" : _getSafeSearchValue(),
        }
        if (pageToken) {
            params.pageToken = pageToken
        }

        ytDataAPIClient.list("search", params, function (response) {
            console.assert(response.kind === "youtube#searchListResponse")
            utilityWorkerScript.appendToModel(resultsListModel, response.items, function() {
                if (response.hasOwnProperty("nextPageToken")) {
                    page.nextPageToken = response.nextPageToken
                }
                indicator.running = false
                bottomMenu.busy = false
            })
        }, function (error) {
            Log.error("Error: " + JSON.stringify(error, undefined, 2))
            page.nextPageToken = ""
            indicator.running = false
        })
        indicator.running = true
    }

    SilicaListView {
        id: searchView
        anchors.fill: parent

        YTPagesTopMenu {
            id: topMenu
            searchMenuVisible: false
        }

        PushUpMenu {
            id: bottomMenu
            visible: page.nextPageToken.length > 0
            quickSelect: true
            MenuItem {
                //: Menu option load additional list elements
                //% "Show more"
                text: qsTrId("ytplayer-action-show-more")
                onClicked: searchView.loadNextResultsPage()
            }
        }

        header: SearchField {
            width: parent.width
            //: Label of video search text field
            //% "Search"
            placeholderText: qsTrId("ytplayer-label-search")
            onTextChanged: {
                searchView.currentIndex = -1
                searchHandler.search(text)
            }
        }

        Label {
            anchors.centerIn: parent
            color: Theme.secondaryHighlightColor
            visible: resultsListModel.count === 0 && !indicator.running
            //: Background label informing the user there are no search results
            //% "No results"
            text: qsTrId("ytplayer-search-no-results")
        }

        Timer {
            id: searchHandler
            interval: 1000
            repeat: false

            property string queryStr

            function search(str) {
                queryStr = str
                if (str.length) {
                    restart()
                } else {
                    stop()
                    resultsListModel.clear()
                    page.nextPageToken = ""
                }
            }

            onTriggered: {
                Log.debug("Searching for: " + queryStr)
                resultsListModel.clear()
                page.nextPageToken = ""
                performSearch(queryStr)
                indicator.running = true
            }
        }

        model: ListModel {
            id: resultsListModel
        }

        delegate: YTListItem {
            width: parent.width
            title: snippet.title
            thumbnails: snippet.thumbnails
            youtubeId: id
        }

        onMovementStarted: {
            if (count > 0) {
                currentIndex = 0
                currentItem.forceActiveFocus()
            }
        }

        onContentYChanged: {
            if (contentY === -searchView.headerItem.height && !pageStack.busy) {
                currentIndex = -1
                searchView.headerItem.forceActiveFocus()
            }
        }

        function loadNextResultsPage() {
            Log.debug("Loading next page of results, token: " + page.nextPageToken)
            performSearch(searchHandler.queryStr, page.nextPageToken)
            bottomMenu.busy = true
        }

        Component.onCompleted: {
            Log.debug("YouTube search page created")
            searchView.headerItem.forceActiveFocus()
        }

        VerticalScrollDecorator {}
    }
}
