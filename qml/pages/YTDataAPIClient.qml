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
import harbour.ytplayer 1.0

Item {
    readonly property alias oAuth2URL: client.OAuth2URL

    property var _requestQueue: []

    function list(resource, params, onSuccess, onFailure) {
        _requestQueue.push({
            "method"   : "list",
            "resource" : resource,
            "params"   : params,
            "success"  : onSuccess,
            "failure"  : onFailure,
        });
        client.process()
    }

    function post(resource, params, content, onSuccess, onFailure) {
        _requestQueue.push({
            "method"   : "post",
            "resource" : resource,
            "content"  : content,
            "params"   : params,
            "success"  : onSuccess,
            "failure"  : onFailure,
        })
        client.process()
    }

    function del(resource, params, onSuccess, onFailure) {
        _requestQueue.push({
            "method"   : "delete",
            "resource" : resource,
            "params"   : params,
            "success"  : onSuccess,
            "failure"  : onFailure,
        })
        client.process();
    }

    function requestOAuth2Token(authCode, onSuccess, onFailure) {
        _requestQueue.push({
            "method"   : "requestOAuth2Token",
            "authCode" : authCode,
            "success"  : onSuccess,
            "failure"  : onFailure,
        })
        client.process()
    }

    YTClient {
        id: client

        property bool busy: false
        property var request

        function process() {
            if (!busy && _requestQueue.length > 0) {
                request = _requestQueue.pop()
                //Log.debug("Executing request: " + JSON.stringify(request))
                _run(request)
            }
        }

        function _run(req) {
            if (req.method === "list") {
                client.list(req.resource, req.params)
            } else if (req.method === "post") {
                client.post(req.resource, req.params, req.content)
            } else if (req.method === "delete") {
                client.del(req.resource, req.params)
            } else {
                console.assert(req.method === "requestOAuth2Token")
                client.requestOAuth2Token(req.authCode)
            }
            busy = true
        }

        onSuccess: {
            request.success(response)
            request = undefined
            busy = false
            process()
        }

        onError: {
            request.failure(details)
            request = undefined
            busy = false
            process()
        }

        onRetry: {
            _run(request)
        }
    }
}
