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
            MenuItem {
                //: Menu option to clear application caches
                //% "Clear cache"
                text: qsTrId("ytplayer-label-clear-cache")
                onClicked: networkManager.clearCache()
            }
        }

        Column {
            id: column
            x: Theme.paddingLarge
            width: parent.width - 2 * x
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

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignRight
                    //: "Label for cache section in settings page"
                    //% "Cache"
                    text: qsTrId("ytplayer-label-cache")
                }
                Slider {
                    //: "Label for image cache size slider"
                    //% "Image cache size"
                    label: qsTrId("ytplayer-label-image-cache-size")
                    width: parent.width
                    minimumValue: 1
                    maximumValue: 30
                    stepSize: 1
                    valueText: value + " MB"
                    Component.onCompleted: {
                        value = networkManager.imageCacheMaxSize
                    }
                    onReleased: {
                        networkManager.imageCacheMaxSize = value
                    }
                }
                KeyValueLabel {
                    //: "Label for current cache usage label"
                    //% "Current usage"
                    key: qsTrId("ytplayer-label-current-usage")
                    width: parent.width
                    value: networkManager.imageCacheUsage + " kB"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                }
                Slider {
                    //: "Label for YouTube API response cache size slider"
                    //% "YouTube API response cache size"
                    label: qsTrId("ytplayer-label-api-req-cache-size")
                    width: parent.width
                    minimumValue: 1
                    maximumValue: 10
                    stepSize: 1
                    valueText: value + " MB"
                    Component.onCompleted: {
                        value = networkManager.apiResponseCacheMaxSize
                    }
                    onReleased: {
                        networkManager.apiResponseCacheMaxSize = value
                    }
                }
                KeyValueLabel {
                    //: "Label for current cache usage label"
                    //% "Current usage"
                    key: qsTrId("ytplayer-label-current-usage")
                    width: parent.width
                    value: networkManager.apiResponseCacheUsage + " kB"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
