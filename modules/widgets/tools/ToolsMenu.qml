import QtQuick
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import Quickshell.Io

import qs.modules.services

ActionGrid {
    id: root

    signal itemSelected

    QtObject {
        id: recordAction
        property string icon: ScreenRecorder.isRecording ? Icons.stop : Icons.recordScreen
        property string text: ScreenRecorder.isRecording ? ScreenRecorder.duration : ""
        property string tooltip: "Record Screen"
        property string command: ""
        property string variant: ScreenRecorder.isRecording ? "error" : "primary"
        property string type: "button"
    }

    layout: "row"
    buttonSize: 48
    iconSize: 20
    spacing: 8

    actions: [
        {
            icon: Icons.camera,
            tooltip: "Screenshot",
            command: ""
        },
        {
            icon: Icons.screenshots,
            tooltip: "Open Screenshots",
            command: ""
        },
        {
            type: "separator"
        },
        recordAction,
        {
            icon: Icons.recordings,
            tooltip: "Open Recordings",
            command: ""
        },
        {
            type: "separator"
        },
        {
            icon: Icons.picker,
            tooltip: "Color Picker",
            command: ""
        },
        {
            icon: Icons.textT,
            tooltip: "OCR",
            command: ""
        },
        {
            icon: Icons.qrCode,
            tooltip: "QR Code",
            command: ""
        },
        {
            icon: Icons.webcam,
            tooltip: "Mirror",
            command: ""
        }
    ]

    onActionTriggered: action => {
        console.log("Tools action triggered:", action.tooltip);
        
        if (action.tooltip === "Screenshot") {
            GlobalStates.screenshotToolVisible = true
        } else if (action.tooltip === "Record Screen") {
            if (ScreenRecorder.isRecording) {
                ScreenRecorder.toggleRecording() // Stops it
            } else {
                GlobalStates.screenRecordToolVisible = true
            }
        }
        
        root.itemSelected();
    }
}
