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
    id: settingsPage

    SilicaListView {
        id: view
        anchors.fill: parent

        header: PageHeader {
            //: Settings page title
            //% "Settings"
            title: qsTrId("ytplayer-title-settings")
        }

        model: ListModel {
            id: optionsModel
            ListElement {
                icon: "image://theme/icon-m-display"
                page: "DisplaySettings.qml"
            }
            ListElement {
                icon: "image://theme/icon-m-about"
                page: "About.qml"
            }

            function name(index) {
                if (name["text"] === undefined) {
                    name.text = [
                        //: Title of display settings page
                        //% "Display"
                        qsTrId("ytplayer-title-display"),
                        //% "About YTPlater"
                        qsTrId("ytplayer-title-about"),
                    ]
                }
                return name.text[index]
            }
        }

        delegate: BackgroundItem {
            id: optionItem

            Image {
                id: optionIcon
                anchors.verticalCenter: parent.verticalCenter
                source: icon
            }
            Label {
                color: optionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                width: settingsPage.width
                anchors.left: optionIcon.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                text: view.model.name(index)
            }

            onClicked: pageStack.push(Qt.resolvedUrl(page))
        }
    }
}
