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
    objectName: "CacheSettingsPage"
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active)
            requestCoverPage("Default.qml")
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height > column.height ? height: column.height

        PullDownMenu {
            MenuItem {
                //: "Menu option to clear application caches"
                //% "Clear cache"
                text: qsTrId("ytplayer-label-clear-cache")
                onClicked: {
                    //: "Remorse popup message telling the user the cache will be cleaned"
                    //% "Clear cache"
                    remorse.execute(qsTrId("ytplayer-msg-clearing-cache"), function() {
                        gNetworkManager.clearCache()
                    })
                }
            }
        }

        RemorsePopup {
            id: remorse
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: "Title of cache settings page"
                //% "Cache settings"
                title: qsTrId("ytplayer-title-cache-settings")
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
                    value = gNetworkManager.imageCacheMaxSize
                }
                onReleased: {
                    gNetworkManager.imageCacheMaxSize = value
                }
            }
            KeyValueLabel {
                //: "Label for current cache usage label"
                //% "Current usage"
                key: qsTrId("ytplayer-label-current-usage")
                width: parent.width
                value: gNetworkManager.imageCacheUsage + " kB"
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
                    value = gNetworkManager.apiResponseCacheMaxSize
                }
                onReleased: {
                    gNetworkManager.apiResponseCacheMaxSize = value
                }
            }
            KeyValueLabel {
                //: "Label for current cache usage label"
                //% "Current usage"
                key: qsTrId("ytplayer-label-current-usage")
                width: parent.width
                value: gNetworkManager.apiResponseCacheUsage + " kB"
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
            }
        } // Column

        VerticalScrollDecorator {}

    } // SilicaFlickable
}
