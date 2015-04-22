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

Column {
    id: root

    property alias title: header.title
    property bool searchVisible: false

    signal searchQueryChanged(var text)

    onSearchVisibleChanged: {
        if (searchVisible) {
            search.state = "visible"
            search.forceActiveFocus()
        } else {
            search.state = "hidden"
            header.forceActiveFocus()
        }
    }

    PageHeader {
        id: header
    }
    SearchField {
        id: search
        width: parent.width
        EnterKey.enabled: false
        state: "hidden"
        onTextChanged: root.searchQueryChanged(text)

        states: [
            State {
                name: "visible"
                PropertyChanges { target: search; opacity: 1.0; scale: 1.0 }
            },
            State {
                name: "hidden"
                PropertyChanges { target: search; opacity: 0; height: 0; scale: 0.0 }
            }

        ]
        transitions: [
            Transition {
                NumberAnimation { properties: "opacity"; duration: kStandardAnimationDuration }
                NumberAnimation { properties: "scale"; duration: kStandardAnimationDuration }
                NumberAnimation { properties: "height"; duration: kStandardAnimationDuration }
                onRunningChanged: {
                    if (!running && search.state === "hidden" && search.text.length > 0)
                        search.text = ""
                }
            }
        ]
    }
}
