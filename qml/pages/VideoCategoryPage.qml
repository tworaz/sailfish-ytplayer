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
import "Settings.js" as Settings


Page {
    id: page

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    SilicaListView {
        id: videoCategoryListView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //: Menu option to show search page
                //% "Search"
                text: qsTrId("ytplayer-action-search")
                onClicked: pageStack.replace(Qt.resolvedUrl("SearchPage.qml"))
            }
            MenuItem {
                //: Menu option to refresh content of the list
                //% "Refresh"
                text: qsTrId("ytplayer-action-refresh")
                onClicked: videoCategoryListView.refresh()
            }
        }

        header: PageHeader {
            //: Video categories page title
            //% "Video Categories"
            title: qsTrId("ytplayer-title-video-categories")
        }

        model: ListModel {
            id: videoCategoryListModel
        }

        delegate: BackgroundItem {
            id: delegate

            Label {
                x: Theme.paddingLarge
                width: page.width;
                text: snippet.title
                anchors.verticalCenter: parent.verticalCenter
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
            }

            onClicked: {
                console.debug("Selected video category id:" + id)
                pageStack.push(Qt.resolvedUrl("VideoListPage.qml"),
                               {"videoCategoryId": id, "title" : snippet.title})
            }
        }

        function onSuccess() {
            indicator.running = false
        }

        function onFailure(reason) {
            console.log("onFailure:" + reason);
            indicator.running = false
        }

        function refresh() {
            indicator.running = true
            videoCategoryListModel.clear()
            Yt.getVideoCategories(videoCategoryListModel, onSuccess, onFailure)
        }

        Component.onCompleted: {
            console.debug("Video category list page created")
            Yt.getVideoCategories(videoCategoryListModel, onSuccess, onFailure)
            Settings.initialize();
        }

        VerticalScrollDecorator {}
    }
}
