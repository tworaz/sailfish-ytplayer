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
import harbour.ytplayer 1.0

Page {
    backNavigation: false
    showNavigationIndicator: false

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!networkManager.online) {
                networkManager.onOnlineStateChanged(networkManager.online)
            }
            webfont.load()
        }
    }

    YTWebFontLoader {
        id: webfont

        onLoadedChanged: {
            console.assert(loaded)
            Log.info("YouTube icons webfont loaded")
            pageStack.replace(Qt.resolvedUrl("VideoCategories.qml"),
                              undefined, PageStackAction.Immediate)
        }

        onError: {
            // TODO: Display error page
            Log.error("Failed to load YouTube webfont")
            pageStack.replace(Qt.resolvedUrl("VideoCategories.qml"),
                              undefined, PageStackAction.Immediate)
        }
    }

    Item {
        width: parent.width
        height: childrenRect.height
        anchors.centerIn: parent

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            id: indicator
            size: BusyIndicatorSize.Large
            running: true
        }

        Label {
            //: Generic label informing user some content is being loaded
            //% "Loading"
            text: qsTrId("ytplayer-label-loading")
            anchors.top: indicator.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraLarge
            font.family: Theme.fontFamilyHeading
        }
    }
}
