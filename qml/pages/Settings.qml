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
    id: settingsPage
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active) {
            accountSwitch.checked = Prefs.isAuthEnabled()
            requestCoverPage("Default.qml")
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                //% "View Logs"
                text: qsTrId("ytplayer-title-show-logs")
                onClicked: pageStack.push(Qt.resolvedUrl("LogViewer.qml"))
            }
        }

        Column {
            id: column
            x: Theme.paddingLarge
            width: parent.width - 2 * Theme.paddingLarge
            spacing: Theme.paddingMedium

            PageHeader {
                //: Settings page title
                //% "Settings"
                title: qsTrId("ytplayer-title-settings")
            }

            Label {
                //: Account settings section label
                //% "Account"
                text: qsTrId("ytplayer-label-account")
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            TextSwitch {
                id: accountSwitch
                //: Label of switch activating/deactivating YouTube account integration
                //% "YouTube account integration"
                text: qsTrId("ytplayer-account-integration-label")
                //: Description of switch activating/deactivating YouTube account integration
                //% "Allow YTPlayer to manage YouTube user account"
                description: qsTrId("ytplayer-account-integration-description")
                automaticCheck: false

                onClicked: {
                    if (Prefs.isAuthEnabled()) {
                        Log.info("Disabling account integration")
                        Prefs.disableAuth();
                        checked = false
                    } else {
                        Log.info("Enabling account integration")
                        pageStack.push(Qt.resolvedUrl("YTOAuth2.qml"))
                    }
                }
            }

            // XXX: Enable search hints
            //Label {
            //    //: Search settings section label
            //    //% "Search"
            //    text: qsTrId("ytplayer-label-search")
            //    width: parent.width
            //    color: Theme.highlightColor
            //    horizontalAlignment: Text.AlignRight
            //}
        }
    }
}
