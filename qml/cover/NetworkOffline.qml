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

CoverBackground {
    id: root

    Image {
        anchors.margins: Theme.paddingMedium
        anchors.top: parent.top
        anchors.bottom: header.top
        anchors.left: parent.left
        anchors.right: parent.right
        fillMode: Image.PreserveAspectFit
        source: datadir + "/images/logo.png"
    }

    Rectangle {
        id: header
        x: Theme.paddingMedium
        anchors.centerIn: parent
        width: root.width
        height: children[0].height + 2 * Theme.paddingMedium
        color: "#AA000000"

        Label {
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamilyHeading
            color: Theme.primaryColor
            maximumLineCount: 2
            wrapMode: Text.Wrap
            //: Network offline screen label
            //% "Network Offline"
            text: qsTrId("ytplayer-label-network-offline")
        }
    }
}

