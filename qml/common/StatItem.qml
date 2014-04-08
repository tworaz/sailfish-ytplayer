import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property alias text: label.text
    property alias image: image.source
    property alias imageRotation: image.rotation

    spacing: Theme.paddingSmall

    Image {
        id: image
        anchors.verticalCenter: parent.verticalCenter
    }

    Label {
        id: label
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        anchors.verticalCenter: parent.verticalCenter
    }
}
