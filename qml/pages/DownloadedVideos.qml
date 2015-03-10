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
import "../common/duration.js" as DJS
import "../common"

Page {
    allowedOrientations: Orientation.All
    objectName: "DownloadedVideos"

    onStatusChanged: {
        if (status === PageStatus.Active)
            requestCoverPage("Default.qml")
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: PageHeader {
            //: Title of downloaded videos page
            //% "Downloaded videos"
            title: qsTrId("ytplayer-title-downloaded-videos")
        }

        ViewPlaceholder {
            enabled: listView.count === 0
            //: "Label informing the user there are no preloaded videos"
            //% "No videos"
            text: qsTrId("ytplayer-label-no-videos")
        }

        model: YTLocalVideoListModel {
            id: listViewModel
        }

        delegate: ListItem {
            menu: contextMenuComponent
            ListView.onRemove: animateRemoval()

            Component.onCompleted: {
                videoDownload.videoId = videoId
            }

            AsyncImage {
                id: thumbnail
                width: kThumbnailWidth
                height: width * thumbnailAspectRatio
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                }
                indicatorSize: BusyIndicatorSize.Small

                Rectangle {
                    visible: videoDownload.status !== YTLocalVideo.Downloaded
                    anchors.fill: parent
                    color: kBlackTransparentBg

                    Label {
                        id: statusLabel
                        anchors.fill: parent
                        color: Theme.highlightColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    visible: (videoDownload.duration.length > 0) &&
                             parent.status === Image.Ready &&
                             videoDownload.status === YTLocalVideo.Downloaded
                    color: "black"
                    height: childrenRect.height
                    width: childrenRect.width + 2 * Theme.paddingSmall

                    Label {
                        x: Theme.paddingSmall
                        text: videoDownload.duration.length > 0 ?
                                  (new DJS.Duration(videoDownload.duration)).asClock() : ""
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall * 0.8
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

            }

            Label {
                color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                text: videoDownload.title
                anchors {
                    left: thumbnail.right
                    right: parent.right
                    leftMargin: Theme.paddingSmall
                    rightMargin: Theme.paddingSmall
                    verticalCenter: parent.verticalCenter
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("VideoOverview.qml"), {
                    "videoId"    : videoDownload.videoId,
                    "title"      : videoDownload.title,
                    "thumbnails" : videoDownload.thumbnails
                })
            }

            function remove() {
                var msg = undefined;
                if (videoDownload.status !== YTLocalVideo.Downloaded) {
                    //: Remorse popup message telling the user video download will be cancelled
                    //% "Cancelling download"
                    msg = qsTrId("ytplayer-msg-cancelling-download")
                } else {
                    //: Remorse popup message telling the user video download will be removed
                    //% "Removing download"
                    msg = qsTrId("ytplayer-msg-removing-download")
                }
                remorseAction(msg, function() {
                    videoDownload.remove()
                })
            }

            YTLocalVideo {
                id: videoDownload
                onStatusChanged: {
                    switch (status) {
                    case YTLocalVideo.Initial:
                        listViewModel.remove(index)
                        break
                    case YTLocalVideo.Paused:
                        //: Label for video download staus indicator telling the user download is paused
                        //% "Paused"
                        statusLabel.text = qsTrId("ytplayer-label-download-paused")
                        break
                    case YTLocalVideo.Loading:
                        statusLabel.text = downloadProgress + "%"
                        break
                    case YTLocalVideo.Queued:
                        //" Label for video download status indicator telling the user download is queued
                        //% "Queued"
                        statusLabel.text = qsTrId("ytplayer-label-download-queued")
                        break;
                    }
                }

                Component.onCompleted: {
                    if (thumbnails.hasOwnProperty("default"))
                        thumbnail.source = thumbnails.default.url
                }

                onDownloadProgressChanged: {
                    statusLabel.text = downloadProgress + "%"
                }

                onThumbnailsChanged: {
                    thumbnail.source = thumbnails.default.url
                }
            }

            Component {
                id: contextMenuComponent
                ContextMenu {
                    MenuItem {
                        //: Menu action to resume paused video download
                        //% "Resume"
                        text: qsTrId("ytplayer-action-resume")
                        visible: videoDownload.status === YTLocalVideo.Paused
                        onClicked: videoDownload.resume()
                    }
                    MenuItem {
                        //: Menu action to pause in progress video download
                        //% "Pause"
                        text: qsTrId("ytplayer-action-pause")
                        visible: videoDownload.status === YTLocalVideo.Loading
                        onClicked: videoDownload.pause()
                    }
                    MenuItem {
                        //: Menu action to remove the element from the list
                        //% "Remove"
                        text: qsTrId("ytplayer-action-remove")
                        onClicked: remove()
                        visible: videoDownload.status === YTLocalVideo.Downloaded
                    }
                    MenuItem {
                        //: Menu action to cancel paused/queued video download
                        //% "Cancel"
                        text: qsTrId("ytplayer-action-cancel")
                        onClicked: remove()
                        visible: videoDownload.status !== YTLocalVideo.Downloaded
                    }
                }
            }

        } // ListItem

        VerticalScrollDecorator {}
    } // SilicaListView
}
