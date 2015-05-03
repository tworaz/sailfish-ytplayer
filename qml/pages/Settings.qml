// Copyright (c) 2014-2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

Page {
    id: page
    objectName: "SettingsPage"
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active) {
            accountSwitch.checked = YTPrefs.isAuthEnabled()
            requestCoverPage("Default.qml")
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        readonly property real _h: topColumn.height + bottomColumn.height
        contentHeight: height > _h ? height : _h

        PullDownMenu {
            MenuItem {
                //: Label for menu option showing application log viewer
                //% "View logs"
                text: qsTrId("ytplayer-action-view-logs")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LogViewer.qml"))
                }
            }
        }

        Column {
            id: topColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Settings page title
                //% "Settings"
                title: qsTrId("ytplayer-title-settings")
            }

            TextSwitch {
                id: accountSwitch
                //: Label of switch activating/deactivating YouTube account integration
                //% "YouTube account integration"
                text: qsTrId("ytplayer-label-account-integration")
                //: Description of switch activating/deactivating YouTube account integration
                //% "Allow YTPlayer to manage YouTube user account."
                description: qsTrId("ytplayer-description-account-integration")
                automaticCheck: false
                checked: YTPrefs.isAuthEnabled()

                onClicked: {
                    if (YTPrefs.isAuthEnabled()) {
                        Log.info("Disabling account integration")
                        YTPrefs.disableAuth();
                        checked = false
                    } else {
                        Log.info("Enabling account integration")
                        pageStack.push(Qt.resolvedUrl("YTOAuth2.qml"))
                    }
                }
            }
        }

        Grid {
            id: bottomColumn
            width: parent.width
            columns: page.isPortrait ? 1 : 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingLarge

            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing cache settings page
                //% "Cache"
                text: qsTrId("ytplayer-action-cache-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("CacheSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing video download settings page
                //% "Download"
                text: qsTrId("ytplayer-action-download-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("DownloadSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing application language settings page
                //% "Language"
                text: qsTrId("ytplayer-action-language-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LanguageSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing video player settings page
                //% "Player"
                text: qsTrId("ytplayer-action-player-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PlayerSettings.qml"))
                }
            }
            SettingsButton {
                width: parent.width / parent.columns
                //: Label for menu option showing search settings page
                //% "Search"
                text: qsTrId("ytplayer-action-search-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SearchSettings.qml"))
                }
            }
        } // Column

        VerticalScrollDecorator {}

    } // SilicaFlickable
}
