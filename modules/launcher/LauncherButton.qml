import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config

ToggleButton {
    buttonIcon: Config.bar.launcherIcon
    tooltipText: "Open Application Launcher"

    onToggle: function () {
        if (GlobalStates.launcherOpen) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule("launcher");
        }
    }
}
