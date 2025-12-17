pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Button {
    id: root

    required property var appToplevel
    property int lastFocused: -1
    property real iconSize: Config.dock?.iconSize ?? 40
    property real countDotWidth: 10
    property real countDotHeight: 4

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    readonly property var desktopEntry: isSeparator ? null : DesktopEntries.heuristicLookup(appToplevel.appId)
    readonly property bool appIsActive: !isSeparator && appToplevel.toplevels.some(t => t.activated === true)
    readonly property bool appIsRunning: !isSeparator && appToplevel.toplevels.length > 0

    enabled: !isSeparator
    implicitWidth: isSeparator ? 2 : iconSize + 8
    implicitHeight: iconSize + 16
    
    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    background: Rectangle {
        radius: Styling.radius(-2)
        color: root.isSeparator ? "transparent" : (root.pressed ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3) : (root.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent"))
        
        Behavior on color {
            enabled: Config.animDuration > 0
            ColorAnimation { duration: Config.animDuration / 2 }
        }
    }

    contentItem: Item {
        // Separator
        Loader {
            active: root.isSeparator
            anchors.centerIn: parent
            sourceComponent: Separator {
                vert: true
                implicitHeight: root.iconSize * 0.6
            }
        }

        // App icon and indicators
        Loader {
            active: !root.isSeparator
            anchors.fill: parent
            sourceComponent: Item {
                anchors.fill: parent

                // App icon
                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -4
                    source: {
                        if (root.desktopEntry && root.desktopEntry.icon) {
                            return Quickshell.iconPath(root.desktopEntry.icon, "application-x-executable");
                        }
                        return Quickshell.iconPath(AppSearch.guessIcon(root.appToplevel.appId), "application-x-executable");
                    }
                    implicitSize: root.iconSize

                    // Monochrome effect
                    layer.enabled: Config.dock?.monochromeIcons ?? false
                    layer.effect: MultiEffect {
                        saturation: 0
                        brightness: 0.1
                        colorization: 0.8
                        colorizationColor: Colors.primary
                    }
                }

                // Running indicators
                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 3
                    visible: (Config.dock?.showRunningIndicators ?? true) && root.appIsRunning

                    Repeater {
                        model: Math.min(root.appToplevel.toplevels.length, 3)
                        delegate: Rectangle {
                            required property int index
                            width: root.appToplevel.toplevels.length <= 3 ? root.countDotWidth : root.countDotHeight
                            height: root.countDotHeight
                            radius: height / 2
                            color: root.appIsActive ? Colors.primary : Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.4)
                            
                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation { duration: Config.animDuration / 2 }
                            }
                        }
                    }
                }
            }
        }
    }

    // Left click: launch or cycle through windows
    onClicked: {
        if (isSeparator) return;
        
        if (appToplevel.toplevels.length === 0) {
            // Launch the app
            if (desktopEntry) {
                desktopEntry.execute();
            }
            return;
        }
        
        // Cycle through running windows
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length;
        appToplevel.toplevels[lastFocused].activate();
    }

    // Middle click: always launch new instance
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton
        
        onClicked: mouse => {
            if (root.isSeparator) return;
            
            if (mouse.button === Qt.MiddleButton) {
                // Launch new instance
                if (root.desktopEntry) {
                    root.desktopEntry.execute();
                }
            } else if (mouse.button === Qt.RightButton) {
                // Toggle pin
                TaskbarApps.togglePin(root.appToplevel.appId);
            }
        }
    }

    // Tooltip
    StyledToolTip {
        show: root.hovered && !root.isSeparator
        tooltipText: root.desktopEntry?.name ?? root.appToplevel.appId
    }
}
