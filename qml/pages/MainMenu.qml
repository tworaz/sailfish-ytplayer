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

    property alias searchActive: search.active
    property alias videoCategoriesActive: videoCategories.active
    property alias subscriptionsActive: subscriptions.active
    property alias likesActive: likes.active
    property alias dislikesActive: dislikes.active
    property alias recommendedActive: recommended.active
    property bool subscriptionVideosActive: false
    property bool subscriptionChannelsActive: false

    Component.onCompleted: {
        priv.showAccount = Prefs.isAuthEnabled()
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
        property bool showAccount: false
    }

    SilicaFlickable {
        anchors.fill: parent

        PageHeader {
            id: header
            title: "YTPlayer"
        }
        Column {
            id: column
            anchors.top: header.bottom
            width: parent.width
            spacing: Theme.paddingMedium

            function handleClick(active, page, params) {
                if (active) {
                    Log.debug("Active menu option selected, going back to " + page)
                    pageStack.navigateBack()
                } else {
                    Log.debug("New page selected, opening: " + page)
                    pageStack.replaceAbove(null, Qt.resolvedUrl(page), params)
                }
            }

            MainMenuItem {
                id: search
                //: Menu option to show search page
                //% "Search"
                text: qsTrId("ytplayer-action-search")
                icon: "qrc:///icons/search-m.png"
                onClicked: parent.handleClick(active, "Search.qml")
            }
            MainMenuItem {
                id: videoCategories
                //: Menu option to show video categories page
                //% "Video Categories"
                text: qsTrId("ytplayer-action-video-categories")
                icon: "qrc:///icons/video-multi-m.png"
                onClicked: parent.handleClick(active, "VideoCategories.qml")
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
                icon: "qrc:///icons/star-m.png"
                onClicked: parent.handleClick(active, "Account.qml",
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
                            onClicked: column.handleClick(page.subscriptionVideosActive,
                                "Account.qml", { "state" : "SUBSCRIPTION_VIDEOS" })
                        }
                        MenuItem {
                            //: Sub-Menu option responsible for showing user subscribed channels
                            //% "Channels"
                            text: qsTrId("ytplayer-action-subscribed-channels")
                            onClicked: column.handleClick(page.subscriptionChannelsActive,
                                "Account.qml", { "state" : "SUBSCRIPTION_CHANNELS" })

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
                onClicked: parent.handleClick(active, "Account.qml",
                                              { "state" : "LIKES" })
            }
            MainMenuItem {
                id: dislikes
                //: Menu option responsible for showing user dislikes page
                //% "Dislikes"
                text: qsTrId("ytplayer-action-dislikes")
                visible: priv.showAccount
                icon: "qrc:///icons/dislike-m.png"
                onClicked: parent.handleClick(active, "Account.qml",
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
                icon: "qrc:///icons/settings-m.png"
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }
            MainMenuItem {
                //: Menu option to show about page
                //% "About"
                text: qsTrId("ytplayer-action-about")
                icon: "qrc:///icons/about.png"
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
        }
    }
}
