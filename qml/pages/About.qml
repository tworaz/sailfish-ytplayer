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
    id: aboutPage

    PageHeader {
        id: header
        //: Title of about page
        //% "About YTPlayer"
        title: qsTrId("ytplayer-title-about")
    }

    Column {
        anchors.top: header.bottom
        width: parent.width
        spacing: 36

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeMedium
            font.family: Theme.fontFamily
            //: YTPlayer application description in about page
            //% "Unofficial YouTube client for Sailfish OS"
            text: qsTrId("ytplayer-label-application-description")
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1.60 * play_icon.width
            height: 1.20 * play_icon.height
            color: mainIconColor
            radius: 20
            Image {
                id: play_icon
                anchors.centerIn: parent
                source: "image://theme/icon-cover-play"
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            //: Version label value
            //% "Version: %1"
            text: qsTrId("ytplayer-label-version").arg(NativeUtil.version)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            //: Region code field value
            //% "Region code: %1"
            text: qsTrId('ytplayer-label-region-code').arg(regionCode)
        }
    }
}
