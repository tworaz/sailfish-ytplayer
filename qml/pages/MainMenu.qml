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
    objectName: "MainMenu"
    allowedOrientations: Orientation.All

    Component.onCompleted: {
        priv.showAccount = Prefs.isAuthEnabled()
        checkClipboard()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        } else if (status === PageStatus.Activating) {
            priv.showAccount = Prefs.isAuthEnabled()
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
            visible: priv.clipboardVideoId.length > 0
            MenuItem {
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
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: "YTPlayer"
            }

            MainMenuItem {
                id: search
                //: Menu option to show search page
                //% "Search"
                text: qsTrId("ytplayer-action-search")
                icon: "qrc:///icons/search-m.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Search.qml"))
            }
            MainMenuItem {
                id: videoCategories
                //: Menu option to show video categories page
                //% "Video categories"
                text: qsTrId("ytplayer-action-video-categories")
                icon: "qrc:///icons/video-multi-m.png"
                onClicked: pageStack.push(Qt.resolvedUrl("VideoCategories.qml"))
            }
            MainMenuItem {
                //: Menu option showing downloaded videos page
                //% "Downloaded videos"
                text: qsTrId("ytplayer-action-downloaded-videos")
                icon: "qrc:///icons/downloaded-videos-64.png"
                onClicked: pageStack.push(Qt.resolvedUrl("DownloadedVideos.qml"))
            }

            Label {
                //: Label for YouTube account related options in main menu
                //% "Account"
                text: qsTrId("ytplayer-label-account")
                visible: priv.showAccount
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                horizontalAlignment: Text.AlignRight
                color: Theme.highlightColor
            }
            MainMenuItem {
                id: recommended
                //: Menu option fo show YouTube recommendations page
                //% "Recommended for you"
                text: qsTrId("ytplayer-action-recommended")
                visible: priv.showAccount
                icon: "qrc:///icons/approval-64.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "RECOMMENDED" })
            }
            MainMenuItem {
                id: subscriptions
                //: Menu option responsible for showing user subscriptions page
                //% "Subscriptions"
                text: qsTrId("ytplayer-action-subscriptions")
                visible: priv.showAccount
                icon: "qrc:///icons/rss-m.png"
                submenu: Component {
                    ContextMenu {
                        MenuItem {
                            //: Sub-Menu option responsible for showing latest subsribed videos page
                            //% "Latest videos"
                            text: qsTrId("ytplayer-action-latest-subscribed-videos")
                            onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                { "state" : "SUBSCRIPTION_VIDEOS" })
                        }
                        MenuItem {
                            //: Sub-Menu option responsible for showing user subscribed channels
                            //% "Channels"
                            text: qsTrId("ytplayer-action-subscribed-channels")
                            onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                { "state" : "SUBSCRIPTION_CHANNELS" })

                        }
                    }
                }
            }
            MainMenuItem {
                id: likes
                //: Menu option responsible for showing user likes page
                //% "Likes"
                text: qsTrId("ytplayer-action-likes")
                visible: priv.showAccount
                icon: "qrc:///icons/like-m.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "LIKES" })
            }
            MainMenuItem {
                id: dislikes
                //: Menu option responsible for showing user dislikes page
                //% "Dislikes"
                text: qsTrId("ytplayer-action-dislikes")
                visible: priv.showAccount
                icon: "qrc:///icons/dislike-m.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Account.qml"),
                                              { "state" : "DISLIKES" })
            }

            Label {
                //: Label for misc items in main application menu
                //% "Other"
                text: qsTrId("ytplayer-action-other")
                x: Theme.paddingLarge
                width: parent.width - 2 * Theme.paddingLarge
                horizontalAlignment: Text.AlignRight
                color: Theme.highlightColor
            }
            MainMenuItem {
                //: Menu option to show settings page
                //% "Settings"
                text: qsTrId("ytplayer-action-settings")
                icon: "qrc:///icons/settings-64.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MainMenuItem {
                //: Menu option to show about page
                //% "About"
                text: qsTrId("ytplayer-action-about")
                icon: "qrc:///icons/info-64.png"
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
        }
        VerticalScrollDecorator {}
    }
}
