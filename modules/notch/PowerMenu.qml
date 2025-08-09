import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.services

FocusScope {
    id: root
    
    implicitWidth: 300
    implicitHeight: 60
    
    property int currentIndex: 0
    property list<QtObject> powerActions: [
        QtObject {
            property string icon: "\uf023"
            property string tooltip: "Lock Session"
            property string command: "loginctl lock-session"
        },
        QtObject {
            property string icon: "\uf186"
            property string tooltip: "Suspend"
            property string command: "systemctl suspend"
        },
        QtObject {
            property string icon: "\uf2f5"
            property string tooltip: "Exit Hyprland"
            property string command: "hyprctl dispatch exit"
        },
        QtObject {
            property string icon: "\uf2f1"
            property string tooltip: "Reboot"
            property string command: "systemctl reboot"
        },
        QtObject {
            property string icon: "\uf011"
            property string tooltip: "Power Off"
            property string command: "systemctl poweroff"
        }
    ]
    
    Component.onCompleted: {
        root.forceActiveFocus()
        if (buttonRepeater.count > 0) {
            buttonRepeater.itemAt(0).forceActiveFocus()
        }
    }
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            currentIndex = (currentIndex + 1) % powerActions.length
            buttonRepeater.itemAt(currentIndex).forceActiveFocus()
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            currentIndex = (currentIndex - 1 + powerActions.length) % powerActions.length
            buttonRepeater.itemAt(currentIndex).forceActiveFocus()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            if (buttonRepeater.itemAt(currentIndex)) {
                buttonRepeater.itemAt(currentIndex).executeAction()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            Visibilities.setActiveModule("")
            event.accepted = true
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        
        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 12
            
            Repeater {
                id: buttonRepeater
                model: root.powerActions
                
                delegate: Button {
                    id: powerButton
                    
                    implicitWidth: 48
                    implicitHeight: 48
                    
                    property bool isCurrentFocus: root.currentIndex === index
                    
                    Process {
                        id: commandProcess
                        command: ["bash", "-c", modelData.command]
                        running: false
                    }
                    
                    function executeAction() {
                        console.log("Executing power action:", modelData.command)
                        commandProcess.running = true
                    }
                    
                    background: BgRect {
                        color: powerButton.pressed ? Colors.adapter.primary : 
                               (powerButton.hovered || powerButton.activeFocus) ? Colors.adapter.surfaceContainerHighest : 
                               Colors.adapter.surfaceContainer
                        radius: 24
                        
                        border.width: powerButton.activeFocus ? 2 : 0
                        border.color: Colors.adapter.primary
                    }
                    
                    contentItem: Text {
                        text: modelData.icon
                        font.family: Styling.iconFont
                        font.pixelSize: 20
                        color: powerButton.pressed ? Colors.adapter.overPrimary : Colors.adapter.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: executeAction()
                    
                    onActiveFocusChanged: {
                        if (activeFocus) {
                            root.currentIndex = index
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: modelData.tooltip
                    ToolTip.delay: 500
                }
            }
        }
    }
}