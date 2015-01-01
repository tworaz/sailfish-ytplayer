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
    QtObject {
        id: priv
        property variant thumbnails
    }

    Component.onCompleted: {
        if (coverData.bannerUrl)
            banner.source = coverData.bannerUrl
        priv.thumbnails = coverData.thumbnails
        title.text = coverData.title
    }

    Item {
        id: background
        anchors.fill: parent

        Image {
            id: banner
            width: parent.width
            fillMode: Image.PreserveAspectFit
        }
        Grid {
            id: imageGrid
            anchors.top: banner.bottom
            width: parent.width
            columns: 2
            Repeater {
                id: thumbRepeater
                model: priv.thumbnails.length
                Image {
                    source: priv.thumbnails[index].default.url
                    width: parent.width / 2
                    fillMode: Image.PreserveAspectCrop
                    height: width * thumbnailAspectRatio
                }
            }
        }
    }

    OpacityRampEffect {
        sourceItem: background
        direction: OpacityRamp.TopToBottom
    }

    Rectangle {
        id: header
        x: Theme.paddingMedium
        anchors.centerIn: parent
        width: parent.width
        height: children[0].height + 2 * Theme.paddingMedium
        z: background.z + 1
        color: "#AA000000"

        Label {
            id: title
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontFamilyHeading
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            color: Theme.primaryColor
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
        }
    }

    CoverActionList {
        id: actions

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                showSearchPage()
                activate()
            }
        }
    }
}

