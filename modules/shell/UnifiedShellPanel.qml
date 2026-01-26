import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.bar
import qs.modules.notch
import qs.modules.dock
import qs.modules.frame
import qs.modules.corners
import qs.modules.services
import qs.modules.globals
import qs.config

PanelWindow {
    id: unifiedPanel

    required property ShellScreen targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    
    // Compatibility properties for Visibilities and other components
    readonly property alias barPosition: barContent.barPosition
    readonly property alias pinned: barContent.pinned
    readonly property alias hoverActive: barContent.hoverActive
    readonly property alias barFullscreen: barContent.activeWindowFullscreen
    readonly property alias reveal: barContent.reveal // Use bar's reveal as general panel reveal for some logic

    readonly property alias dockPosition: dockContent.position
    readonly property alias dockPinned: dockContent.pinned
    readonly property alias dockReveal: dockContent.reveal
    readonly property alias dockFullscreen: dockContent.activeWindowFullscreen

    readonly property alias notchHoverActive: notchContent.hoverActive
    readonly property alias notchOpen: notchContent.screenNotchOpen

    // Proxy properties for Bar/Notch synchronization
    // Note: BarContent and NotchContent already handle their internal sync using Visibilities.
    
    Component.onCompleted: {
        Visibilities.registerBarPanel(screen.name, unifiedPanel);
        Visibilities.registerNotchPanel(screen.name, unifiedPanel);
        Visibilities.registerBar(screen.name, barContent);
        Visibilities.registerNotch(screen.name, notchContent.notchContainerRef);
    }

    Component.onDestruction: {
        Visibilities.unregisterBarPanel(screen.name);
        Visibilities.unregisterNotchPanel(screen.name);
        Visibilities.unregisterBar(screen.name);
        Visibilities.unregisterNotch(screen.name);
    }

    // Mask Region Logic
    mask: Region {
        item: maskUnionContainer
    }

    Item {
        id: maskUnionContainer
        anchors.fill: parent
        visible: false // Must be false so it doesn't draw, but children are used for Region

        // Hitbox from Bar
        Item {
            id: barHitbox
            x: barContent.barHitbox.x
            y: barContent.barHitbox.y
            width: barContent.barHitbox.width
            height: barContent.barHitbox.height
            visible: barContent.visible && barContent.barHitbox.visible
        }

        // Hitbox from Notch
        Item {
            id: notchHitbox
            x: notchContent.notchHitbox.x
            y: notchContent.notchHitbox.y
            width: notchContent.notchHitbox.width
            height: notchContent.notchHitbox.height
            visible: notchContent.visible && notchContent.notchHitbox.visible
        }

        // Hitbox from Dock
        Item {
            id: dockHitbox
            x: dockContent.dockHitbox.x
            y: dockContent.dockHitbox.y
            width: dockContent.dockHitbox.width
            height: dockContent.dockHitbox.height
            visible: dockContent.visible && dockContent.dockHitbox.visible
        }
    }

    // Focus Grab for Notch
    HyprlandFocusGrab {
        id: focusGrab
        windows: {
            let windowList = [unifiedPanel];
            // Optionally add other windows if needed, but since we are one window, this might be enough.
            return windowList;
        }
        active: notchContent.screenNotchOpen

        onCleared: {
            Visibilities.setActiveModule("");
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // VISUAL CONTENT (Z-Order: Frame -> Bar -> Dock -> Notch -> Corners)
    // ═══════════════════════════════════════════════════════════════

    ScreenFrameContent {
        id: frameContent
        anchors.fill: parent
        targetScreen: unifiedPanel.targetScreen
        z: 1
    }

    BarContent {
        id: barContent
        anchors.fill: parent
        screen: unifiedPanel.targetScreen
        z: 2
    }

    DockContent {
        id: dockContent
        anchors.fill: parent
        screen: unifiedPanel.targetScreen
        z: 3
        visible: {
            if (!(Config.dock?.enabled ?? false) || (Config.dock?.theme ?? "default") === "integrated")
                return false;
            
            const list = Config.dock?.screenList ?? [];
            if (!list || list.length === 0)
                return true;
            return list.includes(screen.name);
        }
    }

    NotchContent {
        id: notchContent
        anchors.fill: parent
        screen: unifiedPanel.targetScreen
        z: 4
    }

    ScreenCornersContent {
        id: cornersContent
        anchors.fill: parent
        z: 5
        visible: Config.theme.enableCorners && Config.roundness > 0
    }
}
