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

    SilicaFlickable {
        id: aboutFlickable
        anchors.fill: parent
        contentHeight: aboutColumn.height + Theme.paddingLarge

        VerticalScrollDecorator { flickable: aboutFlickable }

        Column {
            id: aboutColumn
            anchors.top: parent.top
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: Title of about page
                //% "About YTPlayer"
                title: qsTrId("ytplayer-title-about")
            }
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                height: Theme.itemSizeMedium
                width: Theme.itemSizeMedium
                fillMode: Image.PreserveAspectFit
                source: "qrc:///logo.png"
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
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
                text: "Copyright \u00A9 2014-2015 Piotr Tworek\n"
                      +"2015-2018 Petr Tsymbarovich\n"
                      +"2019-2020 Matti Viljanen"
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
            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                readonly property real buttonWidth: Math.max(kPreferredButtonWidth,
                                                             b1.implicitWidth,
                                                             b2.implicitWidth,
                                                             b3.implicitWidth,
                                                             b4.implicitWidth)
                Button {
                    id: b1
                    width: parent.buttonWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: Button for showing license viewer page
                    //% "View license"
                    text: qsTrId("ytplayer-action-view-license")
                    onClicked: pageStack.push(Qt.resolvedUrl("LicenseViewer.qml"), { "licenseFile": "LICENSE.YTPlayer" })
                }
                Button {
                    id: b2
                    width: parent.buttonWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: Label for button showing third party software listing page
                    //% "Third party software"
                    text: qsTrId("ytplayer-action-third-party-software")
                    onClicked: pageStack.push(Qt.resolvedUrl("ThirdPartySoftware.qml"))
                }
                Button {
                    id: b3
                    width: parent.buttonWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: Label for button showing application translation credits page
                    //% "Translations"
                    text: qsTrId("ytplayer-action-translation-credits")
                    onClicked: pageStack.push(Qt.resolvedUrl("TranslationCredits.qml"))
                }
                Button {
                    id: b4
                    width: parent.buttonWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: Label for button showing application translation credits page
                    text: "GitHub"
                    onClicked: Qt.openUrlExternally("https://github.com/direc85/sailfish-ytplayer")
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryColor
                //: Description for Ko-Fi donation link image
                //% "The original creator, tworaz, deserves all the credit for this awesome app. If, however, you would like to give your support to the maintainer, you can buy him a nice cup of coffee!"
                text: qsTrId("ytplayer-about-ko-fiz")
            }

            BackgroundItem {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.iconSizeExtraLarge * 1.2
                height: Theme.iconSizeExtraLarge * 1.2
                onClicked: Qt.openUrlExternally("https://ko-fi.com/direc85")
                contentItem.radius: Theme.paddingSmall

                Image {
                    anchors.centerIn: parent
                    source: "qrc:///ko-fi.png"
                    width: Theme.iconSizeExtraLarge
                    height: Theme.iconSizeExtraLarge
                    smooth: true
                    asynchronous: true
                }
            }
        }
    }
}
