// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

Page {
    onStatusChanged: {
        if (status === PageStatus.Active)
            requestCoverPage("Default.qml")
    }

    Column {
        anchors.fill: parent
        width: parent.width

        PageHeader {
            //: Third party software license page title
            //% "Third party software"
            title: qsTrId("ytplayer-title-third-party-software")
        }

        ListModel {
            id: contentModel
            ListElement {
                name: "nemo-qml-plugin-notifications"
                license: "Copyright \u00A9 2015 Jolla Ltd"
                file: "LICENSE.nemo-notifications"
            }
            ListElement {
                name: "duration.js"
                license: "Copyright \u00A9 2013 Evan W. Isnor"
                file: "LICENSE.durationjs"
            }
            ListElement {
                name: "youtube-dl"
                license: "Public Domain License"
                file: "LICENSE.youtube-dl"
            }
        }

        Repeater {
            model: contentModel
            Column {
                width: parent.width

                Item {
                    width: parent.width
                    height: Theme.paddingLarge
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: name
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: license
                }
                Item {
                    width: parent.width
                    height: Theme.paddingMedium
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(kPreferredButtonWidth, implicitWidth)
                    //: Button for showing license viewer page
                    //% "View license"
                    text: qsTrId("ytplayer-action-view-license")
                    onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), {
                        "licenseFile": file
                    })
                }
            }
        } // Repeater
    } // Column
}
