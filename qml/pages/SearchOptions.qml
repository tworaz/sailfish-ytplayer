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

Page {
    objectName: "SearchOptions"
    allowedOrientations: Orientation.All

    property variant currentSettings: ({})
    property bool changed: false

    QtObject {
        id: priv
        property bool videoTypeSelected: false
        property bool channelTypeSelected: false
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        }
    }

    function handleSetting(key, item) {
        var cur = undefined;
        if (item.hasOwnProperty("value")) {
            cur = currentSettings
            cur[key] = item.value
            currentSettings = cur
        } else if (currentSettings.hasOwnProperty(key)) {
            cur = currentSettings
            delete cur[key]
            currentSettings = cur
        }
        changed = true
    }

    function handleDateSwitch(key, swItem) {
        if (swItem.checked) {
            var dialog = pageStack.push(pickerComponent)
            dialog.accepted.connect(function() {
                swItem.description = dialog.dateText
                var c = currentSettings
                c[key] = dialog.date.toISOString()
                currentSettings = c
            })
            dialog.rejected.connect(function() {
                swItem.checked = false
            })
        } else {
            swItem.description = ""
            var c = currentSettings
            delete c[key]
            currentSettings = c
        }
        changed = true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //: Search options page title
                //% "Search options"
                title: qsTrId("ytplayer-title-search-options")
            }

            ComboBox {
                //: Label for YouTube content type search combo box
                //% "Result type"
                label: qsTrId("ytplayer-label-result-type")
                menu: ContextMenu {
                    MenuItem {
                        //: Label for generic option menu matching any content type
                        //% "Any"
                        text: qsTrId("ytplayer-label-any")
                        // TODO: remove the line below once playlist are supported
                        property string value: "channel,video"
                    }
                    MenuItem {
                        //: Label for menu option indicating YouTube channel content type
                        //% "Channel"
                        text: qsTrId("ytplayer-label-channel")
                        property string value: "channel"
                    }
                    // TODO: Add support for YouTube playlists
                    //MenuItem {
                    //    text: "Playlist"
                    //    property string value: "playlist"
                    //}
                    MenuItem {
                        //: Label for menu option indicating YouTube video content type
                        //% "Video"
                        text: qsTrId("ytplayer-label-video")
                        property string value: "video"
                    }
                }
                onCurrentItemChanged: {
                    priv.videoTypeSelected = (currentItem.value !== undefined &&
                                              currentItem.value === "video")
                    priv.channelTypeSelected = (currentItem.value !== undefined &&
                                                currentItem.value === "channel")
                    handleSetting("type", currentItem)
                }
            }
            ComboBox {
                id: quality
                //: Label for video quality selection combo box
                //% "Video quality"
                label: qsTrId("ytplayer-label-video-quality")
                visible: priv.videoTypeSelected
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("ytplayer-label-any")
                    }
                    MenuItem {
                        //: Label for high video quality menu option
                        //% "High definition"
                        text: qsTrId("ytplayer-label-high-definition")
                        property string value: "high"
                    }
                    MenuItem {
                        //: Label for standard video quality menu option
                        //% "Standard definition"
                        text: qsTrId("ytplayer-label-standard-definition")
                        property string valie: "standard"
                    }
                }
                onCurrentItemChanged: handleSetting("videoDefinition", currentItem)
                Connections {
                    target: priv
                    onVideoTypeSelectedChanged: {
                        if (!priv.videoTypeSelected)
                            quality.currentIndex = 0
                    }
                }
            }
            ComboBox {
                id: duration
                //: Label for video duration combo box
                //% "Video duration"
                label: qsTrId("ytplayer-label-video-duration")
                visible: priv.videoTypeSelected
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("ytplayer-label-any")
                    }
                    MenuItem {
                        //: Label for long (more than 20 minutes) video option menu
                        //% "Longer than 20 minutes"
                        text: qsTrId("ytplayer-label-video-duration-long")
                        property string value: "long"
                    }
                    MenuItem {
                        //: Label for medium (4-20 miniutes) video option menu
                        //% "Between 4 and 20 minutes"
                        text: qsTrId("ytplayer-label-video-duration-medium")
                        property string value: "medium"
                    }
                    MenuItem {
                        //: Label for short (less than 4 minutes) video option MenuItem
                        //% "Less than 4 minutes"
                        text: qsTrId("ytplayer-label-video-duration-short")
                        property string value: "short"
                    }
                }
                onCurrentItemChanged: handleSetting("videoDuration", currentItem)
                Connections {
                    target: priv
                    onVideoTypeSelectedChanged: {
                        if (!priv.videoTypeSelected)
                            duration.currentIndex = 0
                    }
                }
            }
            ComboBox {
                id: videoType
                //: Label for video type combo box
                //% "Video type"
                label: qsTrId("ytplayer-label-video-type")
                visible: priv.videoTypeSelected
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("ytplayer-label-any")
                    }
                    MenuItem {
                        //: Label for episode video type
                        //% "Episode"
                        text: qsTrId("ytplayer-label-video-episode")
                        property string value: "episode"
                    }
                    MenuItem {
                        //: Label for movie video type
                        //% "Movie"
                        text: qsTrId("ytplayer-label-video-movie")
                        property string value: "movie"
                    }
                }
                onCurrentItemChanged: handleSetting("videoType", currentItem)
                Connections {
                    target: priv
                    onVideoTypeSelectedChanged: {
                        if (!priv.videoTypeSelected)
                            videoType.currentIndex = 0
                    }
                }
            }
            ComboBox {
                id: license
                //: Label for video license combo box
                //% "Video license"
                label: qsTrId("ytplayer-label-video-license")
                visible: priv.videoTypeSelected
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("ytplayer-label-any")
                    }
                    MenuItem {
                        //: Label for Creative Commons license type
                        //% "Creative Commons"
                        text: qsTrId("ytplayer-label-cretive-commons-license")
                        property string value: "creativeCommon"
                    }
                    MenuItem {
                        //: Label for YouTube license type
                        //% "YouTube"
                        text: qsTrId("ytplayer-label-youtube-license")
                        property string value: "youtube"
                    }
                }
                onCurrentItemChanged: handleSetting("videoLicense", currentItem)
                Connections {
                    target: priv
                    onVideoTypeSelectedChanged: {
                        if (!priv.videoTypeSelected)
                            license.currentIndex = 0
                    }
                }
            }
            ComboBox {
                id: eventType
                //: Label for video event type combo box
                //% "Event Type"
                label: qsTrId("ytplayer-label-video-event-type")
                visible: priv.videoTypeSelected
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("ytplayer-label-any")
                    }
                    MenuItem {
                        //: Label for completed event type option
                        //% "Completed"
                        text: qsTrId("ytplayer-label-completed-event")
                        property string value: "completed"
                    }
                    MenuItem {
                        //: Label for live event type option
                        //% "Live"
                        text: qsTrId("ytplayer-label-live-event")
                        property string value: "live"
                    }
                    MenuItem {
                        //: Label for upcoming event type option
                        //% "Upcoming"
                        text: qsTrId("ytplayer-label-upcoming-event")
                        property string value: "upcoming"
                    }
                }
                onCurrentItemChanged: handleSetting("eventType", currentItem)
                Connections {
                    target: priv
                    onVideoTypeSelectedChanged: {
                        if (!priv.videoTypeSelected)
                            eventType.currentIndex = 0
                    }
                }
            }
            ComboBox {
                id: order
                //: Label for search result ordering combo box
                //% "Order by"
                label: qsTrId("ytplayer-label-results-order-by")
                menu: ContextMenu {
                    MenuItem {
                        //: Label for relevance ordering menu option
                        //% "Relevance"
                        text: qsTrId("ytplayer-label-order-relevance")
                    }
                    MenuItem {
                        //: Label for date ordering menu option
                        //% "Date"
                        text: qsTrId("ytplayer-label-order-date")
                        property string value: "date"
                    }
                    MenuItem {
                        //: Label for rating ordering menu option
                        //% "Rating"
                        text: qsTrId("ytplayer-label-order-rating")
                        property string value: "rating"
                    }
                    MenuItem {
                        //: Label for title ordering menu option
                        //% "Title"
                        text: qsTrId("ytplayer-label-order-title")
                        property string value: "title"
                    }
                    MenuItem {
                        //: Label for video count ordering menu option
                        //% "Video count"
                        text: qsTrId("ytplayer-label-order-video-count")
                        visible: priv.channelTypeSelected
                        property string value: "videoCount"
                        Connections {
                            target: priv
                            onChannelTypeSelectedChanged: {
                                if (!priv.channelTypeSelected)
                                    order.currentIndex = 0
                            }
                        }
                    }
                    MenuItem {
                        //: Label for view count ordering menu option
                        //% "View count"
                        text: qsTrId("ytplayer-label-order-view-count")
                        property string value: "viewCount"
                    }
                }
                onCurrentItemChanged: handleSetting("order", currentItem)
            }
            ComboBox {
                //: Label for safe search combo box
                //% "Safe search"
                label: qsTrId("ytplayer-label-safe-search")
                menu: ContextMenu {
                    MenuItem {
                        //: Label for moderate content search filtering option
                        //% "Moderate"
                        text: qsTrId("ytplayer-label-safe-search-moderate")
                    }
                    MenuItem {
                        //: Label for no search content filtering menu option
                        //% "None"
                        text: qsTrId("ytplayer-label-safe-search-none")
                        property string value: "none"
                    }
                    MenuItem {
                        //: Label for strict search content filtering menu option
                        //% "Strict"
                        text: qsTrId("ytplayer-label-safe-search-strict")
                        property string value: "strict"
                    }
                }
                onCurrentItemChanged: handleSetting("safeSearch", currentItem)
            }

            TextSwitch {
                id: before
                //: Label for published before search option menu
                //% "Published before"
                text: qsTrId("ytplayer-label-published-before")
                onCheckedChanged: handleDateSwitch("publishedBefore", before)
            }
            TextSwitch {
                id: after
                //: Label for published after search option MenuItem
                //% "Published after"
                text: qsTrId("ytplayer-label-published-after")
                onCheckedChanged: handleDateSwitch("publishedAfter", after)
            }

            VerticalScrollDecorator {}
        }
    }
    Component {
        id: pickerComponent
        DatePickerDialog {}
    }
}
