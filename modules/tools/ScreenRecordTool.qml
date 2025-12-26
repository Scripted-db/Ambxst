import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

PanelWindow {
    id: recordPopup
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Visible only when explicitly opened
    visible: state !== "idle"
    exclusionMode: ExclusionMode.Ignore

    property string state: "idle" // idle, loading, active
    property string currentMode: "region" // region, window, screen, portal
    property var activeWindows: []
    
    // Audio State
    property bool recordAudioOutput: false
    property bool recordAudioInput: false

    property var modes: [
        { name: "audioOutput", icon: Icons.speakerHigh, tooltip: "Toggle Audio Output", type: "toggle", active: recordPopup.recordAudioOutput },
        { name: "audioInput", icon: Icons.mic, tooltip: "Toggle Microphone", type: "toggle", active: recordPopup.recordAudioInput },
        { type: "separator" },
        { name: "region", icon: Icons.regionScreenshot, tooltip: "Region" }, 
        { name: "window", icon: Icons.windowScreenshot, tooltip: "Window" }, 
        { name: "screen", icon: Icons.fullScreenshot, tooltip: "Screen" },
        { name: "portal", icon: Icons.aperture, tooltip: "Portal Mode" }
    ]

    function open() {
        // Reset to default state
        if (modeGrid) modeGrid.currentIndex = 3 // Default to Region (index 3 after toggles and separator)
        recordPopup.currentMode = "region"
        
        // Reset Audio state or keep it? Let's keep it persisted within session? 
        // Or reset to false? Let's default to false to avoid accidents.
        recordAudioOutput = false
        recordAudioInput = false
        
        recordPopup.state = "loading"
        
        // Use Screenshot service to freeze screen (it helps with selection visually)
        // Or should we just rely on live screen? Recording usually needs live screen.
        // ScreenshotTool uses 'freezeScreen' which takes a snapshot. We DON'T want that for recording set up necessarily?
        // But for "Region Selection" it's nice to have a frozen frame so things don't move while selecting.
        // However, `gpu-screen-recorder` records the LIVE screen.
        // If we freeze, we select, then we unfreeze and record. That works.
        screenshotService.freezeScreen()
    }

    function close() {
        recordPopup.state = "idle"
    }
    
    function executeCapture() {
        if (recordPopup.currentMode === "screen") {
            ScreenRecorder.startRecording("screen", "", recordAudioOutput, recordAudioInput)
            recordPopup.close()
        } else if (recordPopup.currentMode === "region") {
            if (selectionRect.width > 0) {
                // Format: WxH+X+Y
                var regionStr = Math.round(selectionRect.width) + "x" + Math.round(selectionRect.height) + "+" + Math.round(selectionRect.x) + "+" + Math.round(selectionRect.y);
                ScreenRecorder.startRecording("region", regionStr, recordAudioOutput, recordAudioInput)
                recordPopup.close()
            }
        } else if (recordPopup.currentMode === "window") {
            // Should have selected a window
        } else if (recordPopup.currentMode === "portal") {
            ScreenRecorder.startRecording("portal", "", recordAudioOutput, recordAudioInput)
            recordPopup.close()
        }
    }

    // Reuse Screenshot service for window detection and screen freezing
    Screenshot {
        id: screenshotService
        onScreenshotCaptured: path => {
            previewImage.source = ""
            previewImage.source = "file://" + path
            recordPopup.state = "active"
            // Reset selection
            selectionRect.width = 0
            selectionRect.height = 0
            // Fetch windows if we are in window mode, or pre-fetch
            screenshotService.fetchWindows()
            
            modeGrid.forceActiveFocus()
        }
        onWindowListReady: windows => {
            recordPopup.activeWindows = windows
        }
        onErrorOccurred: msg => {
            console.warn("ScreenRecordTool Error (Screenshot service):", msg)
            recordPopup.close()
        }
    }

    // Mask
    mask: Region {
        item: recordPopup.visible ? fullMask : emptyMask
    }

    Item {
        id: fullMask
        anchors.fill: parent
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    // Focus grabber
    HyprlandFocusGrab {
        id: focusGrab
        windows: [recordPopup]
        active: recordPopup.visible
    }

    // Main Content
    FocusScope {
        id: mainFocusScope
        anchors.fill: parent
        focus: true
        
        Keys.onEscapePressed: recordPopup.close()
        
        // 1. The "Frozen" Image (Background)
        Image {
            id: previewImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: recordPopup.state === "active"
        }

        // 2. Dimmer
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: recordPopup.state === "active" ? 0.4 : 0
            visible: recordPopup.state === "active" && recordPopup.currentMode !== "screen" && recordPopup.currentMode !== "portal"
        }
        
        // 3. Window Selection Highlights
        Item {
            anchors.fill: parent
            visible: recordPopup.state === "active" && recordPopup.currentMode === "window"
            
            Repeater {
                model: recordPopup.activeWindows
                delegate: Rectangle {
                    x: modelData.at[0]
                    y: modelData.at[1]
                    width: modelData.size[0]
                    height: modelData.size[1]
                    color: "transparent"
                    border.color: hoverHandler.hovered ? Colors.red : "transparent"
                    border.width: 2
                    
                    Rectangle {
                        anchors.fill: parent
                        color: Colors.red
                        opacity: hoverHandler.hovered ? 0.2 : 0
                    }

                    HoverHandler {
                        id: hoverHandler
                    }
                    
                    TapHandler {
                        onTapped: {
                            // Pass window geometry as region
                            var regionStr = parent.width + "x" + parent.height + "+" + parent.x + "+" + parent.y;
                            ScreenRecorder.startRecording("region", regionStr, recordAudioOutput, recordAudioInput)
                            recordPopup.close()
                        }
                    }
                }
            }
        }

        // 4. Region Selection (Drag) and Screen Capture (Click)
        MouseArea {
            id: regionArea
            anchors.fill: parent
            enabled: recordPopup.state === "active" && (recordPopup.currentMode === "region" || recordPopup.currentMode === "screen")
            hoverEnabled: true
            cursorShape: recordPopup.currentMode === "region" ? Qt.CrossCursor : Qt.ArrowCursor

            property point startPoint: Qt.point(0, 0)
            property bool selecting: false

            onPressed: mouse => {
                if (recordPopup.currentMode === "screen") return
                
                startPoint = Qt.point(mouse.x, mouse.y)
                selectionRect.x = mouse.x
                selectionRect.y = mouse.y
                selectionRect.width = 0
                selectionRect.height = 0
                selecting = true
            }

            onClicked: {
                if (recordPopup.currentMode === "screen") {
                    ScreenRecorder.startRecording("screen", "", recordAudioOutput, recordAudioInput)
                    recordPopup.close()
                }
            }

            onPositionChanged: mouse => {
                if (!selecting) return
                
                var x = Math.min(startPoint.x, mouse.x)
                var y = Math.min(startPoint.y, mouse.y)
                var w = Math.abs(startPoint.x - mouse.x)
                var h = Math.abs(startPoint.y - mouse.y)
                
                selectionRect.x = x
                selectionRect.y = y
                selectionRect.width = w
                selectionRect.height = h
            }

            onReleased: {
                if (!selecting) return
                
                selecting = false
                if (selectionRect.width > 5 && selectionRect.height > 5) {
                    var regionStr = Math.round(selectionRect.width) + "x" + Math.round(selectionRect.height) + "+" + Math.round(selectionRect.x) + "+" + Math.round(selectionRect.y);
                    ScreenRecorder.startRecording("region", regionStr, recordAudioOutput, recordAudioInput)
                    recordPopup.close()
                }
            }
        }
        
        // Visual Selection Rect
        Rectangle {
            id: selectionRect
            visible: recordPopup.state === "active" && recordPopup.currentMode === "region"
            color: "transparent"
            border.color: Colors.red
            border.width: 2
            
            Rectangle {
                anchors.fill: parent
                color: Colors.red
                opacity: 0.2
            }
        }

        // 5. Controls UI (Bottom Bar)
        Rectangle {
            id: controlsBar
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 50
            
            width: modeGrid.width + 32
            height: modeGrid.height + 32
            
            radius: Styling.radius(20)
            color: Colors.background
            border.color: Colors.surface
            border.width: 1
            visible: recordPopup.state === "active"
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
            }
            
            ActionGrid {
                id: modeGrid
                anchors.centerIn: parent
                
                // Map the modes to actions, handling dynamic properties
                actions: recordPopup.modes.map(m => {
                    if (m.type === "separator") return m;
                    
                    var newM = Object.assign({}, m);
                    if (m.name === "audioOutput") {
                        newM.variant = recordPopup.recordAudioOutput ? "primary" : "surface";
                        newM.icon = recordPopup.recordAudioOutput ? Icons.speakerHigh : Icons.speakerSlash;
                    } else if (m.name === "audioInput") {
                        newM.variant = recordPopup.recordAudioInput ? "primary" : "surface";
                        newM.icon = recordPopup.recordAudioInput ? Icons.mic : Icons.micSlash;
                    } else {
                        // For modes, highlight if selected
                        // But ActionGrid handles 'currentIndex' highlighting automatically for the selected item?
                        // Wait, ActionGrid highlights 'currentIndex'.
                        // We need to sync currentIndex with currentMode for modes.
                        // But toggles are also in the grid.
                        // If I click a toggle, currentIndex moves there. That's fine.
                        // But toggles shouldn't be "selected" as the active *mode*.
                        // We have mixed types: Toggles (boolean state) and Modes (mutually exclusive).
                        // ActionGrid is designed for simple "click -> action".
                        // Let's rely on onActionTriggered to handle logic.
                    }
                    return newM;
                })
                
                buttonSize: 48
                iconSize: 24
                spacing: 10
                
                onActionTriggered: action => {
                    if (action.name === "audioOutput") {
                        recordPopup.recordAudioOutput = !recordPopup.recordAudioOutput;
                    } else if (action.name === "audioInput") {
                        recordPopup.recordAudioInput = !recordPopup.recordAudioInput;
                    } else if (action.name === "portal") {
                        recordPopup.currentMode = "portal"
                        recordPopup.executeCapture()
                    } else {
                        // It's a mode switch
                        recordPopup.currentMode = action.name;
                    }
                }
            }
        }
    }
}
