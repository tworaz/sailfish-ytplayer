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
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            //% "Log Viewer"
            title: qsTrId("ytplayer-title-log-viewer")
        }

        model: LogModel { }

        delegate: Component {
            Rectangle {
                width: parent.width
                height: children[0].height + Theme.paddingMedium

                color: {
                    switch (type) {
                    case LogModel.LOG_DEBUG:
                        return "#662219B2"
                    case LogModel.LOG_ERROR:
                        return "#66FF0000"
                    case LogModel.LOG_WARN:
                        return "#66FFFD00"
                    case LogModel.LOG_INFO:
                        return "#6641DB00"
                    }
                }

                Label {
                    x: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeTiny
                    wrapMode: Text.Wrap
                    text: message
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
