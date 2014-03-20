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

BackgroundItem {
    id: ytItem
    height: thumbnail.height + 2 * Theme.paddingSmall

    property variant youtubeId
    property alias title: itemLabel.text
    property alias thumbnailUrl: thumbnail.source

    AsyncImage {
        id: thumbnail
        width: 120
        height: width * thumbnailAspectRatio
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: Theme.paddingMedium
        }
        source: ytItem.thumbnailUrl
        indicatorSize: BusyIndicatorSize.Small
    }

    Label {
        id: itemLabel
        color: ytItem.highlighted ? Theme.highlightColor : Theme.primaryColor
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
    }

    onClicked: {
        if (youtubeId.kind === "youtube#video") {
            console.debug("Selected item is a video, opening video overview page")
            pageStack.push(Qt.resolvedUrl("VideoOverview.qml"),
                           { "videoId": youtubeId.videoId, title: ytItem.title })
        } else if (youtubeId.kind === "youtube#channel") {
            console.debug("Selected item is a channel, opening channel browser ")
            pageStack.push(Qt.resolvedUrl("ChannelBrowser.qml"),
                           {"channelId" : youtubeId.channelId, title: ytItem.title})
        } else {
            console.error("Unrecogized id kind: " + youtubeId.kind);
        }
    }
}
