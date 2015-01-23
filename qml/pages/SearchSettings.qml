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
import harbour.ytplayer 1.0
import "../common"

Page {
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active) {
            requestCoverPage("Default.qml")
        }
    }

    YTSuggestionEngine {
        id: engine
    }

    SilicaFlickable {
        anchors.fill: parent

        RemorsePopup {
            id: remorse
        }

        PullDownMenu {
            visible: engine.historySize > 0
            MenuItem {
                //: Menu option allowing the user to clear search history
                //% "Clear history"
                text: qsTrId("ytplayer-action-clear-history")
                visible: parent.visible
                onClicked: {
                    //: "Remorse popup message telling the user search history is about to be cleared"
                    //% "Clearing history"
                    remorse.execute(qsTrId("ytplayer-msg-clearing-history"), function() {
                        engine.clearHistory()
                    })
                }
            }
        }

        Column {
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //: Search settings page title
                //% "Search settings"
                title: qsTrId("ytplayer-title-search-settings")
            }

            ComboBox {
                id: engineChooser
                //: Label for the search suggestion engine combo box
                //% "Suggestion engine"
                label: qsTrId("ytplayer-label-suggestion-engine")

                Component.onCompleted: {
                    switch (Prefs.get("Search/SuggestionEngine")) {
                    case "Google" : currentIndex = 0; break
                    case "History": currentIndex = 1; break
                    default: console.assert(false)
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        //: Label for Google based search suggestion engine
                        //% "Google"
                        text: qsTrId("ytplayer-label-google-suggestion-engine")
                        onClicked: {
                            Prefs.set("Search/SuggestionEngine", "Google")
                        }
                    }
                    MenuItem {
                        //: Label for history based search suggestion engine
                        //% "History"
                        text: qsTrId("ytplayer-label-history-suggestion-engine")
                        onClicked: {
                            Prefs.set("Search/SuggestionEngine", "History")
                        }
                    }
                }
            } // ComboBox
        } // Column
    } // SilicaFlickable
}
