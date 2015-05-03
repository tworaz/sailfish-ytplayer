// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Title of video player settings page
                //% "Player settings"
                title: qsTrId("ytplayer-title-player-settings")
            }

            TextSwitch {
                //: Label for video auto pause option on/off switch.
                //% "Auto pause when deactivated"
                text: qsTrId("ytplayer-label-autopause")
                //: Description of video auto pause option switch.
                //% "Automatically pause video playback when application is deactivated."
                description: qsTrId("ytplayer-description-autopause")
                automaticCheck: false
                Component.onCompleted: {
                    checked = YTPrefs.getBool("Player/AutoPause")
                }
                onClicked: {
                    checked = !checked
                    YTPrefs.set("Player/AutoPause", checked)
                }
            }

            Slider {
                //: Lael for slider changing video player controls hide delay
                //% "Controls hide delay"
                label: qsTrId("ytplayer-label-controls-hide-delay")
                width: parent.width
                minimumValue: 1
                maximumValue: 10
                stepSize: 1
                valueText: value + "s"
                Component.onCompleted: {
                    value = YTPrefs.getInt("Player/ControlsHideDelay") / 1000
                }
                onReleased: {
                    YTPrefs.set("Player/ControlsHideDelay", value * 1000)
                }
            }

            ComboBox {
                //: Label for combo box allowing the user to change video autoload behavior.
                //% "Early video loading"
                label: qsTrId("ytplayer-label-autoload")
                //: Descripton for combo box allowing the user to change video autload behavior.
                //% "Start preloading video data before player page is activated."
                description: qsTrId("ytplayer-description-autoload")
                Component.onCompleted: {
                    switch(YTPrefs.get("Player/AutoLoad")) {
                    case "Always"   : currentIndex = 0; break
                    case "WiFi"     : currentIndex = 1; break
                    case "Cellular" : currentIndex = 2; break
                    case "Never"    : currentIndex = 3; break
                    default: console.assert(false)
                    }
                }
                menu: ContextMenu {
                    MenuItem {
                        //: Menu option allowing the player to always preaload video data.
                        //% "Always"
                        text: qsTrId("ytplayer-action-autoload-always")
                        onClicked: YTPrefs.set("Player/AutoLoad", "Always")
                    }
                    MenuItem {
                        //: Menu option allowing the player to preaload video data only when
                        //: using WiFi connection.
                        //% "WiFi only"
                        text: qsTrId("ytplayer-action-autoload-wifi")
                        onClicked: YTPrefs.set("Player/AutoLoad", "WiFi")
                    }
                    MenuItem {
                        //: Menu option allowing the player to preaload video data only when
                        //: using cellular connection.
                        //% "Cellular only"
                        text: qsTrId("ytplayer-action-autoload-cellular")
                        onClicked: YTPrefs.set("Player/AutoLoad", "Cellular")
                    }
                    MenuItem {
                        //: Menu option disallowing the player to always preaload video data.
                        //% "Never"
                        text: qsTrId("ytplayer-action-autoload-never")
                        onClicked: YTPrefs.set("Player/AutoLoad", "Never")
                    }
                }
            }

            ComboBox {
                //: Label for combo box allowing the user to change default video quality
                //: when using WiFi connection.
                //% "Default video quality on WiFi"
                label: qsTrId("ytplayer-label-quality-wifi")
                Component.onCompleted: {
                    switch(YTPrefs.get("Player/DefaultQualityWiFi")) {
                    case "720p" : currentIndex = 0; break
                    case "360p" : currentIndex = 1; break
                    default: console.assert(false)
                    }
                }
                menu: ContextMenu {
                    MenuItem {
                        text: "720p"
                        onClicked: YTPrefs.set("Player/DefaultQualityWiFi", "720p")
                    }
                    MenuItem {
                        text: "360p"
                        onClicked: YTPrefs.set("Player/DefaultQualityWiFi", "360p")
                    }
                }
            }

            ComboBox {
                //: Label for combo box allowing the user to change default video quality
                //: when using cellular connection.
                //% "Default video quality on cellular"
                label: qsTrId("ytplayer-label-quality-cellular")
                Component.onCompleted: {
                    switch(YTPrefs.get("Player/DefaultQualityCellular")) {
                    case "720p" : currentIndex = 0; break
                    case "360p" : currentIndex = 1; break
                    default: console.assert(false)
                    }
                }
                menu: ContextMenu {
                    MenuItem {
                        text: "720p"
                        onClicked: YTPrefs.set("Player/DefaultQualityCellular", "720p")
                    }
                    MenuItem {
                        text: "360p"
                        onClicked: YTPrefs.set("Player/DefaultQualityCellular", "360p")
                    }
                }
            }
        } // Column
        VerticalScrollDecorator {}
    } // SilicaFlickable
}
