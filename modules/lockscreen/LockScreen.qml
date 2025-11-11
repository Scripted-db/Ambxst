pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
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

    // Screen capture background
    ScreencopyView {
        id: screencopyBackground
        anchors.fill: parent
        captureSource: root.screen
        live: false
        paintCursor: false
        visible: false
    }

    // Blur effect
    MultiEffect {
        id: blurEffect
        anchors.fill: parent
        source: screencopyBackground
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0
        blurMax: 64
        visible: false

        Behavior on blur {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // Overlay for dimming
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.25
    }

    // Left sidebar
    Rectangle {
        id: sidebar
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        x: GlobalStates.lockscreenVisible ? 0 : -width
        width: 350
        color: Colors.background

        Behavior on x {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 24

            // Avatar
            Rectangle {
                id: avatarContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200
                height: 200
                radius: Config.roundness > 0 ? (width / 2) * (Config.roundness / 16) : 0
                color: "transparent"
                border.width: 4
                border.color: Colors.primary

                Image {
                    id: userAvatar
                    anchors.fill: parent
                    anchors.margins: 8
                    source: `file://${Quickshell.env("HOME")}/.face.icon`
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: userAvatar.width
                                height: userAvatar.height
                                radius: Config.roundness > 0 ? (width / 2) * (Config.roundness / 16) : 0
                            }
                        }
                    }
                }

                // Fallback icon if image not found
                Text {
                    anchors.centerIn: parent
                    text: "👤"
                    font.pixelSize: 64
                    visible: userAvatar.status !== Image.Ready
                }
            }

            // User and hostname
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Text {
                    id: usernameText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        const username = usernameCollector.text.trim();
                        return username.charAt(0).toUpperCase() + username.slice(1);
                    }
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 2
                    font.weight: Font.Bold
                    color: Colors.overBackground
                }

                Text {
                    id: hostnameText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        const hostname = hostnameCollector.text.trim();
                        return hostname.charAt(0).toUpperCase() + hostname.slice(1);
                    }
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 2
                    font.weight: Font.Bold
                    color: Colors.outline
                }
            }

            // Password input
            Item {
                width: 300
                height: passwordInput.height
                anchors.horizontalCenter: parent.horizontalCenter

                SearchInput {
                    id: passwordInput
                    width: parent.width
                    iconText: ""
                    placeholderText: "Enter password..."
                    clearOnEscape: false
                    passwordMode: true
                    centerText: true

                    onAccepted: {
                        if (passwordInput.text === "123") {
                            GlobalStates.lockscreenVisible = false;
                            passwordInput.clear();
                        } else {
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
        }
    }

    // Timer to animate blur after capture
    Timer {
        id: blurAnimTimer
        interval: 50
        onTriggered: {
            blurEffect.blur = 1;
        }
    }

    // Focus the input when lockscreen becomes visible
    onVisibleChanged: {
        if (visible) {
            blurEffect.blur = 0;
            screencopyBackground.captureFrame();
            blurEffect.visible = true;
            blurAnimTimer.start();
            passwordInput.focusInput();
        } else {
            blurAnimTimer.stop();
            blurEffect.visible = false;
            blurEffect.blur = 0;
        }
    }

    // Processes for user info
    Process {
        id: usernameProc
        command: ["whoami"]
        running: true

        stdout: StdioCollector {
            id: usernameCollector
            waitForEnd: true
        }
    }

    Process {
        id: hostnameProc
        command: ["hostname"]
        running: true

        stdout: StdioCollector {
            id: hostnameCollector
            waitForEnd: true
        }
    }

    // Screen corners
    RoundCorner {
        id: topLeft
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.left: parent.left
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopLeft
    }

    RoundCorner {
        id: topRight
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.right: parent.right
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopRight
    }

    RoundCorner {
        id: bottomLeft
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomLeft
    }

    RoundCorner {
        id: bottomRight
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomRight
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
