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
import "Settings.js" as S

Page {
    id: settingsPage

    Component.onCompleted: {
        requestCoverPage("Default.qml")
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //% "About YTPlater"
                text: qsTrId("ytplayer-title-about")
                onClicked: pageStack.push(Qt.resolvedUrl("About.qml"))
            }
        }

        Column {
            x: Theme.paddingLarge
            width: parent.width - 2 * Theme.paddingLarge
            spacing: Theme.paddingMedium

            PageHeader {
                //: Settings page title
                //% "Settings"
                title: qsTrId("ytplayer-title-settings")
            }

            Label {
                //: Account settings section label
                //% "Account"
                text: qsTrId("ytplayer-label-account")
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            TextSwitch {
                //: Label of switch activating/deactivating YouTube account integration
                //% "YouTube account integration"
                text: qsTrId("ytplayer-account-integration-label")
                //: Description of switch activating/deactivating YouTube account integration
                //% "Allow YTPlayer to manage YouTube user account"
                description: qsTrId("ytplayer-account-integration-description")
                checked: S.get(S.YOUTUBE_ACCOUNT_INTEGRATION) === S.ENABLE

                onCheckedChanged: {
                    if (settingsPage.status !== PageStatus.Active) {
                        return
                    }

                    if (checked) {
                        Log.info("Enabling account integration")
                        pageStack.push(Qt.resolvedUrl("YTOAuth2.qml"))
                    } else {
                        Log.info("Disabling account integration")
                        S.set(S.YOUTUBE_ACCESS_TOKEN, "")
                        S.set(S.YOUTUBE_REFRESH_TOKEN, "")
                        S.set(S.YOUTUBE_TOKEN_TYPE, "")
                        S.set(S.YOUTUBE_ACCOUNT_INTEGRATION, S.DISABLE)
                    }
                }
            }

            Label {
                //: Search settings section label
                //% "Search"
                text: qsTrId("ytplayer-label-search")
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            ComboBox {
                //: Content filtering settings option label
                //% "Content filtering"
                label: qsTrId("ytplayer-label-content-filtering")
                width: parent.width
                currentIndex: S.get(S.SAFE_SEARCH)

                menu: ContextMenu {
                    // Indexes of menu items should match SAFE_SEARCH_ keys in Settings.js
                    MenuItem {
                        //: Option value for lack of any content filtering
                        //% "None"
                        text: qsTrId("ytplayer-content-fitering-none")
                    }
                    MenuItem {
                        //: Option value for moderate content filtering
                        //% "Moderate"
                        text: qsTrId("ytplayer-content-filtering-moderate")
                    }
                    MenuItem {
                        //: Option value for strict content filtering
                        //% "Strict
                        text: qsTrId("ytplayer-content-filtering-strict")
                    }
                }

                onCurrentIndexChanged: S.set(S.SAFE_SEARCH, currentIndex);
            }

            Label {
                //: Display settings section label
                //% "Display"
                text: qsTrId("ytplayer-label-display")
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Text.AlignRight
            }

            Slider {
                width: parent.width
                minimumValue: 15
                maximumValue: 50
                stepSize: 5
                value: S.get(S.RESULTS_PER_PAGE)
                valueText: value
                //: Label of results per page slider in display settings menu
                //% "Results per page"
                label: qsTrId("ytplayer-label-results-per-page")
                onValueChanged: S.set(S.RESULTS_PER_PAGE, value)
            }
        }
    }
}
