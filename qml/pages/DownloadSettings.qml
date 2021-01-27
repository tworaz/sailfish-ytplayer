// Copyright (c) 2014-2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    objectName: "DownloadSettingsPage"
    allowedOrientations: Orientation.All

    QtObject {
        id: priv
        property bool settingsChanged: false
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        } else if (status === PageStatus.Deactivating) {
            if (priv.settingsChanged)
                YTPrefs.notifyDownloadSettingsChanged()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height > column.height ? height: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Title of video download settings pge
                //% "Download settings"
                title: qsTrId("ytplayer-title-download-settings")
            }

            TextSwitch {
                //: Label for video download auto resume switch in settings
                //% "Automatically resume downloads"
                text: qsTrId("ytplayer-label-autoresume")
                //: Description of video download auto resume switch in settings
                //% "On startup, resume all downloads which were either queued or "
                //% "in progress when YTPlayer was closed."
                description: qsTrId("ytplayer-description-autoresume")
                checked: YTPrefs.getBool("Download/ResumeOnStartup")
                automaticCheck: false
                onClicked: {
                    checked = !checked
                    YTPrefs.set("Download/ResumeOnStartup", checked)
                }
            }

            Slider {
                //: Label for slider changing the maximum number of concurrent downloads
                //% "Max. concurrent downloads"
                label: qsTrId("ytplayer-label-max-concurrent-downloads")
                width: parent.width
                minimumValue: 1
                maximumValue: 10
                stepSize: 1
                valueText: value
                Component.onCompleted: {
                    value = YTPrefs.getInt("Download/MaxConcurrentDownloads")
                }
                onReleased: {
                    YTPrefs.set("Download/MaxConcurrentDownloads", value)
                    priv.settingsChanged = true
                }
            }

            ComboBox {
                //: Label for preferred video quality selection combobox
                //% "Preferred video quality"
                label: qsTrId("ytplayer-label-preferred-quality")

                Component.onCompleted: {
                    switch (YTPrefs.get("Download/Quality")) {
                    case "720p" : currentIndex = 0; break;
                    case "360p" : currentIndex = 1; break;
                    default: console.assert(false);
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        text: "720p"
                        onClicked: YTPrefs.set("Download/Quality", text)
                    }
                    MenuItem {
                        text: "360p"
                        onClicked: YTPrefs.set("Download/Quality", text)
                    }
                }
            }

            ComboBox {
                id: connectionTypeCombo
                //: Label for video download connection type combobox
                //% "Connection type"
                label: qsTrId("ytplayer-label-connection-type")

                Component.onCompleted: {
                    switch (YTPrefs.get("Download/ConnectionType"))  {
                    case "WiFi"          : currentIndex = 0; break;
                    case "WiFi+Cellular" : currentIndex = 1; break;
                    case "Cellular"      : currentIndex = 2; break;
                    default: console.assert(false);
                    }
                }

                function changeType(type) {
                    YTPrefs.set("Download/ConnectionType", type)
                    priv.settingsChanged = true
                }

                menu: ContextMenu {
                    MenuItem {
                        //: Menu option indicating downloads are allowed only when using WiFi
                        //% "WiFi only"
                        text: qsTrId("ytplayer-action-wifi-only")
                        onClicked: connectionTypeCombo.changeType("WiFi")
                    }
                    MenuItem {
                        //: Menu option indicating downloads are allowed on both WiFi and 3G
                        //% "WiFi + Cellular"
                        text: qsTrId("ytplayer-action-wifi-cellular")
                        onClicked: connectionTypeCombo.changeType("WiFi+Cellular")
                    }
                    MenuItem {
                        //: Menu option indicating downloads are allowed only when using 3G
                        //% "Cellular only"
                        text: qsTrId("ytplayer-action-cellular-only")
                        onClicked: connectionTypeCombo.changeType("Cellular")
                    }
                }
            }
        } // Column

        VerticalScrollDecorator {}

    } // SilicaFlickable
}
