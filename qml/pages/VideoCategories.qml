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

    FontLoader {
        id: youtubeIconsLoader
        source: "https://www.youtube.com/s/tv/fonts/youtube-icons.ttf"
        onStatusChanged: {
            if (status === FontLoader.Ready) {
                console.debug("YouTube icons loaded, loading categories")
                videoCategoryListView.refresh()
            } else if (status === FontLoader.Error) {
                console.warn("Failed to load youtube category icons")
                videoCategoryListView.refresh()
            }
        }
    }

    SilicaListView {
        id: videoCategoryListView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                //: Menu option to show search page
                //% "Search"
                text: qsTrId("ytplayer-action-search")
                onClicked: pageStack.replace(Qt.resolvedUrl("Search.qml"))
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

            Row {
                x: Theme.paddingMedium
                width: page.width;
                spacing: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    width: 60
                    font.family: "youtube-icons"
                    font.pixelSize: Theme.fontSizeLarge
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: getIconForCategoryId(id)
                    visible: youtubeIconsLoader.status === FontLoader.Ready

                    function getIconForCategoryId(category)
                    {
                        var categoryId = parseInt(category);
                        switch (categoryId) {
                        case 1:  return "\ue64d"  // Film & Animation
                        case 2:  return "\ue650"  // Autos & Vechicles
                        case 10: return "\ue636"  // Music
                        case 15: return "\ue633"  // Pets & Animals
                        case 17: return "\ue60d"  // Sports
                        case 19: return "\ue641"  // Travel & Events
                        case 20: return "\ue64f"  // Gaming
                        case 22: return "\ue634"  // People & Blogs
                        case 23: return "\ue638"  // Commedy
                        case 24: return "\ue64c"  // Entertainment
                        case 25: return "\ue634"  // News & Politics
                        case 26: return "\ue639"  // Howto & Style
                        case 27: return "\ue64b"  // Education
                        case 28: return "\ue610"  // Science & Technology
                        case 29: return "\ue64e"  // Nonprofits & Activism
                        default:
                            console.debug("No icon for category: " + category)
                            return "\ue60c"
                        }
                    }
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
                console.debug("Selected video category id:" + id)
                pageStack.push(Qt.resolvedUrl("VideoList.qml"),
                               {"videoCategoryId": id, "title" : snippet.title})
            }
        }

        ConnectionRetryTimer {
            id: connectionRetryTimer
            onTriggered: {
                Yt.getVideoCategories(videoCategoryListView.onSuccess, onRetryFailure)
            }
        }

        function onSuccess(categories) {
            for (var i = 0; i < categories.length; i++) {
                var category = categories[i];
                if (category.snippet.assignable) {
                    videoCategoryListModel.append(category);
                }
            }
            indicator.running = false
        }

        function onFailure(error) {
            if (error.code === 0) {
                connectionRetryTimer.reset();
                connectionRetryTimer.start();
            } else {
                errorNotification.show(error);
                indicator.running = false
            }
        }

        function refresh() {
            indicator.running = true
            videoCategoryListModel.clear()
            Yt.getVideoCategories(onSuccess, onFailure)
        }

        Component.onCompleted: {
            console.debug("Video category list page created")
            if (youtubeIconsLoader.status === FontLoader.Ready) {
                console.debug("Youtube icons already loaded, loading categories")
                Yt.getVideoCategories(onSuccess, onFailure)
            }
            Settings.initialize();
        }

        VerticalScrollDecorator {}
    }
}
