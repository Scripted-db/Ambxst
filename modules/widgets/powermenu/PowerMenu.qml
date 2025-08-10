import QtQuick
import qs.modules.components
import qs.modules.services
import qs.modules.theme

ActionGrid {
    id: root

    signal itemSelected

    layout: "row"
    buttonSize: 48
    spacing: 8

    // Forzar foco al abrir
    Component.onCompleted: {
        root.forceActiveFocus();
    }

    actions: [
        {
            icon: Icons.lock,
            tooltip: "Lock Session",
            command: "loginctl lock-session"
        },
        {
            icon: Icons.suspend,
            tooltip: "Suspend",
            command: "systemctl suspend"
        },
        {
            icon: Icons.logout,
            tooltip: "Exit Hyprland",
            command: "hyprctl dispatch exit"
        },
        {
            icon: Icons.reboot,
            tooltip: "Reboot",
            command: "systemctl reboot"
        },
        {
            icon: Icons.shutdown,
            tooltip: "Power Off",
            command: "systemctl poweroff"
        }
    ]

    onActionTriggered: action => {
        console.log("Executing power action:", action.command);
        root.itemSelected();
    }
}
