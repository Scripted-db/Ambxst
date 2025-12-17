pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.modules.globals
import qs.config

Scope {
    id: root
    
    property bool pinned: Config.dock?.pinnedOnStartup ?? false

    // Margin calculations
    readonly property int dockMargin: Config.dock?.margin ?? 8
    readonly property int hyprlandGapsOut: Config.hyprland?.gapsOut ?? 4
    readonly property bool isBottom: (Config.dock?.position ?? "bottom") === "bottom"
    // Side facing windows needs to subtract gapsOut to maintain visual consistency
    // But only if margin > 0, otherwise both sides are 0
    readonly property int windowSideMargin: dockMargin > 0 ? Math.max(0, dockMargin - hyprlandGapsOut) : 0
    readonly property int edgeSideMargin: dockMargin

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.dock?.screenList ?? [];
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        PanelWindow {
            id: dockWindow
            
            required property ShellScreen modelData
            screen: modelData
            visible: Config.dock?.enabled ?? false

            // Reveal logic: pinned, hover, no active window
            property bool reveal: root.pinned || 
                (Config.dock?.hoverToReveal && dockMouseArea.containsMouse) || 
                !ToplevelManager.activeToplevel?.activated

            anchors {
                bottom: root.isBottom
                top: !root.isBottom
                left: true
                right: true
            }

            // Total height includes dock + margins (window side + edge side)
            readonly property int totalMargin: root.windowSideMargin + root.edgeSideMargin
            readonly property int shadowSpace: 32
            
            // Reserve space when pinned (without shadow space to not push windows too far)
            exclusiveZone: root.pinned ? (Config.dock?.height ?? 56) + totalMargin : 0

            implicitWidth: dockContainer.implicitWidth + shadowSpace * 2
            implicitHeight: (Config.dock?.height ?? 56) + totalMargin + shadowSpace * 2
            
            WlrLayershell.namespace: "quickshell:dock"
            color: "transparent"

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                id: dockMouseArea
                // When hidden, only show a small hover region at the screen edge
                // When revealed, cover the full dock area (excluding shadow space on window side)
                height: dockWindow.reveal ? (Config.dock?.height ?? 56) + dockWindow.totalMargin + dockWindow.shadowSpace : (Config.dock?.hoverRegionHeight ?? 4)
                anchors {
                    // Always anchor to the screen edge
                    top: !root.isBottom ? parent.top : undefined
                    bottom: root.isBottom ? parent.bottom : undefined
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: dockContainer.implicitWidth + 20
                hoverEnabled: true

                Behavior on height {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                }

                // Dock container
                Item {
                    id: dockContainer
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        // Position based on dock position with correct margins
                        bottom: root.isBottom ? parent.bottom : undefined
                        top: !root.isBottom ? parent.top : undefined
                        // Edge margin (away from windows)
                        bottomMargin: root.isBottom ? root.edgeSideMargin : 0
                        topMargin: !root.isBottom ? root.edgeSideMargin : 0
                    }
                    
                    implicitWidth: dockBackground.implicitWidth
                    implicitHeight: Config.dock?.height ?? 56

                    // Animation for dock reveal
                    opacity: dockWindow.reveal ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                    }

                    // Slide animation
                    transform: Translate {
                        y: dockWindow.reveal ? 0 : (root.isBottom ? dockContainer.height + root.edgeSideMargin : -(dockContainer.height + root.edgeSideMargin))
                        Behavior on y {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                        }
                    }

                    // Background
                    StyledRect {
                        id: dockBackground
                        anchors.fill: parent
                        variant: "bg"
                        enableShadow: true
                        radius: Styling.radius(4)
                        
                        implicitWidth: dockRow.implicitWidth + 16
                        implicitHeight: parent.height
                    }

                    // Main row with apps
                    RowLayout {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: Config.dock?.spacing ?? 4
                        
                        // Pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Button {
                                id: pinButton
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: root.pinned ? 
                                        Colors.primary : 
                                        (pinButton.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent")
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.pin
                                    font.family: Icons.font
                                    font.pixelSize: 16
                                    color: root.pinned ? Colors.overPrimary : Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    rotation: root.pinned ? 0 : 45
                                    Behavior on rotation {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                onClicked: root.pinned = !root.pinned
                                
                                StyledToolTip {
                                    show: pinButton.hovered
                                    tooltipText: root.pinned ? "Unpin dock" : "Pin dock"
                                }
                            }
                        }

                        // Separator after pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Separator {
                                vert: true
                                implicitHeight: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // App buttons
                        Repeater {
                            model: TaskbarApps.apps
                            
                            DockAppButton {
                                required property var modelData
                                appToplevel: modelData
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // Separator before overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Separator {
                                vert: true
                                implicitHeight: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // Overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Button {
                                id: overviewButton
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: overviewButton.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent"
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.apps
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    // Toggle overview on the current screen
                                    let visibilities = Visibilities.getForScreen(dockWindow.screen.name);
                                    if (visibilities) {
                                        visibilities.overview = !visibilities.overview;
                                    }
                                }
                                
                                StyledToolTip {
                                    show: overviewButton.hovered
                                    tooltipText: "Overview"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
