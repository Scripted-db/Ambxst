import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Item {
    id: root

    required property ShellScreen screen

    // State properties for Bar and Dock
    property bool barEnabled: true
    property string barPosition: Config.bar?.position ?? "top"
    property bool barPinned: true
    property int barSize: 0
    property int barOuterMargin: 0
    property bool containBar: Config.bar?.containBar ?? false

    // Force update when any relevant bar state changes
    onBarEnabledChanged: updateAllZones();
    onBarPinnedChanged: updateAllZones();
    onBarSizeChanged: updateAllZones();
    onBarOuterMarginChanged: updateAllZones();
    onContainBarChanged: updateAllZones();
    
    onBarPositionChanged: {
        console.log("ReservationWindows: barPosition changed to", barPosition, "- updating all zones");
        updateAllZones();
    }

    Connections {
        target: Config
        function onBarReadyChanged() {
            console.log("ReservationWindows: Config.barReady changed to", Config.barReady, "- updating all zones");
            root.updateAllZones();
        }
    }

    // Reference the full border array first (helps QML detect changes)
    readonly property var borderData: Config.theme.srBg.border
    readonly property int borderWidth: borderData[1]

    // Watch for border changes and update zones
    onBorderWidthChanged: updateAllZones()

    property bool dockEnabled: true
    property string dockPosition: "bottom"
    property bool dockPinned: true
    property int dockHeight: (Config.dock?.height ?? 56) + (Config.dock?.margin ?? 8) + (isDefaultDock ? 0 : (Config.dock?.margin ?? 8))
    property bool isDefaultDock: (Config.dock?.theme ?? "default") === "default"

    onDockEnabledChanged: updateAllZones();
    onDockPositionChanged: updateAllZones();
    onDockPinnedChanged: updateAllZones();
    onDockHeightChanged: updateAllZones();

    property bool frameEnabled: Config.bar?.frameEnabled ?? false
    property int frameThickness: {
        const value = Config.bar?.frameThickness;
        if (typeof value !== "number")
            return 6;
        return Math.max(1, Math.min(Math.round(value), 40));
    }
    
    onFrameEnabledChanged: updateAllZones();
    onFrameThicknessChanged: updateAllZones();

    readonly property int actualFrameSize: frameEnabled ? frameThickness : 0

    function getExtraZone(side) {
        if (!Config.barReady) return 0;
        
        // Base zone is frame + border (static area)
        let zone = actualFrameSize > 0 ? actualFrameSize + borderWidth : 0;

        // Bar zone - only reserve if pinned (static)
        if (barEnabled && barPosition === side && barPinned) {
            if (zone === 0) zone = borderWidth;
            zone += barSize + barOuterMargin;
            // Add extra thickness if containing bar
            if (containBar) {
                zone += actualFrameSize;
            }
        }

        // Dock zone - only reserve if pinned (static)
        if (dockEnabled && dockPosition === side && dockPinned) {
            if (zone === 0) zone = borderWidth;
            zone += dockHeight;
        }

        return zone;
    }
    
    function getExclusionMode(side) {
        return getExtraZone(side) > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore;
    }

    function updateAllZones() {
        // Calculate new zones
        const newTop = getExtraZone("top");
        const newBottom = getExtraZone("bottom");
        const newLeft = getExtraZone("left");
        const newRight = getExtraZone("right");

        // Only update if something actually changed to avoid flickering
        if (topWindow.exclusiveZone === newTop && 
            bottomWindow.exclusiveZone === newBottom && 
            leftWindow.exclusiveZone === newLeft && 
            rightWindow.exclusiveZone === newRight) {
            
            // Check exclusion modes too
            if (topWindow.exclusionMode === getExclusionMode("top") &&
                bottomWindow.exclusionMode === getExclusionMode("bottom") &&
                leftWindow.exclusionMode === getExclusionMode("left") &&
                rightWindow.exclusionMode === getExclusionMode("right")) {
                return;
            }
        }

        // Clear all zones first
        topWindow.exclusiveZone = 0;
        bottomWindow.exclusiveZone = 0;
        leftWindow.exclusiveZone = 0;
        rightWindow.exclusiveZone = 0;

        // Restore zones (this triggers re-evaluation)
        Qt.callLater(() => {
            topWindow.exclusiveZone = newTop;
            bottomWindow.exclusiveZone = newBottom;
            leftWindow.exclusiveZone = newLeft;
            rightWindow.exclusiveZone = newRight;

            // Update exclusion modes too
            topWindow.exclusionMode = getExclusionMode("top");
            bottomWindow.exclusionMode = getExclusionMode("bottom");
            leftWindow.exclusionMode = getExclusionMode("left");
            rightWindow.exclusionMode = getExclusionMode("right");

            console.log("ReservationWindows: Updated zones - top:", topWindow.exclusiveZone, 
                       "bottom:", bottomWindow.exclusiveZone, 
                       "left:", leftWindow.exclusiveZone, 
                       "right:", rightWindow.exclusiveZone);
        });
    }

    Item {
        id: noInputRegion
        width: 0
        height: 0
        visible: false
    }

    PanelWindow {
        id: topWindow
        screen: root.screen
        visible: true
        implicitHeight: 1 // Minimal height
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:reservation:top"
        exclusionMode: root.getExclusionMode("top")
        exclusiveZone: root.getExtraZone("top")
        mask: Region {
            item: noInputRegion
        }
    }

    PanelWindow {
        id: bottomWindow
        screen: root.screen
        visible: true
        implicitHeight: 1
        color: "transparent"
        anchors {
            left: true
            right: true
            bottom: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:reservation:bottom"
        exclusionMode: root.getExclusionMode("bottom")
        exclusiveZone: root.getExtraZone("bottom")
        mask: Region {
            item: noInputRegion
        }
    }

    PanelWindow {
        id: leftWindow
        screen: root.screen
        visible: true
        implicitWidth: 1
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:reservation:left"
        exclusionMode: root.getExclusionMode("left")
        exclusiveZone: root.getExtraZone("left")
        mask: Region {
            item: noInputRegion
        }
    }

    PanelWindow {
        id: rightWindow
        screen: root.screen
        visible: true
        implicitWidth: 1
        color: "transparent"
        anchors {
            top: true
            bottom: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:reservation:right"
        exclusionMode: root.getExclusionMode("right")
        exclusiveZone: root.getExtraZone("right")
        mask: Region {
            item: noInputRegion
        }
    }
}
