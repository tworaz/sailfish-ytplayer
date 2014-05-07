import QtQuick 2.0
import Sailfish.Silica 1.0

/* Fancy label for key-value pairs.
 */
Label {
    property string key: ""
    property string value: ""
    property color highlightColor: Theme.highlightColor
    property int pixelSize: Theme.fontSizeSmall

    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    font.pixelSize: pixelSize
    text: "<font color=\"" + highlightColor + "\">" +
          key + "</font> " + value
}
