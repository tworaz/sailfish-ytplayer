// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: root
    opacity: 0.0
    radius: Theme.paddingMedium
    width: image.width + 2 * Theme.paddingMedium
    height: image.height + 2 * Theme.paddingMedium
    color: Theme.secondaryHighlightColor

    property alias source: image.source

    function trigger() {
        animation.start()
    }

    Image {
        id: image
        anchors.centerIn: parent
    }

    ParallelAnimation {
        id: animation
        PropertyAnimation {
            target: root
            property: "opacity";
            from: 1.0;
            to: 0.0;
            duration: kLongAnimationDuration
        }
        PropertyAnimation {
            target: root
            property: "scale";
            from: 1.0;
            to: 2.0;
            duration: kLongAnimationDuration
        }
    }
}
