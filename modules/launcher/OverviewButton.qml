import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config

ToggleButton {
    buttonIcon: Config.bar.overviewIcon
    tooltipText: "Open Window Overview"

    onToggle: function () {
        if (GlobalStates.overviewOpen) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule("overview");
        }
    }
}
