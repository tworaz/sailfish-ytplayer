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
    objectName: "DownloadSettings"
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: childrenRect.height

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Title of video download settings pge
                //% "Video download settings"
                title: qsTrId("ytplayer-title-download-settings")
            }

            TextSwitch {
                //: Label for video download auto resume switch in settings
                //% "Automatically resume downloads"
                text: qsTrId("ytplayer-label-autoresume")
                //: Description of video download auto resume switch in settings
                //% "On startup, resume all downloads which were either quened or "
                //% "in progress when YTPlayer was closed."
                description: qsTrId("ytplayer-description-autoresume")
                checked: Prefs.getBool("Download/ResumeOnStartup")
                automaticCheck: false
                onClicked: {
                    checked = !checked
                    Prefs.set("Download/ResumeOnStartup", checked)
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
                    value = Prefs.getInt("Download/MaxConcurrentDownloads")
                }
                onReleased: {
                    Prefs.set("Download/MaxConcurrentDownloads", value)
                }
            }

            ComboBox {
                //: Label for preferred video quality selection combobox
                //% "Preferred video quality"
                label: qsTrId("ytplayer-label-preferred-quality")

                Component.onCompleted: {
                    switch (Prefs.get("Download/Quality")) {
                    case "1080p": currentIndex = 0; break;
                    case "720p" : currentIndex = 1; break;
                    case "360p" : currentIndex = 2; break;
                    default: console.assert(false);
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        text: "1080p"
                        onClicked: Prefs.set("Download/Quality", text)
                    }
                    MenuItem {
                        text: "720p"
                        onClicked: Prefs.set("Download/Quality", text)
                    }
                    MenuItem {
                        text: "360p"
                        onClicked: Prefs.set("Download/Quality", text)
                    }
                }
            }

            ComboBox {
                //: Label for video download connection type combobox
                //% "Connection type"
                label: qsTrId("ytplayer-label-connection-type")

                Component.onCompleted: {
                    switch (Prefs.get("Download/ConnectionType"))  {
                    case "WiFi"          : currentIndex = 0; break;
                    case "WiFi+Cellular" : currentIndex = 1; break;
                    case "Cellular"      : currentIndex = 2; break;
                    default: console.assert(false);
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        //: Menu option indicating downloads are allowed only when using WiFi
                        //% "WiFi only"
                        text: qsTrId("ytplayer-action-wifi-only")
                        onClicked: Prefs.set("Download/ConnectionType", "WiFi")
                    }
                    MenuItem {
                        //: Menu option indicating downloads are allowed on both WiFi and 3G
                        //% "WiFi + Cellular"
                        text: qsTrId("ytplayer-action-wifi-cellular")
                        onClicked: Prefs.set("Download/ConnectionType", "WiFi+Cellular")
                    }
                    MenuItem {
                        //: Menu option indicating downloads are allowed only when using 3G
                        //% "Cellular only"
                        text: qsTrId("ytplayer-action-cellular-only")
                        onClicked: Prefs.set("Download/ConnectionType", "Cellular")
                    }
                }
            }
        } // Column
    } // SilicaFlickable
}
