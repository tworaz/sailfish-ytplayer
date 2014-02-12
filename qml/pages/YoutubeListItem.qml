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

BackgroundItem {
    id: videoItem
    height: 94

    property variant youtubeId
    property string title
    property string thumbnailUrl

    Image {
        id: thumbnail
        width: 120
        height: 90
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
        fillMode: Image.PreserveAspectFit
        source: videoItem.thumbnailUrl

        BusyIndicator {
            size: BusyIndicatorSize.Small
            anchors.centerIn: parent
            running: thumbnail.status == Image.Loading
        }
    }

    Label {
        color: videoItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        //color: Theme.primaryColor
        elide: Text.ElideRight
        anchors {
            left: thumbnail.right
            right: parent.right
            leftMargin: Theme.paddingSmall
            rightMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }
        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSizeSmall
        }
        text: videoItem.title
    }

    onClicked: {
        if (youtubeId.kind === "youtube#video") {
            console.debug("Clicked item is a video, opening video overview page")
            pageStack.push(Qt.resolvedUrl("VideoOverview.qml"), {"videoId": youtubeId.videoId})
        } else if (youtubeId.kind === "youtube#channel") {
            console.error("TODO: implement support for browsing channel videos!")
        } else {
            console.error("Unrecogized id kind: " + youtubeId.kind);
        }
    }
}
