pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 400
    implicitHeight: 300

    property int currentSection: 0  // 0: Network, 1: Bluetooth, 2: Mixer, 3: Effects

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Sidebar container with background
        StyledRect {
            id: sidebarContainer
            variant: "common"
            Layout.preferredWidth: 200
            Layout.maximumWidth: 200
            Layout.fillHeight: true
            Layout.fillWidth: false

            Flickable {
                id: sidebarFlickable
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: sidebar.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Sliding highlight behind tabs
                StyledRect {
                    id: tabHighlight
                    variant: "focus"
                    width: parent.width
                    height: 40
                    radius: Styling.radius(-6)
                    z: 0

                    readonly property int tabHeight: 40
                    readonly property int tabSpacing: 4

                    x: 0
                    y: root.currentSection * (tabHeight + tabSpacing)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Column {
                    id: sidebar
                    width: parent.width
                    spacing: 4
                    z: 1

                    Repeater {
                        model: [
                            { icon: Icons.wifiHigh, label: "Network", section: 0 },
                            { icon: Icons.bluetooth, label: "Bluetooth", section: 1 },
                            { icon: Icons.faders, label: "Mixer", section: 2 },
                            { icon: Icons.waveform, label: "Effects", section: 3 }
                        ]

                        delegate: Button {
                            id: sidebarButton
                            required property var modelData
                            required property int index

                            width: sidebar.width
                            height: 40
                            flat: true
                            hoverEnabled: true

                            property bool isActive: root.currentSection === sidebarButton.modelData.section

                            background: Rectangle {
                                color: "transparent"
                            }

                            contentItem: Row {
                                spacing: 8

                                // Icon on the left
                                Text {
                                    id: iconText
                                    text: sidebarButton.modelData.icon
                                    font.family: Icons.font
                                    font.pixelSize: 20
                                    color: sidebarButton.isActive 
                                        ? Config.resolveColor(Config.theme.srOverPrimary.itemColor)
                                        : Config.resolveColor(Config.theme.srCommon.itemColor)
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 10

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                // Text
                                Text {
                                    text: sidebarButton.modelData.label
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: sidebarButton.isActive ? Font.Bold : Font.Normal
                                    color: sidebarButton.isActive 
                                        ? Config.resolveColor(Config.theme.srOverPrimary.itemColor)
                                        : Config.resolveColor(Config.theme.srCommon.itemColor)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation {
                                            duration: Config.animDuration
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            onClicked: root.currentSection = sidebarButton.modelData.section
                        }
                    }
                }

                // Scroll wheel navigation between sections
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        // If content is scrollable, let Flickable handle it
                        if (sidebarFlickable.contentHeight > sidebarFlickable.height) {
                            return;
                        }
                        // Otherwise, navigate sections
                        if (event.angleDelta.y > 0 && root.currentSection > 0) {
                            root.currentSection--;
                        } else if (event.angleDelta.y < 0 && root.currentSection < 3) {
                            root.currentSection++;
                        }
                    }
                }
            }
        }

        // Content area with animated transitions
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            property int previousSection: 0

            // Track section changes for animation direction
            onVisibleChanged: {
                if (visible) {
                    contentArea.previousSection = root.currentSection;
                }
            }

            Connections {
                target: root
                function onCurrentSectionChanged() {
                    contentArea.previousSection = root.currentSection;
                }
            }

            // WiFi Panel
            WifiPanel {
                id: wifiPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width, 480)
                visible: opacity > 0
                opacity: root.currentSection === 0 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 0 ? 0 : (root.currentSection > 0 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Bluetooth Panel
            BluetoothPanel {
                id: bluetoothPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width, 480)
                visible: opacity > 0
                opacity: root.currentSection === 1 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 1 ? 0 : (root.currentSection > 1 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Audio Mixer Panel
            AudioMixerPanel {
                id: audioPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width, 480)
                visible: opacity > 0
                opacity: root.currentSection === 2 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 2 ? 0 : (root.currentSection > 2 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // EasyEffects Panel
            EasyEffectsPanel {
                id: effectsPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width, 480)
                visible: opacity > 0
                opacity: root.currentSection === 3 ? 1 : 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    y: root.currentSection === 3 ? 0 : (root.currentSection > 3 ? -20 : 20)

                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
