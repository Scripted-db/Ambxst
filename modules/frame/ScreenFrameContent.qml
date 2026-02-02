import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.modules.theme
import qs.config

Item {
    id: root

    required property ShellScreen targetScreen
    property bool hasFullscreenWindow: false

    readonly property bool frameEnabled: Config.bar?.frameEnabled ?? false
    
    // Reference the bar/dock content to get states
    readonly property var barPanel: Visibilities.barPanels[targetScreen.name]
    readonly property var dockPanel: Visibilities.dockPanels[targetScreen.name]
    
    readonly property bool barHovered: barPanel ? (barPanel.barHoverActive || barPanel.notchHoverActive || barPanel.notchOpen) : false
    // dockPanel.reveal is already true when it's pinned, we need to know if it's actually "visible" or being hovered to reveal
    readonly property bool dockHovered: dockPanel ? (dockPanel.reveal && (dockPanel.activeWindowFullscreen || dockPanel.keepHidden || !dockPanel.pinned)) : false

    readonly property real baseThickness: {
        const base = Config.bar?.frameThickness ?? 6;
        return Math.max(1, Math.min(Math.round(base), 40));
    }

    readonly property bool containBar: Config.bar?.containBar ?? false
    readonly property string barPos: Config.bar?.position ?? "top"

    readonly property int barSize: {
        if (!barPanel) return 44; // Fallback
        const isHoriz = barPos === "top" || barPos === "bottom";
        return isHoriz ? barPanel.barTargetHeight : barPanel.barTargetWidth;
    }

    property bool barReveal: true

    property real _barAnimProgress: barReveal ? 1.0 : 0.0
    Behavior on _barAnimProgress {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration / 2
            easing.type: Easing.OutCubic
        }
    }

    // This must match ScreenFrame.qml logic EXACTLY
    // ScreenFrame: barExpansion = barSize + baseThickness
    readonly property int barExpansion: Math.round((barSize + baseThickness) * _barAnimProgress)

    readonly property int topThickness: {
        let t = baseThickness;
        if (hasFullscreenWindow && !(barHovered && barPos === "top") && !(dockHovered && dockPanel.position === "top")) t = 0;
        return t + ((containBar && barPos === "top") ? barExpansion : 0);
    }
    readonly property int bottomThickness: {
        let t = baseThickness;
        if (hasFullscreenWindow && !(barHovered && barPos === "bottom") && !(dockHovered && dockPanel.position === "bottom")) t = 0;
        return t + ((containBar && barPos === "bottom") ? barExpansion : 0);
    }
    readonly property int leftThickness: {
        let t = baseThickness;
        if (hasFullscreenWindow && !(barHovered && barPos === "left") && !(dockHovered && dockPanel.position === "left")) t = 0;
        return t + ((containBar && barPos === "left") ? barExpansion : 0);
    }
    readonly property int rightThickness: {
        let t = baseThickness;
        if (hasFullscreenWindow && !(barHovered && barPos === "right") && !(dockHovered && dockPanel.position === "right")) t = 0;
        return t + ((containBar && barPos === "right") ? barExpansion : 0);
    }

    readonly property int actualFrameSize: frameEnabled ? baseThickness : 0

    readonly property int borderWidth: Config.theme.srBg.border[1]
    
    // innerRadius restoration logic
    readonly property real targetInnerRadius: (root.hasFullscreenWindow && !barHovered && !dockHovered) ? 0 : Styling.radius(4 + borderWidth)
    property real innerRadius: targetInnerRadius
    Behavior on innerRadius {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }

    // Visual part
    StyledRect {
        id: frameFill
        anchors.fill: parent
        variant: "bg"
        radius: 0
        enableBorder: false
        visible: root.frameEnabled
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: frameMask
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: frameMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            id: maskRect
            x: root.leftThickness
            y: root.topThickness
            width: parent.width - (root.leftThickness + root.rightThickness)
            height: parent.height - (root.topThickness + root.bottomThickness)
            radius: root.innerRadius
            color: "white"
            visible: width > 0 && height > 0
        }
    }
}
