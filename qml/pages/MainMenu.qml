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
    objectName: "MainMenu"
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        priv.showAccount = YTPrefs.isAuthEnabled()
        checkClipboard()
        if (priv.showAccount)
            request.run()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        } else if (status === PageStatus.Activating) {
            priv.showAccount = YTPrefs.isAuthEnabled()
            if (priv.showAccount && !request.loaded && !request.busy) {
                request.run()
            } else if (!priv.showAccount && channelsModel.count > 0) {
                channelsModel.clear();
                kUserChannelIds = []
                request.reset();
            }

        }
    }

    QtObject {
        id: priv
        property string clipboardVideoId: ""
        property bool showAccount: false
    }

    Connections {
        target: Clipboard
        onHasTextChanged: checkClipboard()
    }

    function checkClipboard() {
        if (!Clipboard.hasText) {
            priv.clipboardVideoId = ""
            return
        }
        Log.debug("Clipboard has text: " + Clipboard.text)
        var r = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/
        var result = Clipboard.text.match(r);
        priv.clipboardVideoId = result ? result[1] : ""
        if (priv.clipboardVideoId.length > 0)
            Log.info("Clipboard contains a link for video: " + priv.clipboardVideoId)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            busy: request.busy

            MenuItem {
                //: Menu option to show about page
                //% "About"
                text: qsTrId("ytplayer-action-about")
                //icon: "qrc:///icons/info-64"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
            MenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MenuItem {
                visible: priv.clipboardVideoId.length > 0
                //: Menu opion for opening video links from clipboard
                //% "Open link from clipboard"
                text: qsTrId("ytplayer-action-open-link-from-clipboard")
                onClicked: {
                    console.assert(priv.clipboardVideoId.length > 0)
                    Log.info("Opening clipboard link for videoId: " + priv.clipboardVideoId)
                    pageStack.push(Qt.resolvedUrl("VideoOverview.qml"), {
                        "videoId" : priv.clipboardVideoId
                    })
                }
            }
            MenuItem {
                //: Menu option to show search page
                //% "Search"
                text: qsTrId("ytplayer-action-search")
                onClicked: pageStack.push(Qt.resolvedUrl("Search.qml"))
            }
        }

        Column {
            id: column
            width: parent.width

            MainMenuSectionHeader {
                visible: priv.showAccount
                anchors.rightMargin: Theme.paddingLarge
                anchors.right: parent.right
                //: Label for channels section indicator in main menu
                //% "Channels"
                text: qsTrId("ytplayer-label-channels")
            }

            MainMenuItem {
                visible: priv.showAccount
                //: Menu option responsible for showing user subscriptions page
                //% "Subscriptions"
                text: qsTrId("ytplayer-action-subscriptions")
                icon: "qrc:///icons/rss-m"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                    { "state" : "SUBSCRIPTION_CHANNELS" })
            }

            YTRequest {
                id: request
                method: YTRequest.List
                resource: "channels"
                model: channelsModel
                params: {
                    "part" : "id,snippet",
                    "mine" : true,
                }
            }

            Repeater {
                model: YTListModel {
                    id: channelsModel
                }
                delegate: MainMenuItem {
                    id: userChannelItem
                    visible: priv.showAccount
                    text: snippet.title
                    icon: snippet.thumbnails.default.url
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("ChannelBrowser.qml"),
                            { "channelId" : id, "title" : text })
                    }
                    Component.onCompleted: kUserChannelIds.push(id)

                    ParallelAnimation {
                        running: true
                        NumberAnimation {
                            //target: userChannelScale
                            target: userChannelItem
                            properties: "scale"
                            //property: "yScale"
                            to: 1.0
                            duration: kStandardAnimationDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: userChannelItem
                            property: "height"
                            from: 0
                            to: userChannelItem.implicitHeight
                            duration: kStandardAnimationDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: userChannelItem
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: kStandardAnimationDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                } // MainMenuItem
            } // Repeater

            MainMenuSectionHeader {
                anchors.rightMargin: Theme.paddingLarge
                anchors.right: parent.right
                //: Main menu label indicating videos section of the page
                //% "Videos"
                text: qsTrId("ytplayer-label-videos")
            }

            MainMenuItem {
                //: Menu option showing video favorites page
                //% "Favorites"
                text: qsTrId("ytplayer-acton-favorites")
                icon: "qrc:///icons/star-8-64"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("Favorites.qml"))
            }
            MainMenuItem {
                //: Menu option to show video categories page
                //% "Categories"
                text: qsTrId("ytplayer-action-video-categories")
                icon: "qrc:///icons/categorize-64"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("VideoCategories.qml"))
            }
            MainMenuItem {
                //: Menu option showing downloaded videos page
                //% "Downloads"
                text: qsTrId("ytplayer-action-downloaded-videos")
                icon: "qrc:///icons/downloaded-videos-64"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("DownloadedVideos.qml"))
            }
            MainMenuItem {
                //: Menu option fo show YouTube recommendations page
                //% "Recommendations"
                text: qsTrId("ytplayer-action-recommended")
                visible: priv.showAccount
                icon: "qrc:///icons/approval-64"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "RECOMMENDED" })
            }
            MainMenuItem {
                //: Menu opion showing recently watched videos page
                //% "Watched recently"
                text: qsTrId("ytplayer-action-watched-recently")
                icon: "qrc:///icons/video-multi-m"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("WatchedRecently.qml"))
            }
            MainMenuItem {
                //: Menu option responsible for showing user likes page
                //% "Likes"
                text: qsTrId("ytplayer-action-likes")
                visible: priv.showAccount
                icon: "qrc:///icons/like-m"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "LIKES" })
            }
            MainMenuItem {
                //: Menu option responsible for showing user dislikes page
                //% "Dislikes"
                text: qsTrId("ytplayer-action-dislikes")
                visible: priv.showAccount
                icon: "qrc:///icons/dislike-m"+iconColor+".png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "DISLIKES" })
            }
        }

        VerticalScrollDecorator {}
    }
}
