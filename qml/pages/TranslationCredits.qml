/*-
 * Copyright (c) 2015 Peter Tworek
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
    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //: Menu option opening a link to YTPlayer translation page on Transifex.
                //% "Translate YTPlayer"
                text: qsTrId("ytplayer-action-translate-app")
                onClicked: openLinkInBrowser("https://www.transifex.com/tworaz/ytplayer/")
            }
        }

        VerticalScrollDecorator { flickable: listView}

        header: PageHeader {
            //: Title of translation credits page
            //% "Translations"
            title: qsTrId("ytplayer-title-translation-credits")
        }

        model: YTTranslations.items

        delegate: Column {
            id: listItem
            x: Theme.paddingLarge
            width: parent.width - 2*x
            property variant authors: listView.model[index].authors

            SectionHeader {
                text: listView.model[index].name
                font.pixelSize: Theme.fontSizeSmall
            }
            Repeater {
                model: listItem.authors
                Label {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: Theme.paddingSmall
                    }
                    text: listItem.authors[index]
                    font.pixelSize: Theme.fontSizeExtraSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                    //horizontalAlignment: Text.AlignHCenter
                }
            }
        }

    }
}
