import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.modules.bar.workspaces
import qs.modules.theme
import qs.modules.bar.clock
import qs.modules.bar.systray
import qs.modules.widgets.overview
import qs.modules.widgets.dashboard
import qs.modules.widgets.powermenu
import qs.modules.widgets.presets
import qs.modules.corners
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.modules.bar
import qs.config
import "." as Bar

PanelWindow {
    id: panel

    property string position: ["top", "bottom", "left", "right"].includes(Config.bar.position) ? Config.bar.position : "top"
    property string orientation: position === "left" || position === "right" ? "vertical" : "horizontal"

    // Integrated dock configuration
    readonly property bool integratedDockEnabled: (Config.dock?.enabled ?? false) && (Config.dock?.theme ?? "default") === "integrated"
    // Map dock position for integrated based on orientation
    readonly property string integratedDockPosition: {
        const pos = Config.dock?.position ?? "center";
        
        if (panel.orientation === "horizontal") {
            if (pos === "left" || pos === "start") return "start";
            if (pos === "right" || pos === "end") return "end";
            return "center";
        }
        
        // Vertical always falls back to center (or default logic) for now
        // to match the reverted behavior where it ignores start/end.
        return "center";
    }

    anchors {
        top: position !== "bottom"
        bottom: position !== "top"
        left: position !== "right"
        right: position !== "left"
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top

    exclusiveZone: Config.showBackground ? 44 : 40
    exclusionMode: ExclusionMode.Ignore

    // Altura implícita incluye espacio extra para animaciones / futuros elementos.
    implicitHeight: Screen.height

    // La máscara sigue a la barra principal para mantener correcta interacción en ambas posiciones.
    mask: Region {
        item: bar
    }

    Component.onCompleted: {
        Visibilities.registerBar(screen.name, bar);
        Visibilities.registerPanel(screen.name, panel);
    }

    Component.onDestruction: {
        Visibilities.unregisterBar(screen.name);
        Visibilities.unregisterPanel(screen.name);
    }

    Item {
        id: bar

        layer.enabled: true
        layer.effect: Shadow {}

        states: [
            State {
                name: "top"
                when: panel.position === "top"
                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: undefined
                }
                PropertyChanges {
                    target: bar
                    width: undefined
                    height: 44
                }
            },
            State {
                name: "bottom"
                when: panel.position === "bottom"
                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: undefined
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: undefined
                    height: 44
                }
            },
            State {
                name: "left"
                when: panel.position === "left"
                AnchorChanges {
                    target: bar
                    anchors.left: parent.left
                    anchors.right: undefined
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: 44
                    height: undefined
                }
            },
            State {
                name: "right"
                when: panel.position === "right"
                AnchorChanges {
                    target: bar
                    anchors.left: undefined
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
                PropertyChanges {
                    target: bar
                    width: 44
                    height: undefined
                }
            }
        ]

        BarBg {
            id: barBg
            anchors.fill: parent
            position: panel.position
        }


        RowLayout {
            id: horizontalLayout
            visible: panel.orientation === "horizontal"
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            // Obtener referencia al notch de esta pantalla
            readonly property var notchContainer: Visibilities.getNotchForScreen(panel.screen.name)

            LauncherButton {
                id: launcherButton
            }

            Workspaces {
                orientation: panel.orientation
                bar: QtObject {
                    property var screen: panel.screen
                }
            }

            LayoutSelectorButton {
                id: layoutSelectorButton
                bar: panel
                layerEnabled: Config.showBackground
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: panel.orientation === "horizontal" && integratedDockEnabled

                Bar.IntegratedDock {
                    bar: panel
                    orientation: panel.orientation
                    anchors.verticalCenter: parent.verticalCenter
                    
                    // Calculate target position based on config
                    property real targetX: {
                        if (integratedDockPosition === "start") return 0;
                        if (integratedDockPosition === "end") return parent.width - width;
                        
                        // Center logic (reactive using parent.x + margin offset)
                        // RowLayout has anchors.margins: 4, so offset is 4
                        return (bar.width - width) / 2 - (parent.x + 4);
                    }
                    
                    // Clamp the x position so it never leaves the container (preventing overlap)
                    x: Math.max(0, Math.min(parent.width - width, targetX))
                    
                    width: Math.min(implicitWidth, parent.width)
                    height: implicitHeight
                }
            }

            Item {
                Layout.fillWidth: true
                visible: !(panel.orientation === "horizontal" && integratedDockEnabled)
            }

            PresetsButton {
                id: presetsButton
            }

            ToolsButton {
                id: toolsButton
            }

            SysTray {
                bar: panel
                layer.enabled: Config.showBackground
            }

            ControlsButton {
                id: controlsButton
                bar: panel
                layerEnabled: Config.showBackground
            }

            Bar.BatteryIndicator {
                id: batteryIndicator
                bar: panel
                layerEnabled: Config.showBackground
            }

            Clock {
                id: clockComponent
                bar: panel
                layerEnabled: Config.showBackground
            }

            PowerButton {
                id: powerButton
            }
        }

        ColumnLayout {
            id: verticalLayout
            visible: panel.orientation === "vertical"
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            LauncherButton {
                id: launcherButtonVert
                Layout.preferredHeight: 36
            }

            SysTray {
                bar: panel
                layer.enabled: Config.showBackground
            }

            ControlsButton {
                id: controlsButtonVert
                bar: panel
                layerEnabled: Config.showBackground
            }

            // Center Group Container
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Calculate target position to be absolutely centered in the bar (vertically)
                    property real targetY: {
                        if (!parent || !bar) return 0;
                        var parentPos = parent.mapToItem(bar, 0, 0);
                        return (bar.height - height) / 2 - parentPos.y;
                    }

                    // Clamp y position
                    y: Math.max(0, Math.min(parent.height - height, targetY))

                    height: Math.min(parent.height, implicitHeight)
                    width: parent.width
                    spacing: 4

                    LayoutSelectorButton {
                        id: layoutSelectorButtonVert
                        bar: panel
                        layerEnabled: Config.showBackground
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Workspaces {
                        id: workspacesVert
                        orientation: panel.orientation
                        bar: QtObject {
                            property var screen: panel.screen
                        }
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Bar.IntegratedDock {
                        bar: panel
                        orientation: panel.orientation
                        visible: integratedDockEnabled
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    ToolsButton {
                        id: toolsButtonVert
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            PresetsButton {
                id: presetsButtonVert
            }

            Bar.BatteryIndicator {
                id: batteryIndicatorVert
                bar: panel
                layerEnabled: Config.showBackground
            }

            Clock {
                id: clockComponentVert
                bar: panel
                layerEnabled: Config.showBackground
            }

            PowerButton {
                id: powerButtonVert
                Layout.preferredHeight: 36
            }
        }
    }
}
