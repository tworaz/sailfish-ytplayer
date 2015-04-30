// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0

Image {
    id: root
    opacity: 0.0

    function trigger() {
        animation.start()
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
