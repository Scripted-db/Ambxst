import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

Item {
    implicitWidth: 258
    implicitHeight: 40

    Process {
        id: hostnameProcess
        command: ["hostname"]
        running: true

        stdout: StdioCollector {
            id: hostnameCollector
            waitForEnd: true

            onStreamFinished: {}
        }
    }

    Row {
        anchors.centerIn: parent
        width: parent.implicitWidth - 24
        height: parent.height
        spacing: 8

        Item {
            width: 24
            height: parent.height

            ClippingRectangle {
                id: avatarClip
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: Config.roundness
                clip: true

                Image {
                    anchors.fill: parent
                    source: `file://${Quickshell.env("HOME")}/.face.icon`
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }

        MouseArea {
            id: userHostArea
            width: userHostText.implicitWidth
            height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (Visibilities.currentActiveModule === "dashboard") {
                    Visibilities.setActiveModule("overview");
                } else if (Visibilities.currentActiveModule === "overview") {
                    GlobalStates.launcherCurrentTab = 0;
                    Visibilities.setActiveModule("launcher");
                } else if (Visibilities.currentActiveModule === "launcher") {
                    Visibilities.setActiveModule("");
                } else {
                    GlobalStates.dashboardCurrentTab = 0;
                    Visibilities.setActiveModule("dashboard");
                }
            }

            Text {
                id: userHostText
                anchors.centerIn: parent
                text: `${Quickshell.env("USER")}@${hostnameCollector.text.trim()}`
                color: userHostArea.pressed ? Colors.overBackground : (userHostArea.containsMouse ? Colors.primary : Colors.overBackground)
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDuration / 2
                    }
                }
            }
        }

        Item {
            width: parent.width - avatarClip.width - userHostArea.width - 16
            height: parent.height

            Item {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24

                Text {
                    anchors.centerIn: parent
                    text: Icons.bell
                    font.family: Icons.font
                    font.pixelSize: 20
                    color: Colors.overBackground
                }

                Rectangle {
                    visible: Notifications.historyList.length > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 8
                    height: 8
                    radius: 4
                    color: Colors.error
                }
            }
        }
    }
}
