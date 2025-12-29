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
    // Map dock position for integrated: "bottom"/"top" should be "center" for integrated dock
    // In vertical orientation, "center" falls back to "left" (start) to avoid layout issues
    readonly property string integratedDockPosition: {
        const pos = Config.dock?.position ?? "center";
        // For integrated, "bottom" and "top" don't make sense - map to "center"
        let mappedPos = (pos === "bottom" || pos === "top") ? "center" : pos;
        // In vertical orientation, center is not supported - fallback to "left" (start)
        if (panel.orientation === "vertical" && mappedPos === "center") {
            return "left";
        }
        return mappedPos;
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

            PresetsButton {
                id: presetsButton
            }

            RowLayout {
                id: leftSection
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 4

                ClippingRectangle {
                    id: leftRect
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: "transparent"
                    radius: Styling.radius(0)
                    layer.enabled: Config.showBackground
                    layer.effect: Shadow {}

                    Flickable {
                        id: leftFlickable
                        width: parent.width
                        height: parent.height
                        anchors.left: parent.left
                        contentWidth: leftContent.width
                        contentHeight: 36
                        flickableDirection: Flickable.HorizontalFlick
                        clip: true
                        pressDelay: 100

                        RowLayout {
                            id: leftContent
                            spacing: 4

                            RowLayout {
                                id: leftWidgets
                                spacing: 4

                                Workspaces {
                                    orientation: panel.orientation
                                    bar: QtObject {
                                        property var screen: panel.screen
                                    }
                                    layer.enabled: false
                                }
                                LayoutSelectorButton {
                                    id: layoutSelectorButton
                                    bar: panel
                                    layerEnabled: false
                                }
                                // Integrated dock - left position (after layout selector)
                                IntegratedDock {
                                    id: integratedDockLeft
                                    bar: panel
                                    orientation: "horizontal"
                                    visible: panel.integratedDockEnabled && panel.integratedDockPosition === "left"
                                    layer.enabled: false
                                }
                            }

                            Item {
                                Layout.preferredWidth: Math.max(0, leftRect.width - leftWidgets.width - 4)
                            }
                        }
                    }
                }
            }

            // Espaciador sincronizado con el ancho del notch (oculto cuando dock integrated está activo)
            Item {
                visible: !panel.integratedDockEnabled
                Layout.preferredWidth: horizontalLayout.notchContainer ? horizontalLayout.notchContainer.implicitWidth - 40 : 0
                Layout.fillHeight: true
            }

            // Integrated dock - center position
            IntegratedDock {
                id: integratedDockCenter
                bar: panel
                orientation: "horizontal"
                visible: panel.integratedDockEnabled && panel.integratedDockPosition === "center"
                layer.enabled: Config.showBackground
                layer.effect: Shadow {}
            }

            RowLayout {
                id: rightSection
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 4

                ClippingRectangle {
                    id: rightRect
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: "transparent"
                    radius: Styling.radius(0)
                    layer.enabled: Config.showBackground
                    layer.effect: Shadow {}

                    Flickable {
                        id: rightFlickable
                        width: parent.width
                        height: parent.height
                        anchors.right: parent.right
                        contentWidth: rightContent.width
                        contentHeight: 36
                        contentX: Math.max(0, rightContent.width - width)
                        flickableDirection: Flickable.HorizontalFlick
                        clip: true
                        pressDelay: 100

                        RowLayout {
                            id: rightContent
                            spacing: 4

                            Item {
                                Layout.preferredWidth: Math.max(0, rightRect.width - rightWidgets.width - 4)
                            }

                            RowLayout {
                                id: rightWidgets
                                spacing: 4

                                // Integrated dock - right position (before power profile)
                                IntegratedDock {
                                    id: integratedDockRight
                                    bar: panel
                                    orientation: "horizontal"
                                    visible: panel.integratedDockEnabled && panel.integratedDockPosition === "right"
                                    layer.enabled: false
                                }

                                Bar.BatteryIndicator {
                                    id: batteryIndicator
                                    bar: panel
                                    layerEnabled: false
                                }

                                ToolsButton {
                                    id: toolsButton
                                }

                                ControlsButton {
                                    id: controlsButton
                                    bar: panel
                                    layerEnabled: false
                                }
                            }
                        }
                    }
                }

                SysTray {
                    bar: panel
                    layer.enabled: Config.showBackground
                }

                Clock {
                    id: clockComponent
                    bar: panel
                    layer.enabled: Config.showBackground
                }
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

            ColumnLayout {
                id: topSection
                spacing: 4

                ClippingRectangle {
                    id: topRect
                    Layout.preferredHeight: topWidgets.height
                    Layout.preferredWidth: 36
                    color: "transparent"
                    radius: Styling.radius(0)
                    layer.enabled: Config.showBackground
                    layer.effect: Shadow {}

                    ColumnLayout {
                        id: topWidgets
                        spacing: 4

                        Workspaces {
                            orientation: panel.orientation
                            bar: QtObject {
                                property var screen: panel.screen
                            }
                            layer.enabled: false
                        }
                        LayoutSelectorButton {
                            id: layoutSelectorButtonVert
                            bar: panel
                            layerEnabled: false
                        }
                        // Integrated dock - left/top position (after layout selector)
                        IntegratedDock {
                            id: integratedDockTop
                            bar: panel
                            orientation: "vertical"
                            visible: panel.integratedDockEnabled && panel.integratedDockPosition === "left"
                            layer.enabled: false
                        }
                    }
                }
            }

            ColumnLayout {
                id: bottomSection
                Layout.fillHeight: true
                spacing: 4

                ClippingRectangle {
                    id: bottomRect
                    Layout.fillHeight: true
                    Layout.preferredWidth: 36
                    color: "transparent"
                    radius: Styling.radius(0)
                    layer.enabled: Config.showBackground
                    layer.effect: Shadow {}

                    Flickable {
                        id: bottomFlickable
                        width: parent.width
                        height: parent.height
                        anchors.bottom: parent.bottom
                        contentWidth: 36
                        contentHeight: bottomContent.height
                        contentY: Math.max(0, bottomContent.height - height)
                        flickableDirection: Flickable.VerticalFlick
                        clip: true
                        pressDelay: 100

                        ColumnLayout {
                            id: bottomContent
                            spacing: 4

                            Item {
                                Layout.preferredHeight: Math.max(0, bottomRect.height - bottomWidgets.height - 4)
                            }

                            ColumnLayout {
                                id: bottomWidgets
                                spacing: 4

                                // Integrated dock - right/bottom position (before power profile)
                                IntegratedDock {
                                    id: integratedDockBottomInner
                                    bar: panel
                                    orientation: "vertical"
                                    visible: panel.integratedDockEnabled && panel.integratedDockPosition === "right"
                                    layer.enabled: false
                                }

                                Bar.BatteryIndicator {
                                    id: batteryIndicatorVert
                                    bar: panel
                                    layerEnabled: false
                                }

                                ToolsButton {
                                    id: toolsButtonVert
                                }

                                ControlsButton {
                                    id: controlsButtonVert
                                    bar: panel
                                    layerEnabled: false
                                }
                            }
                        }
                    }
                }

                SysTray {
                    bar: panel
                    layer.enabled: Config.showBackground
                }

                Clock {
                    id: clockComponentVert
                    bar: panel
                    layer.enabled: Config.showBackground
                }
            }

            PowerButton {
                id: powerButtonVert
                Layout.preferredHeight: 36
            }
        }
    }
}
