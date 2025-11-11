pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.theme
import qs.modules.globals
import qs.config

PanelWindow {
    id: root

    visible: GlobalStates.lockscreenVisible
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    focusable: true
    mask: null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst-lockscreen"

    // Simple black overlay
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    // Password input container
    Item {
        anchors.centerIn: parent
        width: Math.min(400, parent.width - 64)
        height: passwordInput.height

        SearchInput {
            id: passwordInput
            width: parent.width
            iconText: "🔒"
            placeholderText: "Enter password..."
            clearOnEscape: false

            onAccepted: {
                if (passwordInput.text === "123") {
                    GlobalStates.lockscreenVisible = false;
                    passwordInput.clear();
                } else {
                    // Simple shake animation for wrong password
                    wrongPasswordAnim.start();
                }
            }

            onEscapePressed: {
                GlobalStates.lockscreenVisible = false;
                passwordInput.clear();
            }

            SequentialAnimation {
                id: wrongPasswordAnim
                NumberAnimation {
                    target: passwordInput
                    property: "x"
                    from: 0
                    to: 10
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInput
                    property: "x"
                    from: 10
                    to: -10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInput
                    property: "x"
                    from: -10
                    to: 10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInput
                    property: "x"
                    from: 10
                    to: 0
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: passwordInput.clear()
                }
            }

            Component.onCompleted: {
                if (GlobalStates.lockscreenVisible) {
                    passwordInput.focusInput();
                }
            }
        }
    }

    // Focus the input when lockscreen becomes visible
    onVisibleChanged: {
        if (visible) {
            passwordInput.focusInput();
        }
    }

    // Capture all keyboard input
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.lockscreenVisible = false;
            passwordInput.clear();
            event.accepted = true;
        }
    }
}
