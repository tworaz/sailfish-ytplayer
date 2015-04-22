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
            //: Title of about page
            //% "About YTPlayer"
            title: qsTrId("ytplayer-title-about")
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 256
            fillMode: Image.PreserveAspectFit
            source: "qrc:///logo.png"
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            //: YTPlayer application description in about page
            //% "Unofficial YouTube client for Sailfish OS"
            text: qsTrId("ytplayer-label-application-description")
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            //: Region code field value
            //% "Region code: %1"
            text: qsTrId("ytplayer-label-region-code").arg(regionCode)
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            //: Version label value
            //% "Version: %1"
            text: qsTrId("ytplayer-label-version").arg(YTUtils.version)
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Copyright \u00A9 2014-2015 Piotr Tworek"
        }
        Label {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            //: Label displaying YTPlayer licensing information
            //% "YTPlayer is licensed under 3-clause BSD License"
            text: qsTrId("ytplayer-label-application-license")
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            //: Button for showing license viewer page
            //% "View license"
            text: qsTrId("ytplayer-action-view-license")
            onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), {
                "licenseFile": "LICENSE.YTPlayer"
            })
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            //: Label for button showing third party software listing page
            //% "Third party software"
            text: qsTrId("ytplayer-action-third-party-software")
            onClicked: pageStack.push(Qt.resolvedUrl("ThirdPartySoftware.qml"))
        }
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            //: Label for button showing application translation credits page
            //% "Translations"
            text: qsTrId("ytplayer-action-translation-credits")
            onClicked: pageStack.push(Qt.resolvedUrl("TranslationCredits.qml"))
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingSmall
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeTiny
        text: "https://github.com/tworaz/sailfish-ytplayer"
    }
}
