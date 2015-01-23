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

    QtObject {
        id: priv
        property Item optionsPage
        property string nextPageToken: ""
        property variant searchParams: ({})
        property bool ignoreNextAtYBeginning: false
        property real autoLoadThreshold: 0.8
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
            if (!priv.optionsPage) {
                priv.optionsPage = pageStack.pushAttached(
                    Qt.resolvedUrl("SearchOptions.qml"))
            }
            updateSearchParams()
            // Only auto focus search field if the list is not scrolled
            if (searchView.headerItem.height + searchView.contentY === 0)
                focusSearchField()
        }
    }

    Component.onCompleted: {
        Log.info("YouTube search page created")
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
        for (var prop in s)
            params[prop] = s[prop]
        priv.searchParams = params
        priv.optionsPage.changed = false
        Log.debug("Search params updated: " + JSON.stringify(params, undefined, 2))

        if (searchView.headerItem.queryText.length > 0)
            performSearch(searchView.headerItem.queryText)
    }

    function performSearch(queryStr, pageToken) {
        var params = priv.searchParams
        params.q = queryStr
        if (pageToken) {
            params.pageToken = pageToken
        } else {
            clearSearch()
        }

        request.params = params

        suggestions.clear()

        request.run()
        suggestions.addToSearchHistory(queryStr)
    }

    function clearSearch() {
        priv.nextPageToken = ""
        resultsListModel.clear()
    }

    function focusSearchField() {
        if (page.status === PageStatus.Active &&
            searchView.headerItem)
            searchView.headerItem.focusSearchField();
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
            } else {
                priv.nextPageToken = ""
            }

            // Make sure keyboard is not shown
            priv.ignoreNextAtYBeginning = true
            priv.autoLoadThreshold =
                1.0 - (kListAutoLoadItemThreshold / resultsListModel.count)
        }
    }

    SearchSuggestions {
        id: suggestions
        anchors.bottom: parent.bottom
        width: parent.width
        height: page.height - searchView.headerItem.height
        visible: hasResults && resultsListModel.count === 0 &&
                 !request.busy
        z: searchView.z + 10
        isPortrait: page.isPortrait

        onSelected: {
            searchView.headerItem.changeSearchText(suggestion)
            performSearch(suggestion)
        }
    }

    SilicaListView {
        id: searchView
        anchors.fill: parent

        header: Item {
            width: page.width
            height: options.height + searchField.height

            property alias queryText: searchField.text
            property alias searchFieldHeight: searchField.height

            function focusSearchField() {
                searchField.forceActiveFocus()
            }

            function changeSearchText(txt) {
                searchField._ignoreTextChange = true
                searchField.text = txt
                searchField._ignoreTextChange = false
            }

            HeaderButton {
                id: options
                anchors.right: parent.right
                isPortrait: page.isPortrait
                visible: !!priv.optionsPage
                //: Generic options menu/button label
                //% "Advanced"
                text: qsTrId("ytplayer-label-advanced")
                onClicked: {
                    pageStack.navigateForward(PageStackAction.Animated)
                }
            }
            SearchField {
                id: searchField
                property bool _ignoreTextChange: false
                anchors.top: options.bottom
                width: parent.width
                //: Label of video search text field
                //% "Search"
                placeholderText: qsTrId("ytplayer-label-search")
                onTextChanged: {
                    if (_ignoreTextChange)
                        return;

                    clearSearch()
                    if (text.length > 0) {
                        suggestions.query = text
                    } else {
                        suggestions.clear()
                    }
                }
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: performSearch(text)
            }
        }

        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height - parent.headerItem.searchFieldHeight

            Label {
                anchors.centerIn: parent
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
                visible: resultsListModel.count === 0 &&
                         !suggestions.hasResults &&
                         !indicator.running &&
                         (searchView.height - searchView.headerItem.height > height)

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

        model: YTListModel {
            id: resultsListModel
        }

        delegate: YTListItem {
            width: parent.width
            title: snippet.title
            thumbnails: snippet.thumbnails
            youtubeId: id
            onPressed: forceActiveFocus()
        }

        onAtYBeginningChanged: {
            if (priv.ignoreNextAtYBeginning) {
                priv.ignoreNextAtYBeginning = false
                return
            }

            if (atYBeginning && !pageStack.busy) {
                currentIndex = -1
                focusSearchField()
            } else if (!atYBeginning && resultsListModel.count > 0 &&
                       page.isPortrait) {
                // XXX: In landscape mode when scrolling the view atYBeginning
                //      often changes first to true than to false. If SW keyboard
                //      is shown focusing 1st item on the list will scroll the view.
                currentIndex = 1
                currentItem.forceActiveFocus()
            }
        }

        onContentYChanged: {
            var curY = searchView.height + contentY + headerItem.height
            if ((curY >= priv.autoLoadThreshold * contentHeight) &&
                 !request.busy && priv.nextPageToken.length > 0) {
                Log.debug("Loading next page of results, token: " + priv.nextPageToken)
                performSearch(searchView.headerItem.queryText, priv.nextPageToken)
            }
        }

        VerticalScrollDecorator {}
    } // SilicaListView
}
