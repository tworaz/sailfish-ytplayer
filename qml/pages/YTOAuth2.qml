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
import QtWebKit 3.0
import Sailfish.Silica 1.0
import harbour.ytplayer.notifications 1.0
import "YoutubeClientV3.js" as YT

Page {
    id: page

    readonly property string scope: "https://www.googleapis.com/auth/youtube"
    readonly property string youtubeOAuthUri: NativeUtil.YouTubeAuthData["auth_uri"]
    readonly property string clientId: NativeUtil.YouTubeAuthData["client_id"]
    readonly property string clientSecret: NativeUtil.YouTubeAuthData["client_secret"]
    readonly property string redirectUri: NativeUtil.YouTubeAuthData["redirect_uri"]

    property string pageTitle: ""

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: !webview.visible
        size: BusyIndicatorSize.Large
    }

    Label {
        anchors.top: indicator.bottom
        width: parent.width
        text: "Signing in"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.highlightColor
        horizontalAlignment: Text.AlignHCenter
    }

    Notification {
        id: successNotification
        //: Notification informing the user that YouTube sign in succeeded
        //% "Sign in successful"
        previewBody: qsTrId("ytplayer-youtube-sign-in-successful")
        category: "network"
    }

    Notification {
        id: failureNotification
        category: "network.error"
    }

    SilicaWebView {
        id: webview
        anchors.fill: parent
        visible: false

        property string authCode: ""

        header: PageHeader {
            title: page.pageTitle
        }

        url: youtubeOAuthUri +
             "?client_id=" + encodeURIComponent(clientId) +
             "&redirect_uri=" + encodeURIComponent(redirectUri) +
             "&scope=" + encodeURIComponent(scope) +
             "&response_type=code" +
             "&access_type=offline"

        onLoadingChanged: {
            switch(loadRequest.status) {
            case WebView.LoadSucceededStatus:
                if (authCode.length === 0) {
                    visible = true
                }
                break
            case WebView.LoadFailedStatus:
                Log.warn("Authorization page loading failed!")
                //: YouTube OAuth page loading failure message
                //% "Failed to load OAuth authorization page!"
                failureNotification.previewBody = qsTrId("ytplayer-oauth-page-loading-failed")
                failureNotification.publish()
                break
            }
        }

        onTitleChanged: {
            if (title.indexOf('Success code') !== -1) {
                authCode = title.replace('Success code=', '')
                visible = false
                YT.requestOAuthTokens(authCode, onSuccess, onFailure)
            } else if (title.indexOf('Denied error') !== -1) {
                Log.debug("Youtube OAuth access denied!")
                //: Message informing the user about YouTube OAuth autorization denial
                //% "YouTube OAuth access denined!"
                failureNotification.previewBody = qsTrId("ytplayer-oauth-access-denied")
                failureNotification.publish()
                pageStack.navigateBack(PageStackAction.Animated)
            } else if (title.length > 0) {
                Log.debug("OAuth page title changed: " + title)
                pageTitle = title
            }
        }

        function onSuccess(result) {
            console.assert(result.hasOwnProperty('access_token'))
            console.assert(result.hasOwnProperty('refresh_token'))
            console.assert(result.hasOwnProperty('token_type'))
            Prefs.set("YouTubeAccessToken", result["access_token"])
            Prefs.set("YouTubeRefreshToken", result["refresh_token"])
            Prefs.set("YouTubeaAccessTokenType", result["token_type"])
            Prefs.set("YouTubeAccountIntegration", true)
            successNotification.publish()
            pageStack.pop(undefined, PageStackAction.Animated)
        }

        function onFailure(error) {
            Log.debug("Error: " + JSON.stringify(error, undefined, 2))
            //: Error message informing the user about OAuth authorization failure
            //% "OAuth authorization failed!"
            failureNotification.previewBody = qsTrId("ytplayer-oauth-failed")
            failureNotification.publish()
            pageStack.pop(undefined, PageStackAction.Animated)
        }
    }
}
