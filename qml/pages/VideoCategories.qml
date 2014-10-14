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
import "../common/Helpers.js" as H

Page {
    id: page
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        Log.info("Video categories list page created")
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (videoCategoriesModel.count === 0) {
                request.run()
            }
            requestCoverPage("Default.qml")
        }
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: request.busy
    }

    YTRequest {
        id: request
        method: YTRequest.List
        resource: "videoCategories"
        params: { "part" : "snippet" }
        model: videoCategoriesModel
    }

    SilicaListView {
        id: videoCategoryListView
        anchors.fill: parent

        header: PageHeader {
            //: Video categories page title
            //% "Video Categories"
            title: qsTrId("ytplayer-title-video-categories")
        }

        model: YTListModel {
            id: videoCategoriesModel
            filter.key: "snippet.assignable"
            filter.value: true
        }

        delegate: BackgroundItem {
            id: delegate

            Row {
                x: Theme.paddingMedium
                width: page.width
                spacing: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    width: 60
                    font.family: youtubeIconsFontName
                    font.pixelSize: Theme.fontSizeLarge
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: H.getYouTubeIconForCategoryId(id)
                }

                Label {
                    text: snippet.title
                    anchors.verticalCenter: parent.verticalCenter
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font {
                        pixelSize: Theme.fontSizeLarge
                        family: Theme.fontFamilyHeading
                    }
                }
            }

            onClicked: {
                Log.debug("Selected video category id:" + id)
                var listingType = { "kind" : kind, "id" : id }
                pageStack.push(Qt.resolvedUrl("CategoryVideoList.qml"), {
                    "categoryResourceId" : listingType,
                    "title"              : snippet.title
                })
            }
        }

        VerticalScrollDecorator {}
    }
}
