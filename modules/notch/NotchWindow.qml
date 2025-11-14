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
import qs.modules.components
import qs.config
import "./NotchNotificationView.qml"

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

    // Check if the bar for this screen is vertical
    readonly property bool isBarVertical: {
        const barPanel = Visibilities.panels[screen.name];
        if (barPanel && barPanel.position) {
            return barPanel.position === "left" || barPanel.position === "right";
        }
        return false;
    }

    // Notch state properties
    readonly property bool screenNotchOpen: screenVisibilities ? (screenVisibilities.launcher || screenVisibilities.dashboard || screenVisibilities.overview || screenVisibilities.powermenu) : false
    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0

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
        active: notchPanel.screenNotchOpen

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
        item: notchRegionContainer
    }

    Component.onCompleted: {
        Visibilities.registerPanel(screen.name, notchPanel);
        Visibilities.registerNotch(screen.name, notchContainer);
    }

    Component.onDestruction: {
        Visibilities.unregisterPanel(screen.name);
        Visibilities.unregisterNotch(screen.name);
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

    // Notification view component
    Component {
        id: notificationViewComponent
        NotchNotificationView {}
    }

    Item {
        id: notchRegionContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: Math.max(notchContainer.width, notificationPopupContainer.visible ? notificationPopupContainer.width : 0)
        height: notchContainer.height + (notificationPopupContainer.visible ? notificationPopupContainer.height + notificationPopupContainer.anchors.topMargin : 0)

        // Center notch
        Notch {
            id: notchContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

             anchors.topMargin: (Config.notchTheme === "default" ? 0 : (Config.notchTheme === "island" ? 4 : 0))

            layer.enabled: true
            layer.effect: Shadow {}

            defaultViewComponent: defaultViewComponent
            launcherViewComponent: launcherViewComponent
            dashboardViewComponent: dashboardViewComponent
            overviewViewComponent: overviewViewComponent
            powermenuViewComponent: powermenuViewComponent
            notificationViewComponent: notificationViewComponent
            visibilities: screenVisibilities

            // Handle global keyboard events
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape && notchPanel.screenNotchOpen) {
                    if (screenVisibilities.launcher) {
                        GlobalStates.clearLauncherState();
                    }
                    Visibilities.setActiveModule("");
                    event.accepted = true;
                }
            }
        }

        // Popup de notificaciones debajo del notch
        BgRect {
            id: notificationPopupContainer
            anchors.top: notchContainer.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4
            width: Math.round(popupHovered ? 420 + 48 : 320 + 48)
            height: shouldShowNotificationPopup ? (popupHovered ? notificationPopup.implicitHeight + 48 : notificationPopup.implicitHeight + 32) : 0
            clip: false
            visible: height > 0
            z: 999
            radius: Config.roundness > 0 ? Config.roundness + 20 : 0

            layer.enabled: true
            layer.effect: Shadow {}

            property bool popupHovered: false

            readonly property bool shouldShowNotificationPopup: {
                // Mostrar solo si hay notificaciones y el notch está expandido
                if (!notchPanel.hasActiveNotifications || !notchPanel.screenNotchOpen) return false;

                // NO mostrar si estamos en la pestaña de widgets del dashboard (tab 0)
                if (screenVisibilities.dashboard) {
                    return GlobalStates.dashboardCurrentTab !== 0;
                }

                return true;
            }

            Behavior on width {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            Behavior on height {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            HoverHandler {
                id: popupHoverHandler
                enabled: notificationPopupContainer.shouldShowNotificationPopup

                onHoveredChanged: {
                    notificationPopupContainer.popupHovered = hovered;
                }
            }

            NotchNotificationView {
                id: notificationPopup
                anchors.fill: parent
                anchors.margins: 16
                opacity: notificationPopupContainer.shouldShowNotificationPopup ? 1 : 0
                notchHovered: notificationPopupContainer.popupHovered

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
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
                    let currentItem = notchContainer.stackView.currentItem;
                    if (currentItem && currentItem.focusSearchInput) {
                        currentItem.focusSearchInput();
                    }
                });
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.replace(defaultViewComponent);
                    notchContainer.isShowingDefault = true;
                    notchContainer.isShowingNotifications = false;
                }
            }
        }

        function onDashboardChanged() {
            if (screenVisibilities.dashboard) {
                notchContainer.stackView.push(dashboardViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.replace(defaultViewComponent);
                    notchContainer.isShowingDefault = true;
                    notchContainer.isShowingNotifications = false;
                }
            }
        }

        function onOverviewChanged() {
            if (screenVisibilities.overview) {
                notchContainer.stackView.push(overviewViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.replace(defaultViewComponent);
                    notchContainer.isShowingDefault = true;
                    notchContainer.isShowingNotifications = false;
                }
            }
        }

        function onPowermenuChanged() {
            if (screenVisibilities.powermenu) {
                notchContainer.stackView.push(powermenuViewComponent);
            } else {
                if (notchContainer.stackView.depth > 1) {
                    notchContainer.stackView.replace(defaultViewComponent);
                    notchContainer.isShowingDefault = true;
                    notchContainer.isShowingNotifications = false;
                }
            }
        }
    }
}
