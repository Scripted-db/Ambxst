pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    id: root

    property Process launchBluemanProcess: Process {
        command: ["blueman-manager"]
        running: false
    }

    Component.onCompleted: {
        // Only refresh device list, don't start scanning automatically
        if (BluetoothService.enabled) {
            BluetoothService.updateDevices();
        }
    }

    Component.onDestruction: {
        BluetoothService.stopDiscovery();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Titlebar
        PanelTitlebar {
            title: "Bluetooth"
            showSpinner: BluetoothService.discovering
            showToggle: true
            toggleChecked: BluetoothService.enabled
            
            actions: [
                {
                    icon: Icons.externalLink,
                    tooltip: "Open Blueman",
                    onClicked: function() { root.launchBluemanProcess.running = true; }
                },
                {
                    icon: Icons.sync,
                    tooltip: "Scan for devices",
                    enabled: !BluetoothService.discovering && BluetoothService.enabled,
                    onClicked: function() { BluetoothService.startDiscovery(); }
                }
            ]
            
            onToggleChanged: checked => {
                BluetoothService.setEnabled(checked);
                if (checked) {
                    BluetoothService.startDiscovery();
                }
            }
        }

        // Device list
        ListView {
            id: deviceList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4

            model: BluetoothService.friendlyDeviceList

            delegate: BluetoothDeviceItem {
                required property var modelData
                width: deviceList.width
                device: modelData
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0 && !BluetoothService.discovering
                text: BluetoothService.enabled ? "No devices found" : "Bluetooth is disabled"
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.overSurfaceVariant
            }
        }
    }
}
