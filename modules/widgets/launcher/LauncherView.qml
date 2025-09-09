import QtQuick
import QtQuick.Controls
import qs.modules.widgets.launcher
import qs.modules.globals
import qs.modules.services
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root

    readonly property var tabModel: [Icons.apps, Icons.terminal, Icons.clipboard]
    readonly property int tabCount: tabModel.length
    readonly property int tabSpacing: 8
    readonly property int tabWidth: 48

    property var state: QtObject {
        property int currentTab: 0  // Siempre iniciar en la primera página
    }

    implicitWidth: 480
    implicitHeight: Math.min(stack.currentItem ? stack.currentItem.implicitHeight : 368, 368)

    // Reset al tab 0 cuando se abre el launcher
    Component.onCompleted: {
        root.state.currentTab = 0;
        GlobalStates.launcherCurrentTab = 0;
        Qt.callLater(() => {
            if (stack.currentItem && stack.currentItem.focusSearchInput) {
                stack.currentItem.focusSearchInput();
            }
        });
    }

    Row {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Tab buttons (sidebar)
        Item {
            id: tabsContainer
            width: root.tabWidth
            height: parent.height

            // Manejo del scroll con rueda del mouse
            WheelHandler {
                id: wheelHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                onWheel: event => {
                    // Determinar dirección del scroll
                    let scrollUp = event.angleDelta.y > 0;
                    let newIndex = root.state.currentTab;

                    if (scrollUp && newIndex > 0) {
                        // Scroll hacia arriba = pestaña anterior
                        newIndex = newIndex - 1;
                    } else if (!scrollUp && newIndex < root.tabCount - 1) {
                        // Scroll hacia abajo = pestaña siguiente
                        newIndex = newIndex + 1;
                    }

                    // Navegar solo si cambió el índice
                    if (newIndex !== root.state.currentTab) {
                        stack.navigateToTab(newIndex);
                    }
                }
            }

            // Background highlight que se desplaza verticalmente
            Rectangle {
                id: tabHighlight
                width: parent.width
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                color: Colors.adapter.primary
                z: 0

                property real idx1: root.state.currentTab
                property real idx2: root.state.currentTab

                x: 0
                y: Math.min(idx1, idx2) * (width + root.tabSpacing)
                height: Math.abs(idx1 - idx2) * (width + root.tabSpacing) + width

                Behavior on idx1 {
                    NumberAnimation {
                        duration: Config.animDuration / 3
                        easing.type: Easing.OutSine
                    }
                }
                Behavior on idx2 {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutSine
                    }
                }
            }

            Column {
                id: tabs
                anchors.fill: parent
                spacing: root.tabSpacing

                Repeater {
                    model: root.tabModel

                    Button {
                        required property int index
                        required property string modelData

                        text: modelData
                        flat: true
                        width: tabsContainer.width
                        height: width

                        background: Rectangle {
                            color: "transparent"
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: root.state.currentTab === index ? Colors.background : Colors.adapter.overBackground
                            font.family: Icons.font
                            font.pixelSize: 20
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        onClicked: stack.navigateToTab(index)
                    }
                }
            }
        }

        // Content area
        PaneRect {
            id: viewWrapper

            color: "transparent"
            width: parent.width - root.tabWidth - 8
            height: parent.height
            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            clip: true

            StackView {
                id: stack
                anchors.fill: parent

                // Array de componentes para cargar dinámicamente
                property var components: [appsComponent, tmuxComponent, clipboardComponent]

                initialItem: appsComponent

                // Función para navegar a un tab específico
                function navigateToTab(index) {
                    if (index >= 0 && index < components.length && index !== root.state.currentTab) {
                        let targetComponent = components[index];

                        // Determinar dirección de la transición
                        let direction = index > root.state.currentTab ? StackView.PushTransition : StackView.PopTransition;

                        // Usar replace para evitar acumulación en el stack
                        stack.replace(targetComponent, {}, direction);

                        root.state.currentTab = index;
                        GlobalStates.launcherCurrentTab = index;

                        // Auto-focus search input when switching to apps tab
                        if (index === 0) {
                            Qt.callLater(() => {
                                if (stack.currentItem && stack.currentItem.focusSearchInput) {
                                    stack.currentItem.focusSearchInput();
                                }
                            });
                        }
                    }
                }

                // Transiciones personalizadas para swipe vertical
                pushEnter: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: stack.height
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                pushExit: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: 0
                        to: -stack.height
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                popEnter: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: -stack.height
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                popExit: Transition {
                    PropertyAnimation {
                        property: "y"
                        from: 0
                        to: stack.height
                        duration: Config.animDuration
                        easing.type: Easing.OutCubic
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }

    // Atajos de teclado para navegación
    Shortcut {
        id: nextTabShortcut
        sequence: "Ctrl+Tab"
        enabled: GlobalStates.getActiveLauncher()

        onActivated: {
            let nextIndex = (root.state.currentTab + 1) % root.tabCount;
            stack.navigateToTab(nextIndex);
        }
    }

    Shortcut {
        id: prevTabShortcut
        sequence: "Ctrl+Shift+Tab"
        enabled: GlobalStates.getActiveLauncher()

        onActivated: {
            let prevIndex = root.state.currentTab - 1;
            if (prevIndex < 0) {
                prevIndex = root.tabCount - 1;
            }
            stack.navigateToTab(prevIndex);
        }
    }

    // Manejo de eventos de teclado
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.clearLauncherState();
            Visibilities.setActiveModule("");
            event.accepted = true;
        }
    }

    // Component definitions
    Component {
        id: appsComponent
        LauncherAppsTab {
            onItemSelected: {
                GlobalStates.clearLauncherState();
                Visibilities.setActiveModule("");
            }
        }
    }

    Component {
        id: tmuxComponent
        LauncherTmuxTab {}
    }

    Component {
        id: clipboardComponent
        LauncherClipboardTab {}
    }
}