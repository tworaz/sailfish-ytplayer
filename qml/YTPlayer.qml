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
import "pages"

ApplicationWindow
{
    property string regionCode: NativeUtil.regionCode
    readonly property string mainIconColor: "#FF980093"
    readonly property double thumbnailAspectRatio: 9 / 16
    // TODO don't hardcode this
    readonly property string datadir: "/usr/share/harbour-ytplayer/"

    initialPage: Component { VideoCategories { } }
    cover: Qt.resolvedUrl("cover/Default.qml")
    property variant coverData
    property variant defaultCoverData

    function requestCoverPage(coverFile, props) {
        var coverUrl = Qt.resolvedUrl("cover/" + coverFile)
        if (coverUrl !== cover) {
            Log.info("Changing cover to: " + coverFile)
            cover = coverUrl
            coverData = props
        }
    }

    FontLoader {
        id: youtubeWebFont
        source: "https://www.youtube.com/s/tv/fonts/youtube-icons.ttf"
    }

    YTDataAPIClient {
        id: ytDataAPIClient
    }

    Notification {
        id: errorNotification
        category: "network.error"

        function show(error) {
            Log.error("HTTP error code: " + error.code)
            Log.error("HTTP error details: " + JSON.stringify(error.details, undefined, 2))

            if (error.code === 0) {
                //: Internal application error notification summary
                //% "Internal application error"
                previewSummary = qsTrId('ytplayer-error-summary')
            } else if (error.code >= 400 && error.code < 600) {
                //: HTTP error notification summary
                //% "HTTP error"
                previewSummary = qsTrId('ytplayer-http-error-summary')
            } else {
                //: Unknown HTTP error notification summary
                //% "Unknown network error"
                previewSummary = qsTrId('ytplayer-unknown-error-summary')
            }

            if (error.details) {
                if (error.details.hasOwnProperty("error")) {
                    previewBody = error.details.error.message
                } else {
                    //: Http client error notification body
                    //% "The server has returned %1"
                    previewBody = qsTrId('ytplayer-http-error-body').arg(error.code)
                }
            }

            publish()
        }
    }
}


