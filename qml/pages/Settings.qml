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
import "../common"

Page {
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
            //x: Theme.paddingLarge
            //width: parent.width - 2 * x
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

        Column {
            id: bottomColumn
            width: parent.width
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingLarge

            SettingsButton {
                //: Label for menu option showing cache settings page
                //% "Cache"
                text: qsTrId("ytplayer-action-cache-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("CacheSettings.qml"))
                }
            }
            SettingsButton {
                //: Label for menu option showing video download settings page
                //% "Download"
                text: qsTrId("ytplayer-action-download-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("DownloadSettings.qml"))
                }
            }
            SettingsButton {
                //: Label for menu option showing application language settings page
                //% "Language"
                text: qsTrId("ytplayer-action-language-settings")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("LanguageSettings.qml"))
                }
            }
            SettingsButton {
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
