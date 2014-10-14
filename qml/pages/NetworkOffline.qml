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
    id: page
    backNavigation: false
    showNavigationIndicator: false
    allowedOrientations: Orientation.All
    state: page.isPortrait ? "PORTRAIT" : "LANDSCAPE"

    states: [
        State {
            name: "PORTRAIT"
            PropertyChanges { target: logo; height: 320 }
            PropertyChanges { target: flickable; anchors.topMargin: 3 * Theme.paddingLarge}
        },
        State {
            name: "LANDSCAPE"
            PropertyChanges { target: logo; height: 256 }
            PropertyChanges { target: flickable; anchors.topMargin: Theme.paddingLarge}
        }
    ]

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("NetworkOffline.qml")
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: Theme.paddingLarge
        anchors.bottomMargin: Theme.paddingLarge

        Item {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            height: 256
            width: parent.width
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:///logo.png"
            }
        }

        Label {
            width: parent.width
            anchors.top: logo.bottom
            anchors.bottom: btn.top
            //: Network offline screen label
            //% "Network Offline"
            text: qsTrId("ytplayer-label-network-offline")
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraLarge
            font.family: Theme.fontFamilyHeading
        }

        Button {
            id: btn
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            //: Label of network connection retry button
            //% "Retry"
            text: qsTrId("ytplayer-label-network-connection-retry")
            onClicked: networkManager.tryConnect()
        }
    }
}
