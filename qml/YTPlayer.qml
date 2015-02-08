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
import harbour.ytplayer.notifications 1.0
import harbour.ytplayer 1.0
import "pages"

ApplicationWindow
{
    property string regionCode: YTUtils.regionCode
    readonly property double thumbnailAspectRatio: 9 / 16
    readonly property string youtubeIconsFontName: "youtube-icons"
    readonly property int kMaxCoverThumbnailCount: 12
    readonly property int kThumbnailWidth: 120
    readonly property color kBlackTransparentBg: "#AA000000"
    readonly property string kYoutubeVideoUrlBase: "https://www.youtube.com/watch?v="
    readonly property int kListAutoLoadItemThreshold: 10

    initialPage: Component { MainMenu { } }
    cover: YTNetworkManager.online ?
               Qt.resolvedUrl("cover/Default.qml") :
               Qt.resolvedUrl("cover/NetworkOffline.qml")
    property variant coverData
    property variant defaultCoverData

    Component.onCompleted: {
        initialConnectivityCheck.start()
    }

    function requestCoverPage(coverFile, props) {
        var coverUrl = undefined
        if (YTNetworkManager.online)
            coverUrl = Qt.resolvedUrl("cover/" + coverFile)
        else
            coverUrl = Qt.resolvedUrl("cover/NetworkOffline.qml")

        if (coverUrl !== cover) {
            Log.info("Changing cover to: " + coverFile)
            cover = coverUrl
            coverData = props
        }
    }

    function showSearchPage() {
        if (pageStack.depth === 1)
            pageStack.push(Qt.resolvedUrl("pages/Search.qml"))

        var menu = pageStack.find(function(page){
            if (page.objectName === "MainMenu")
                return true
            return false
        })
        pageStack.replaceAbove(menu, Qt.resolvedUrl("pages/Search.qml"))
    }

    function openLinkInBrowser(url) {
        Log.debug("Opening link in browser: " + url)
        pageStack.push(Qt.resolvedUrl("pages/BrowserLauncher.qml"), {
            "url" : url,
        })
    }

    Timer {
        id: initialConnectivityCheck
        repeat: false
        interval: 100
        onTriggered: {
            if (!YTNetworkManager.online) {
                YTNetworkManager.onOnlineChanged(false)
            }
        }
    }

    Connections {
        target: YTNetworkManager
        onOnlineChanged: {
            if (online) {
                pageStack.pop()
            } else {
                pageStack.push(Qt.resolvedUrl("pages/NetworkOffline.qml"),
                               undefined, PageStackAction.Immediate)
            }
        }
    }

    YTVideoDownloadNotification {
        onFinished: {
            Log.info("Finished downloading video: " + video)
            //: Notification summary informing the user video download has been finished
            //% "Video download finished"
            downloadNotification.previewSummary = qsTrId("ytplayer-msg-download-finished")
            downloadNotification.previewBody = video
            downloadNotification.publish()
        }

        onFailed: {
            Log.info("Failed downloading video: " + video)
            //: Notification summary informing the user video download has failed
            //% "Video download failed"
            downloadNotification.previewSummary = qsTrId("ytplayer-msg-download-failed")
            downloadNotification.previewBody = video
            downloadNotification.publish()
        }
    }

    Notification {
        id: downloadNotification
    }
}
