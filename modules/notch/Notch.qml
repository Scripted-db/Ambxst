import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.modules.globals
import qs.modules.theme
import qs.modules.components
import qs.modules.corners
import qs.config

Item {
    id: notchContainer

    z: 1000

    property Component defaultViewComponent
    property Component launcherViewComponent
    property Component dashboardViewComponent
    property Component overviewViewComponent
    property Component powermenuViewComponent
    property var stackView: stackViewInternal
    property bool isExpanded: stackViewInternal.currentItem && stackViewInternal.initialItem && stackViewInternal.currentItem !== stackViewInternal.initialItem

    // Screen-specific visibility properties passed from parent
    property var visibilities
    readonly property bool screenNotchOpen: visibilities ? (visibilities.launcher || visibilities.dashboard || visibilities.overview || visibilities.powermenu) : false

    property int defaultHeight: Config.bar.showBackground ? (screenNotchOpen ? Math.max(stackContainer.height, 44) : 44) : (screenNotchOpen ? Math.max(stackContainer.height, 40) : 40)
    property int islandHeight: Config.bar.showBackground ? (screenNotchOpen ? Math.max(stackContainer.height, 36) : 36) : (screenNotchOpen ? Math.max(stackContainer.height, 36) : 36)

    implicitWidth: screenNotchOpen ? Math.max(stackContainer.width + 40, 290) : 290
    implicitHeight: Config.notchTheme === "default" ? defaultHeight : (Config.notchTheme === "island" ? islandHeight : defaultHeight)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: isExpanded ? 1.2 : 1.0
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: isExpanded ? Easing.OutBack : Easing.OutQuart
            easing.overshoot: isExpanded ? 1.2 : 1.0
        }
    }

    RoundCorner {
        id: leftCorner
        visible: Config.notchTheme === "default"
        anchors.top: parent.top
        anchors.right: notchRect.left
        corner: RoundCorner.CornerEnum.TopRight
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        color: Colors.background
    }

    BgRect {
        id: notchRect
        anchors.centerIn: parent
        width: parent.implicitWidth - 40
        height: parent.implicitHeight
        layer.enabled: false
        radius: 0

        property int defaultRadius: Config.roundness > 0 ? (screenNotchOpen ? Config.roundness + 20 : Config.roundness + 4) : 0
        property int islandRadius: screenNotchOpen ? Config.roundness + 20 : Config.roundness

        topLeftRadius: Config.notchTheme === "default" ? 0 : (Config.notchTheme === "island" ? islandRadius : 0)
        topRightRadius: Config.notchTheme === "default" ? 0 : (Config.notchTheme === "island" ? islandRadius : 0)
        bottomLeftRadius: defaultRadius
        bottomRightRadius: defaultRadius
        clip: true

        Behavior on radius {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: screenNotchOpen ? Easing.OutBack : Easing.OutQuart
                easing.overshoot: screenNotchOpen ? 1.2 : 1.0
            }
        }

        Item {
            id: stackContainer
            anchors.centerIn: parent
            width: stackViewInternal.currentItem ? stackViewInternal.currentItem.implicitWidth + 32 : 32
            height: stackViewInternal.currentItem ? stackViewInternal.currentItem.implicitHeight + 32 : 32
            clip: true

            // Propiedad para controlar el blur durante las transiciones
            property real transitionBlur: 0.0

            // Aplicar MultiEffect con blur animable
            layer.enabled: transitionBlur > 0.0
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 64
                blur: Math.min(Math.max(stackContainer.transitionBlur, 0.0), 1.0)
            }

            // Animación simple de blur → nitidez durante transiciones
            PropertyAnimation {
                id: blurTransitionAnimation
                target: stackContainer
                property: "transitionBlur"
                from: 1.0
                to: 0.0
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }

            StackView {
                id: stackViewInternal
                anchors.fill: parent
                anchors.margins: 16
                initialItem: defaultViewComponent

                // Activar blur al inicio de transición y animarlo a nítido
                onBusyChanged: {
                    if (busy) {
                        stackContainer.transitionBlur = 1.0;
                        blurTransitionAnimation.start();
                    }
                }

                pushEnter: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                    PropertyAnimation {
                        property: "scale"
                        from: 0.8
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }

                pushExit: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                    PropertyAnimation {
                        property: "scale"
                        from: 1
                        to: 1.05
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                popEnter: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                    PropertyAnimation {
                        property: "scale"
                        from: 1.05
                        to: 1
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }

                popExit: Transition {
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                    PropertyAnimation {
                        property: "scale"
                        from: 1
                        to: 0.95
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }

    RoundCorner {
        id: rightCorner
        visible: Config.notchTheme === "default"
        anchors.top: parent.top
        anchors.left: notchRect.right
        corner: RoundCorner.CornerEnum.TopLeft
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        color: Colors.background
    }
}
