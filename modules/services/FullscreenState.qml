pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    function isFullscreen(monitor, toplevels) {
        if (!monitor || !toplevels) return false;
        for (var i = 0; i < toplevels.length; i++) {
            if (toplevels[i].wayland && toplevels[i].wayland.fullscreen === true) {
                return true;
            }
        }
        return false;
    }
}
