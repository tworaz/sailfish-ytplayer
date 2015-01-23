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

Item {
    id: root

    property string query: ""
    property bool hasResults: suggestionRepeater.model ?
                                  suggestionRepeater.model.length : false
    property bool isPortrait: false

    signal selected(var suggestion)

    function clear() {
        if (suggestionRepeater.model &&
            suggestionRepeater.model.length > 0)
            suggestionRepeater.model = []
    }

    function addToSearchHistory(query) {
        engine.addToHistory(query);
    }

    onQueryChanged: engine.find(query)

    YTSuggestionEngine {
        id: engine

        onSuggestionListChanged: {
            suggestionRepeater.model = suggestionList
        }
    }

    Grid {
        id: grid
        width: parent.width
        columns: root.isPortrait ? 1 : 2
        columnSpacing: Theme.paddingMedium

        Repeater {
            id: suggestionRepeater
            model: engine.suggestionList

            BackgroundItem {
                width: grid.width / grid.columns -
                       (grid.columns - 1) * grid.columnSpacing
                Label {
                    x: Theme.paddingSmall
                    height: parent.height
                    width: parent.width - 2 * x
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    maximumLineCount: 2
                    elide: Text.ElideLeft
                    text: suggestionRepeater.model[index]
                }

                onClicked: {
                    Log.debug("Suggestion selected: " + suggestionRepeater.model[index])
                    parent.forceActiveFocus()
                    root.selected(suggestionRepeater.model[index])
                }
            }
        } // Repeater
    } // Column
}
