import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.globals
import qs.modules.theme
import qs.modules.widgets.launcher
import qs.modules.widgets.defaultview
import qs.modules.widgets.overview
import qs.modules.widgets.dashboard
import qs.modules.widgets.powermenu
import qs.modules.services
import qs.config

PanelWindow {
    id: notchPanel

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Get this screen's visibility state
    readonly property var screenVisibilities: Visibilities.getForScreen(screen.name)
    readonly property bool isScreenFocused: Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === screen.name

    HyprlandFocusGrab {
        id: focusGrab
        windows: {
            let windowList = [notchPanel];
            // Agregar la barra de esta pantalla al focus grab cuando el notch esté abierto
            let barPanel = Visibilities.panels[screen.name];
            if (barPanel && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu)) {
                windowList.push(barPanel);
            }
            return windowList;
        }
        active: screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu

        onCleared: {
            if (screenVisibilities.launcher) {
                GlobalStates.clearLauncherState();
            }
            Visibilities.setActiveModule("");
        }
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    mask: Region {
        item: notchContainer
    }

    Component.onCompleted: {
        Visibilities.registerPanel(screen.name, notchPanel);
    }

    Component.onDestruction: {
        Visibilities.unregisterPanel(screen.name);
    }

    // Default view component - user@host text
    Component {
        id: defaultViewComponent
        DefaultView {}
    }

    // Launcher view component
    Component {
        id: launcherViewComponent
        LauncherView {}
    }

    // Overview view component
    Component {
        id: overviewViewComponent
        OverviewView {
            currentScreen: notchPanel.screen
        }
    }

    // Dashboard view component
    Component {
        id: dashboardViewComponent
        DashboardView {}
    }

    // Power menu view component
    Component {
        id: powermenuViewComponent
        PowerMenuView {}
    }

    // Center notch
    Notch {
        id: notchContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        anchors.topMargin: Config.notchTheme === "default" ? 0 : (Config.notchTheme === "island" ? 4 : 0)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: Config.theme.shadowOpacity > 0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowBlur: screenVisibilities && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu) ? 2.0 : 1.0
            shadowColor: Colors.adapter.shadow
            shadowOpacity: screenVisibilities && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu) ? Math.min(Config.theme.shadowOpacity + 0.25, 1.0) : Config.theme.shadowOpacity

            Behavior on shadowBlur {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: screenVisibilities && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu) ? Easing.OutBack : Easing.OutQuart
                }
            }

            Behavior on shadowOpacity {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: screenVisibilities && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu) ? Easing.OutBack : Easing.OutQuart
                }
            }
        }

        defaultViewComponent: defaultViewComponent
        launcherViewComponent: launcherViewComponent
        dashboardViewComponent: dashboardViewComponent
        overviewViewComponent: overviewViewComponent
        powermenuViewComponent: powermenuViewComponent
        visibilities: screenVisibilities

        // Handle global keyboard events
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape && (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu)) {
                if (screenVisibilities.launcher) {
                    GlobalStates.clearLauncherState();
                }
                Visibilities.setActiveModule("");
                event.accepted = true;
            }
        }
    }

    // Listen for launcher, dashboard, overview and powermenu state changes
    Connections {
        target: screenVisibilities
        function onLauncherChanged() {
            if (screenVisibilities.launcher) {
                notchContainer.stackView.push(launcherViewComponent);
                Qt.callLater(() => {
                    // Additional focus to ensure search input gets focus
                    let currentItem = notchContainer.stackView.currentItem;
                    if (currentItem && currentItem.children[0] && currentItem.children[0].focusSearchInput) {
                        currentItem.children[0].focusSearchInput();
                    }
                });
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.pop();
                }
            }
        }

        function onDashboardChanged() {
            if (screenVisibilities.dashboard) {
                notchContainer.stackView.push(dashboardViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.pop();
                }
            }
        }

        function onOverviewChanged() {
            if (screenVisibilities.overview) {
                notchContainer.stackView.push(overviewViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.pop();
                }
            }
        }

        function onPowermenuChanged() {
            if (screenVisibilities.powermenu) {
                notchContainer.stackView.push(powermenuViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.pop();
                }
            }
        }
    }
}
