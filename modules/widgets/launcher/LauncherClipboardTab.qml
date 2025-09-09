import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

Rectangle {
    id: root

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 16

        // Placeholder content
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignCenter

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: Icons.clipboard
                    font.family: Icons.font
                    font.pixelSize: 48
                    color: Colors.adapter.overBackground
                    opacity: 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Clipboard Manager"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 4
                    font.weight: Font.Bold
                    color: Colors.adapter.overBackground
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Coming soon..."
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize
                    color: Colors.adapter.overBackground
                    opacity: 0.7
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}