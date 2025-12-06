import QtQuick
import qs.config
import qs.modules.theme

Rectangle {
    property bool vert: false

    color: Colors.overBackground
    opacity: 0.1
    radius: Styling.radius(0)

    width: vert ? 20 : 2
    height: vert ? 2 : 20
}
