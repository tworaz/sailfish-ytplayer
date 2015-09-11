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

        // nemo-qml-plugin-notifications
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "nemo-qml-plugin-notifications"
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Copyright \u00A9 2015 Jolla Ltd"
        }
        Item {
            width: parent.width
            height: Theme.paddingMedium
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: kPreferredButtonWidth
            //: Button for showing license viewer page
            //% "View license"
            text: qsTrId("ytplayer-action-view-license")
            onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), {
                "licenseFile": "LICENSE.nemo-notifications"
            })
        }

        // duration.js
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "duration.js"
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Copyright \u00A9 2013 Evan W. Isnor"
        }
        Item {
            width: parent.width
            height: Theme.paddingMedium
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: kPreferredButtonWidth
            //: Button for showing license viewer page
            //% "View license"
            text: qsTrId("ytplayer-action-view-license")
            onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), {
                "licenseFile": "LICENSE.durationjs"
            })
        }

        // youtube-dl
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "youtube-dl " + YTUtils.youTubeDLVersion
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Public Domain License"
        }
        Item {
            width: parent.width
            height: Theme.paddingMedium
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            width: kPreferredButtonWidth
            //: Button for showing license viewer page
            //% "View license"
            text: qsTrId("ytplayer-action-view-license")
            onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), {
                "licenseFile": "LICENSE.youtube-dl"
            })
        }
    }
}
