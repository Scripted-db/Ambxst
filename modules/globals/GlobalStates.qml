pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property bool oledMode: loader.adapter.oledMode
    property int roundness: loader.adapter.roundness

    FileView {
        id: loader
        path: Qt.resolvedUrl("./globals.json")
        preload: true
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            property bool oledMode: false
            property int roundness: 16
        }
    }

    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool notchOpen: launcherOpen || dashboardOpen || overviewOpen
    property bool overviewOpen: false
    property bool launcherOpen: false
    property bool dashboardOpen: false
    property bool workspaceShowNumbers: false
    property bool superReleaseMightTrigger: true
    property var wallpaperManager: null
    onSuperReleaseMightTriggerChanged: {
        workspaceShowNumbersTimer.stop();
    }

    Timer {
        id: workspaceShowNumbersTimer
        interval: 300 // ConfigOptions.bar.workspaces.showNumberDelay
        repeat: false
        onTriggered: {
            workspaceShowNumbers = true;
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: qsTr("Hold to show workspace numbers, release to show icons")

        onPressed: {
            workspaceShowNumbersTimer.start();
        }
        onReleased: {
            workspaceShowNumbersTimer.stop();
            workspaceShowNumbers = false;
        }
    }

    GlobalShortcut {
        name: "toggleDashboard"
        description: qsTr("Toggle dashboard")

        onPressed: {
            dashboardOpen = !dashboardOpen;
        }
    }
}
