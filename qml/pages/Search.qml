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

Page {
    id: page
    allowedOrientations: Orientation.All

    QtObject {
        id: priv
        property Item optionsPage
        property string nextPageToken: ""
        property variant searchParams: ({})
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
            if (!priv.optionsPage) {
                priv.optionsPage = pageStack.pushAttached(
                    Qt.resolvedUrl("SearchOptions.qml"))
            }
            updateSearchParams()
        }
    }

    function updateSearchParams() {
        console.assert(priv.optionsPage !== undefined)
        console.assert(priv.optionsPage.hasOwnProperty("currentSettings"))
        console.assert(priv.optionsPage.hasOwnProperty("changed"))

        if (!priv.optionsPage.changed)
            return

        var s = priv.optionsPage.currentSettings
        var params = {
            "part" : "snippet",
        }
        for (var prop in s) {
            params[prop] = s[prop]
        }
        priv.searchParams = params
        priv.optionsPage.changed = false
        Log.debug("Search params updated: " + JSON.stringify(params, undefined, 2))

        if (searchHandler.queryStr.length > 0) {
            searchHandler.onTriggered()
        }
    }

    function performSearch(queryStr, pageToken) {
        var params = priv.searchParams
        params.q = queryStr
        if (pageToken) {
            params.pageToken = pageToken
        }
        request.params = params
        request.run()
    }

    YTRequest {
        id: request
        method: YTRequest.List
        resource: "search"
        model: resultsListModel

        onSuccess: {
            console.assert(response.kind === "youtube#searchListResponse")
            if (response.hasOwnProperty("nextPageToken")) {
                priv.nextPageToken = response.nextPageToken
            }
        }
    }

    SilicaListView {
        id: searchView
        anchors.fill: parent

        PullDownMenu {
            visible: request.busy
            busy: true
        }

        PushUpMenu {
            visible: request.busy
            busy: true
        }

        header: Item {
            width: page.width
            height: options.height + searchField.height

            function focusSearchField() {
                searchField.forceActiveFocus()
            }

            HeaderButton {
                id: options
                anchors.right: parent.right
                icon: "qrc:///icons/advanced-48.png"
                //: Generic options menu/button label
                //% "Advanced"
                text: qsTrId("ytplayer-label-advanced")
                onClicked: {
                    pageStack.navigateForward(PageStackAction.Animated)
                }
            }
            SearchField {
                id: searchField
                anchors.top: options.bottom
                width: parent.width
                //: Label of video search text field
                //% "Search"
                placeholderText: qsTrId("ytplayer-label-search")
                onTextChanged: {
                    searchView.currentIndex = -1
                    searchHandler.search(text)
                }
            }
        }

        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height - parent.headerItem.height / 2

            Label {
                anchors.centerIn: parent
                color: Theme.secondaryHighlightColor
                visible: resultsListModel.count === 0 && !indicator.running
                //: Background label informing the user there are no search results
                //% "No results"
                text: qsTrId("ytplayer-search-no-results")
            }

            BusyIndicator {
                id: indicator
                anchors.centerIn: parent
                running: request.busy && resultsListModel.count === 0
                size: BusyIndicatorSize.Large
            }
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
                    priv.nextPageToken = ""
                }
            }

            onTriggered: {
                Log.debug("Searching for: " + queryStr)
                resultsListModel.clear()
                priv.nextPageToken = ""
                performSearch(queryStr)
            }
        }

        model: YTListModel {
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
                if (currentItem) {
                    currentItem.forceActiveFocus()
                }
            }
        }

        onAtYBeginningChanged: {
            if (atYBeginning && !pageStack.busy) {
                currentIndex = -1
                if (searchView.headerItem) {
                    searchView.headerItem.focusSearchField()
                }
            }
        }

        onAtYEndChanged: {
            if (atYEnd && priv.nextPageToken.length > 0 && !request.busy) {
                loadNextResultsPage()
            }
        }

        function loadNextResultsPage() {
            Log.debug("Loading next page of results, token: " + priv.nextPageToken)
            performSearch(searchHandler.queryStr, priv.nextPageToken)
        }

        Component.onCompleted: {
            Log.debug("YouTube search page created")
            searchView.headerItem.focusSearchField()
        }

        VerticalScrollDecorator {}
    }
}
