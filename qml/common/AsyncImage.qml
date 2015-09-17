// Copyright (c) 2015 Piotr Tworek. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.YTPlayer file.

import QtQuick 2.0
import Sailfish.Silica 1.0


Image {
    fillMode: Image.PreserveAspectCrop

    property alias indicatorSize: indicator.size

    BusyIndicator {
        id: indicator
        size: BusyIndicatorSize.Small
        anchors.centerIn: parent
        running: parent.status === Image.Loading
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.secondaryHighlightColor
        visible: status === Image.Error
        Label {
            anchors.fill: parent
            width: parent.width
            maximumLineCount: 1
            font.pixelSize: Theme.fontSizeExtraSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.HorizontalFit
            //: Label shown where video thumbnail is not valid, can't be loaded.
            //: Should be very short 8-10 characters max.
            //% "No image"
            text: qsTrId("ytplayer-label-broken-image")
            color: Theme.primaryColor
        }
    }
}
