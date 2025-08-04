import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals

Item {
    id: root

    GlobalShortcut {
        id: launcherShortcut
        appid: "ambyst"
        name: "launcher"
        description: "Toggle application launcher"

        onPressed: {
            console.log("Launcher shortcut pressed");
            // Toggle launcher - si ya está abierto, se cierra; si no, abre launcher y cierra dashboard
            if (GlobalStates.launcherOpen) {
                GlobalStates.launcherOpen = false;
            } else {
                GlobalStates.dashboardOpen = false;
                GlobalStates.overviewOpen = false;
                GlobalStates.launcherOpen = true;
            }
        }
    }

    GlobalShortcut {
        id: dashboardShortcut
        appid: "ambyst"
        name: "dashboard"
        description: "Toggle dashboard"

        onPressed: {
            console.log("Dashboard shortcut pressed");
            // Toggle dashboard - si ya está abierto, se cierra; si no, abre dashboard y cierra launcher
            if (GlobalStates.dashboardOpen) {
                GlobalStates.dashboardOpen = false;
            } else {
                GlobalStates.launcherOpen = false;
                GlobalStates.overviewOpen = false;
                GlobalStates.dashboardOpen = true;
            }
        }
    }

    GlobalShortcut {
        id: overviewShortcut
        appid: "ambyst"
        name: "overview"
        description: "Toggle window overview"

        onPressed: {
            console.log("Overview shortcut pressed");
            // Toggle overview - si ya está abierto, se cierra; si no, abre overview y cierra otros
            if (GlobalStates.overviewOpen) {
                GlobalStates.overviewOpen = false;
            } else {
                GlobalStates.launcherOpen = false;
                GlobalStates.dashboardOpen = false;
                GlobalStates.overviewOpen = true;
            }
        }
    }
}
