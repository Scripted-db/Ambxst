import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.config
import "./NotificationAnimation.qml"
import "./notification_utils.js" as NotificationUtils

Item {
    id: root
    property var notificationObject
    property bool expanded: false
    property real fontSize: 12
    property real padding: 8

    property real dragConfirmThreshold: 70
    property real dismissOvershoot: 20
    property var qmlParent: root?.parent?.parent
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - (index ?? 0))
    property real xOffset: dragIndexDiff == 0 ? Math.max(0, parentDragDistance) : parentDragDistance > dragConfirmThreshold ? 0 : dragIndexDiff == 1 ? Math.max(0, parentDragDistance * 0.3) : dragIndexDiff == 2 ? Math.max(0, parentDragDistance * 0.1) : 0

    signal destroyRequested

    implicitHeight: background.implicitHeight

    // Timer para actualizar el timestamp cada minuto
    Timer {
        id: timestampUpdateTimer
        interval: 60000 // 1 minuto
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            // Forzar actualización del binding del timestamp
            if (timestampText) {
                timestampText.text = NotificationUtils.getFriendlyNotifTimeString(root.notificationObject.time);
            }
        }
    }

    function processNotificationBody(body) {
        // Limpiar HTML básico y saltos de línea para vista simple
        return body.replace(/<[^>]*>/g, "").replace(/\n/g, " ");
    }

    function destroyWithAnimation() {
        if (root.qmlParent && root.qmlParent.resetDrag)
            root.qmlParent.resetDrag();

        background.anchors.leftMargin = background.anchors.leftMargin;
        notificationAnimation.startDestroy();
    }

    NotificationAnimation {
        id: notificationAnimation
        targetItem: background
        dismissOvershoot: root.dismissOvershoot
        parentWidth: root.width

        onDestroyFinished: {
            Notifications.discardNotification(notificationObject.id);
        }
    }

    MouseArea {
        id: dragManager
        anchors.fill: root
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool dragging: false
        property real dragDiffX: 0

        onPressed: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
        }

        function resetDrag() {
            dragging = false;
            dragDiffX = 0;
        }
    }

    Rectangle {
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: 8
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        color: (notificationObject.urgency == NotificationUrgency.Critical) ? Colors.adapter.error : Colors.surfaceContainerLow

        implicitHeight: contentColumn.implicitHeight + padding * 2

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 8

            // Row con app name, summary y timestamp
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    id: appNameText
                    font.family: Config.theme.font
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Colors.adapter.outline
                    text: root.notificationObject.appName || ""
                    visible: text.length > 0
                    elide: Text.ElideRight
                    Layout.maximumWidth: Math.max(60, parent.width * 0.25)
                }

                Text {
                    id: summaryText
                    Layout.fillWidth: true
                    font.family: Config.theme.font
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Colors.adapter.primary
                    elide: Text.ElideRight
                    text: root.notificationObject.summary || ""
                    visible: text.length > 0
                }

                Text {
                    id: timestampText
                    font.family: Config.theme.font
                    font.pixelSize: 11
                    color: Colors.adapter.overBackground
                    text: NotificationUtils.getFriendlyNotifTimeString(root.notificationObject.time)
                    visible: text.length > 0
                    // No elide para el timestamp
                }
            }

            // Contenido de la notificación
            Text {
                id: bodyText
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: root.fontSize
                color: Colors.adapter.overBackground
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: processNotificationBody(notificationObject.body || "")
                visible: text.length > 0
            }

            // Botones de acción si existen
            RowLayout {
                Layout.fillWidth: true
                visible: notificationObject.actions.length > 0

                Repeater {
                    model: notificationObject.actions
                    Button {
                        Layout.fillWidth: true
                        text: modelData.text
                        onClicked: {
                            Notifications.attemptInvokeAction(notificationObject.id, modelData.identifier);
                        }
                    }
                }
            }
        }
    }
}
