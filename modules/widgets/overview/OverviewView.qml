import QtQuick
import qs.modules.widgets.overview
import qs.modules.services
import qs.config

Item {
    property var currentScreen

    implicitWidth: overviewItem.implicitWidth
    implicitHeight: overviewItem.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Overview {
        id: overviewItem
        anchors.centerIn: parent
        currentScreen: parent.currentScreen

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Visibilities.setActiveModule("");
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                forceActiveFocus();
            });
        }
    }
}