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
                text: qsTr("Refresh")
                onClicked: videoListView.refresh()
            }
        }

        PushUpMenu {
            MenuItem {
                //: Menu option show additional list elements
                text: qsTr("Show More")
                onClicked: console.debug("Show more elements")
            }
        }

        header: PageHeader {
            title: page.title
        }

        model: ListModel {
            id: videoListModel
        }

        delegate: BackgroundItem {
            id: delegate
            width: page.width
            height: 94

            Image {
                id: thumbnail
                width: 120
                height: 90
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                }
                fillMode: Image.PreserveAspectFit
                source: snippet.thumbnails.default.url

                BusyIndicator {
                    size: BusyIndicatorSize.Small
                    anchors.centerIn: parent
                    running: thumbnail.status == Image.Loading
                }
            }

            Label {
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                elide: Text.ElideRight
                anchors {
                    left: thumbnail.right
                    right: parent.right
                    leftMargin: Theme.paddingSmall
                    rightMargin: Theme.paddingSmall
                    verticalCenter: parent.verticalCenter
                }
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSizeSmall
                }
                text: snippet.title
            }

            onClicked: {
                console.debug("Clicked " + index + ", videoId: " + id)
                pageStack.push(Qt.resolvedUrl("VideoOverview.qml"), {"videoId": id})
            }
        }

        function onFailure(reason) {
            console.log("onFailure:" + reason);
            indicator.running = false
        }

        function onSuccess() {
            indicator.running = false
        }

        function refresh() {
            indicator.running = true
            videoListModel.clear()
            Yt.getVideosInCategory(page.videoCategoryId, videoListModel, onSuccess, onFailure)
        }

        Component.onCompleted: {
            console.debug("Video list page created")
            Yt.getVideosInCategory(page.videoCategoryId, videoListModel, onSuccess, onFailure)
        }

        VerticalScrollDecorator {}
    }
}
