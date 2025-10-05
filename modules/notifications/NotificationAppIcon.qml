import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.config

ClippingRectangle {
    id: root
    property var appIcon: ""
    property var summary: ""
    property var urgency: NotificationUrgency.Normal
    property var image: ""
    property real scale: 1
    property real size: 48 * scale
    property real appIconScale: scale
    property real smallAppIconScale: 0.4
    property real appIconSize: size * appIconScale
    property real smallAppIconSize: size * smallAppIconScale

    implicitWidth: size
    implicitHeight: size
    radius: Config.roundness > 8 ? Config.roundness - 8 : 0
    color: "transparent"

    // Solo mostrar appIcon si existe
    Loader {
        id: appIconLoader
        active: root.image == "" && root.appIcon != ""
        anchors.fill: parent
        sourceComponent: Image {
            id: appIconImage
            anchors.fill: parent
            source: root.appIcon ? "image://icon/" + root.appIcon : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
    }

    // Mostrar imagen de notificación si existe
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

            // App icon pequeño superpuesto si hay imagen
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: root.smallAppIconSize
                height: root.smallAppIconSize
                sourceComponent: ClippingRectangle {
                    radius: root.radius * root.smallAppIconScale
                    Image {
                        anchors.fill: parent
                        source: root.appIcon ? "image://icon/" + root.appIcon : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }
                }
            }
        }
    }
}
