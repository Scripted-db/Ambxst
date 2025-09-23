import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.config
import "./notification_utils.js" as NotificationUtils

ClippingRectangle {
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property real scale: 1
    property real size: 48 * scale
    property real materialIconScale: 0.57
    // property real materialIconScale: scale
    // property real appIconScale: 0.7
    property real appIconScale: scale
    property real smallAppIconScale: 0.4
    // property real smallAppIconScale: scale
    property real materialIconSize: size * materialIconScale
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale

    implicitWidth: size
    implicitHeight: size
    radius: Config.roundness > 8 ? Config.roundness - 8 : 0
    color: "transparent" // Light surface color

    Loader {
        id: materialSymbolLoader
        active: root.appIcon == ""
        anchors.fill: parent
        sourceComponent: Text {
            text: "🔔" // Icono de notificación simple como fallback
            anchors.fill: parent
            color: (root.urgency == NotificationUrgency.Critical) ? Colors.adapter.error : Colors.adapter.primary
            font.family: Config.theme.font
            font.pixelSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Loader {
        id: appIconLoader
        active: root.image == "" && root.appIcon != ""
        anchors.centerIn: parent
        sourceComponent: Image {
            id: appIconImage
            width: root.appIconSize
            height: root.appIconSize
            source: root.appIcon ? "image://icon/" + root.appIcon : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Loader {
        id: notifImageLoader
        active: root.image != ""
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: "transparent"

                Image {
                    id: notifImage
                    anchors.fill: parent
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }

            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: Image {
                    width: root.smallAppIconSize
                    height: root.smallAppIconSize
                    source: root.appIcon ? "image://icon/" + root.appIcon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }
        }
    }
}
