import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.config

Item {
    id: root
    property var actions: []
    property bool showWhen: true
    property var notificationObject: null
    property int urgency: NotificationUrgency.Normal

    Layout.fillWidth: true
    implicitHeight: showWhen && actions.length > 0 ? 32 : 0
    height: implicitHeight
    clip: true

    RowLayout {
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: actions

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                text: modelData.text
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                hoverEnabled: true

                background: Rectangle {
                    color: root.urgency == NotificationUrgency.Critical ? Colors.criticalRed : (parent.pressed ? Colors.primary : (parent.hovered ? Colors.surfaceBright : Colors.surface))
                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: root.urgency == NotificationUrgency.Critical ? Colors.shadow : (parent.pressed ? Colors.overPrimary : (parent.hovered ? Colors.primary : Colors.overBackground))
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration
                        }
                    }
                }

                onClicked: {
                    if (root.notificationObject) {
                        Notifications.attemptInvokeAction(root.notificationObject.id, modelData.identifier);
                    }
                }
            }
        }
    }
}
