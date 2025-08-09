import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals
import qs.modules.services

Item {
    id: root

    GlobalShortcut {
        id: launcherShortcut
        appid: "ambyst"
        name: "launcher"
        description: "Toggle application launcher"

        onPressed: {
            console.log("Launcher shortcut pressed");
            
            // Toggle launcher - if already open, close it; otherwise open launcher
            if (Visibilities.currentActiveModule === "launcher") {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("launcher");
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
            
            // Toggle dashboard - if already open, close it; otherwise open dashboard
            if (Visibilities.currentActiveModule === "dashboard") {
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("dashboard");
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
            
            // Toggle overview - if already open, close it; otherwise open overview
            if (Visibilities.currentActiveModule === "overview") {
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("overview");
            }
        }
    }

    GlobalShortcut {
        id: powermenuShortcut
        appid: "ambyst"
        name: "powermenu"
        description: "Toggle power menu"

        onPressed: {
            console.log("Power menu shortcut pressed");
            
            // Toggle power menu - if already open, close it; otherwise open power menu
            if (Visibilities.currentActiveModule === "powermenu") {
                Visibilities.setActiveModule("");
            } else {
                Visibilities.setActiveModule("powermenu");
            }
        }
    }
}
