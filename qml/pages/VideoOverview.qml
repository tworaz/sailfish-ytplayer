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
import "YoutubeClientV3.js" as Yt


Page {
    id: page
    property string videoId

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        running: true
        size: BusyIndicatorSize.Large
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: wrapper.height

        PullDownMenu {
            MenuItem {
                text: "Refresh"
                /*onClicked: pageStack.push(Qt.resolvedUrl("SecondPage.qml"))*/
            }
        }

        Column {
            id: wrapper
            width: parent.width - 2 * Theme.paddingMedium
            x: Theme.paddingMedium

            PageHeader {
                id: header
            }


            Image {
                id: poster
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: width * 3 / 4
                fillMode: Image.PreserveAspectFit

                onStatusChanged: {
                    if (poster.status == Image.Ready) {
                        playButton.visible = true
                    }
                }

                MouseArea {
                    id: playButton
                    anchors.centerIn: parent
                    visible: false
                    width: ytBackground.width
                    height: ytBackground.height

                    Rectangle {
                        id: ytBackground
                        anchors.centerIn: parent
                        width: 1.60 * play_icon.width
                        height: 1.20 * play_icon.height
                        color: "#BBDE483C"
                        radius: 20
                    }

                    Image {
                        id: play_icon
                        anchors.centerIn: parent
                        source: "image://theme/icon-cover-play"
                    }

                    onClicked: {
                        console.debug("Play button clicked")
                        onClicked: pageStack.push(Qt.resolvedUrl("VideoPlayer.qml"),
                                                  {"videoId" : videoId, "title": header.title})

                    }
                }
            }

            Label {
                id: description
                width: parent.width;
                font {
                    family: Theme.fontFamily
                    pixelSize: Theme.fontSizeSmall
                }
                color: Theme.primaryColor
                wrapMode: Text.Wrap
            }
        }

        function onVideoDetailsLoaded(details) {
            //console.debug("Have video details: " + JSON.stringify(details, undefined, 2))
            var thumbnails = details.snippet.thumbnails;
            if (thumbnails.standard) {
                poster.source = thumbnails.standard.url
            } else if (thumbnails.high) {
                poster.source = thumbnails.high.url;
            } else {
                poster.source = thumbnails.default.url
            }

            description.text = details.snippet.description
            header.title = details.snippet.title
            indicator.running = false
        }

        function onFailure(msg) {
            console.error("Video overview failure: " + msg)
            indicator.running = false
        }

        Component.onCompleted: {
            console.debug("Video overview page created")
            console.debug("Video ID: " + videoId)
            Yt.getVideoDetails(videoId, onVideoDetailsLoaded, onFailure)
        }

        VerticalScrollDecorator {}
    }
}
