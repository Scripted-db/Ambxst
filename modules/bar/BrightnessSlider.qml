import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme

Item {
    id: root
    required property var bar
    
    // Orientación derivada de la barra
    property bool vertical: bar.orientation === "vertical"
    
    // Estado de hover para activar wavy
    property bool isHovered: false
    property bool mainHovered: false
    property bool iconHovered: false
    property bool externalBrightnessChange: false
    
    // Propiedades para animación del icono
    property string currentIcon: Icons.sun
    property real iconRotation: 0
    property real iconScale: 1
    property real previousValue: 0
    
    // Animaciones individuales con IDs
    NumberAnimation {
        id: rotationAnim
        target: root
        property: "iconRotation"
        duration: Config.animDuration
        easing.type: Easing.InOutCubic
    }
    
    NumberAnimation {
        id: scaleAnim
        target: root
        property: "iconScale"
        duration: Config.animDuration
        easing.type: Easing.InOutCubic
    }
    
    // Función helper para animar el icono
    function animateIcon(brightness) {
        rotationAnim.stop();
        scaleAnim.stop();
        
        rotationAnim.to = (brightness / 1.0) * 90;
        scaleAnim.to = 0.8 + (brightness / 1.0) * 0.2;
        
        rotationAnim.start();
        scaleAnim.start();
    }
    
    HoverHandler {
        onHoveredChanged: {
            root.mainHovered = hovered;
            root.isHovered = root.mainHovered || root.iconHovered;
        }
    }
    
    // Tamaño basado en hover para BgRect con animación
    implicitWidth: root.vertical ? 4 : 80
    implicitHeight: root.vertical ? 80 : 4
    Layout.preferredWidth: root.vertical ? 4 : 80
    Layout.preferredHeight: root.vertical ? 80 : 4
    
    states: [
        State {
            name: "hovered"
            when: root.isHovered || brightnessSlider.isDragging || root.externalBrightnessChange
            PropertyChanges {
                target: root
                implicitWidth: root.vertical ? 4 : 128
                implicitHeight: root.vertical ? 128 : 4
                Layout.preferredWidth: root.vertical ? 4 : 128
                Layout.preferredHeight: root.vertical ? 128 : 4
            }
        }
    ]
    
    transitions: Transition {
        NumberAnimation {
            properties: "implicitWidth,implicitHeight,Layout.preferredWidth,Layout.preferredHeight"
            duration: Config.animDuration
            easing.type: Easing.OutCubic
        }
    }
    
    Layout.fillWidth: root.vertical
    Layout.fillHeight: !root.vertical
    
    // Obtener el monitor para la pantalla actual
    property var currentMonitor: Brightness.getMonitorForScreen(bar.screen)
    
    Component.onCompleted: {
        if (currentMonitor) {
            brightnessSlider.value = currentMonitor.brightness;
            const brightness = currentMonitor.brightness;
            currentIcon = Icons.sun;
            iconRotation = (brightness / 1.0) * 360;
            iconScale = 0.5 + (brightness / 1.0) * 0.5;
        }
    }
    
    BgRect {
        anchors.fill: parent
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.mainHovered = true;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
            onExited: {
                root.mainHovered = false;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    brightnessSlider.value = Math.min(1, brightnessSlider.value + 0.1);
                } else {
                    brightnessSlider.value = Math.max(0, brightnessSlider.value - 0.1);
                }
            }
        }
        
        StyledSlider {
            id: brightnessSlider
            anchors.fill: parent
            anchors.margins: 8
            anchors.rightMargin: root.vertical ? 8 : 16
            anchors.topMargin: root.vertical ? 16 : 8
            
            vertical: root.vertical
            smoothDrag: true
            value: 0
            resizeParent: false
            wavy: true
            wavyAmplitude: (root.isHovered || brightnessSlider.isDragging || root.externalBrightnessChange) ? (1.5 * value) : 0
            wavyFrequency: (root.isHovered || brightnessSlider.isDragging || root.externalBrightnessChange) ? (8.0 * value) : 0
            
            iconPos: root.vertical ? "end" : "start"
            icon: root.currentIcon
            iconRotation: root.iconRotation
            iconScale: root.iconScale
            progressColor: Colors.primary
            
            onValueChanged: {
                if (currentMonitor) {
                    currentMonitor.setBrightness(value);
                }
                
                // Siempre usar Icons.sun
                currentIcon = Icons.sun;
                
                // Animar el icono
                root.animateIcon(value);
                
                previousValue = value;
            }
            
            onIconClicked: {
                // Opcional: toggle o algo, pero por ahora solo el slider
            }
            
            Connections {
                target: currentMonitor
                function onBrightnessChanged() {
                    if (currentMonitor) {
                        brightnessSlider.value = currentMonitor.brightness;
                        const brightness = currentMonitor.brightness;
                        currentIcon = Icons.sun;
                        
                        // Animar el icono
                        root.animateIcon(brightness);
                        
                        root.externalBrightnessChange = true;
                        externalChangeTimer.restart();
                    }
                }
            }
            
            Connections {
                target: brightnessSlider
                function onIconHovered(hovered) {
                    root.iconHovered = hovered;
                    root.isHovered = root.mainHovered || root.iconHovered;
                }
            }
        }
        
        Timer {
            id: externalChangeTimer
            interval: 1000
            onTriggered: root.externalBrightnessChange = false
        }
    }
}
