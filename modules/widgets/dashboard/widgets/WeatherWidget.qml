pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Rectangle {
    id: root

    // Configurable properties
    property bool showDebugControls: true
    property real cornerRadius: Styling.radius(4)

    // Internal alias for celestial body position (used by sun rays)
    readonly property alias celestialBodyItem: celestialBody

    radius: cornerRadius
    clip: true
    visible: WeatherService.dataAvailable

    // Color blending helper function
    function blendColors(color1, color2, color3, blend) {
        var r = color1.r * blend.day + color2.r * blend.evening + color3.r * blend.night;
        var g = color1.g * blend.day + color2.g * blend.evening + color3.g * blend.night;
        var b = color1.b * blend.day + color2.b * blend.evening + color3.b * blend.night;
        return Qt.rgba(r, g, b, 1);
    }

    // Color definitions for each time of day
    // Day colors (sky blue)
    readonly property color dayTop: "#87CEEB"
    readonly property color dayMid: "#B0E0E6"
    readonly property color dayBot: "#E0F6FF"
    
    // Evening colors (sunset)
    readonly property color eveningTop: "#1a1a2e"
    readonly property color eveningMid: "#e94560"
    readonly property color eveningBot: "#ffeaa7"
    
    // Night colors (dark blue)
    readonly property color nightTop: "#0f0f23"
    readonly property color nightMid: "#1a1a3a"
    readonly property color nightBot: "#2d2d5a"

    // Blended colors based on time
    readonly property var blend: WeatherService.effectiveTimeBlend
    readonly property color topColor: blendColors(dayTop, eveningTop, nightTop, blend)
    readonly property color midColor: blendColors(dayMid, eveningMid, nightMid, blend)
    readonly property color botColor: blendColors(dayBot, eveningBot, nightBot, blend)

    // Dynamic gradient based on time of day (smooth interpolation)
    gradient: Gradient {
        GradientStop { position: 0.0; color: root.topColor }
        GradientStop { position: 0.5; color: root.midColor }
        GradientStop { position: 1.0; color: root.botColor }
    }

    // Weather effect properties
    readonly property string weatherEffect: WeatherService.effectiveWeatherEffect
    readonly property real weatherIntensity: WeatherService.effectiveWeatherIntensity

    // Text colors (interpolated)
    readonly property color textPrimary: blendColors(
        Qt.color("#1a5276"),  // Day
        Qt.color("#FFFFFF"),  // Evening
        Qt.color("#FFFFFF"),  // Night
        blend
    )
    readonly property color textSecondary: blendColors(
        Qt.color("#2980b9"),  // Day
        Qt.rgba(1, 1, 1, 0.7),  // Evening
        Qt.rgba(1, 1, 1, 0.7),  // Night
        blend
    )

    // ═══════════════════════════════════════════════════════════
    // AMBIENT EFFECTS (stars, sun rays)
    // ═══════════════════════════════════════════════════════════

    // Stars at night (twinkling)
    Item {
        id: starsEffect
        anchors.fill: parent
        // Show stars when night blend > 0.3 and weather is clear
        opacity: (root.blend.night > 0.3 && root.weatherEffect === "clear") 
                 ? Math.min(1, (root.blend.night - 0.3) / 0.4) : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad }
        }

        Repeater {
            model: 20

            Rectangle {
                id: star
                property real baseX: Math.random() * starsEffect.width
                property real baseY: Math.random() * (starsEffect.height * 0.7)  // Upper 70%
                property real baseSize: 1 + Math.random() * 2
                property real twinkleSpeed: 1500 + Math.random() * 2000
                property real baseOpacity: 0.4 + Math.random() * 0.4

                x: baseX
                y: baseY
                width: baseSize
                height: baseSize
                radius: baseSize / 2
                color: "#FFFFFF"
                opacity: baseOpacity

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: starsEffect.visible

                    NumberAnimation {
                        to: star.baseOpacity * 0.3
                        duration: star.twinkleSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: star.baseOpacity
                        duration: star.twinkleSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // Sun rays during clear day
    Item {
        id: sunRaysEffect
        anchors.fill: parent
        // Show rays when day blend > 0.5 and weather is clear
        opacity: (root.blend.day > 0.5 && root.weatherEffect === "clear") 
                 ? Math.min(0.4, (root.blend.day - 0.5) * 0.8) : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
        }

        // Position rays emanating from sun position
        property real sunX: celestialBody.x + celestialBody.width / 2
        property real sunY: celestialBody.y + celestialBody.height / 2

        Repeater {
            model: 8

            Rectangle {
                id: ray
                property real angle: (index * 45) * Math.PI / 180
                property real rayLength: 60 + Math.random() * 30
                property real pulseSpeed: 3000 + Math.random() * 1500

                x: sunRaysEffect.sunX + Math.cos(angle) * 15 - width / 2
                y: sunRaysEffect.sunY + Math.sin(angle) * 15 - 1
                width: rayLength
                height: 2
                radius: 1
                rotation: angle * 180 / Math.PI
                transformOrigin: Item.Left
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 0.95, 0.7, 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 0.95, 0.7, 0) }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: sunRaysEffect.visible

                    NumberAnimation {
                        to: 0.3
                        duration: ray.pulseSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: ray.pulseSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // WEATHER EFFECTS
    // ═══════════════════════════════════════════════════════════

    // Cloud effect (improved with layering)
    Item {
        id: cloudEffect
        anchors.fill: parent
        visible: root.weatherEffect === "clouds"
        opacity: root.weatherIntensity

        // Background layer - larger, slower, more transparent clouds
        Repeater {
            model: 2

            Item {
                id: bgCloud
                property real startX: -width + (index * parent.width * 0.6)
                property real speed: 0.15 + (index * 0.05)

                x: startX
                y: 5 + (index * 20)
                width: 80 + (index * 20)
                height: 30 + (index * 8)

                // Cloud shape - multiple overlapping circles
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: parent.height * 0.6
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.15)
                }
                Rectangle {
                    x: parent.width * 0.1
                    y: parent.height * 0.2
                    width: parent.width * 0.4
                    height: parent.height * 0.5
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
                Rectangle {
                    x: parent.width * 0.5
                    y: parent.height * 0.15
                    width: parent.width * 0.45
                    height: parent.height * 0.55
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.12)
                }

                NumberAnimation on x {
                    from: bgCloud.startX
                    to: cloudEffect.width + bgCloud.width
                    duration: 35000 / bgCloud.speed
                    loops: Animation.Infinite
                    running: cloudEffect.visible
                }
            }
        }

        // Foreground layer - smaller, faster, more opaque clouds
        Repeater {
            model: 3

            Item {
                id: fgCloud
                property real startX: -width + (index * parent.width * 0.35)
                property real speed: 0.25 + (index * 0.1)

                x: startX
                y: 15 + (index * 18)
                width: 45 + (index * 12)
                height: 18 + (index * 5)

                // Cloud shape
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.7
                    height: parent.height * 0.7
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.28 - (index * 0.04))
                }
                Rectangle {
                    x: parent.width * 0.05
                    y: parent.height * 0.25
                    width: parent.width * 0.35
                    height: parent.height * 0.5
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.22 - (index * 0.03))
                }
                Rectangle {
                    x: parent.width * 0.55
                    y: parent.height * 0.2
                    width: parent.width * 0.4
                    height: parent.height * 0.55
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.22 - (index * 0.03))
                }

                NumberAnimation on x {
                    from: fgCloud.startX
                    to: cloudEffect.width + fgCloud.width
                    duration: 22000 / fgCloud.speed
                    loops: Animation.Infinite
                    running: cloudEffect.visible
                }
            }
        }
    }

    // Fog effect
    Rectangle {
        id: fogEffect
        anchors.fill: parent
        visible: root.weatherEffect === "fog"
        opacity: root.weatherIntensity * 0.5

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.1) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.3) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.4) }
        }

        // Animated fog wisps
        Repeater {
            model: 4

            Rectangle {
                property real baseY: index * (parent.height / 4)

                x: -width / 2
                y: baseY
                width: parent.width * 1.5
                height: 25 + (index * 5)
                color: Qt.rgba(1, 1, 1, 0.15)
                radius: height / 2

                NumberAnimation on x {
                    from: -width / 2
                    to: 0
                    duration: 8000 + (index * 2000)
                    loops: Animation.Infinite
                    running: fogEffect.visible
                    easing.type: Easing.InOutSine
                }

                NumberAnimation on opacity {
                    from: 0.1
                    to: 0.25
                    duration: 4000 + (index * 1000)
                    loops: Animation.Infinite
                    running: fogEffect.visible
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // Rain effect
    Item {
        id: rainEffect
        anchors.fill: parent
        visible: root.weatherEffect === "rain" || root.weatherEffect === "drizzle"
        
        property int dropCount: Math.round(20 * root.weatherIntensity)

        Repeater {
            model: rainEffect.dropCount

            Rectangle {
                id: rainDrop
                property real startX: Math.random() * rainEffect.width
                property real startY: -10
                property real fallSpeed: 800 + Math.random() * 400

                x: startX
                y: startY
                width: root.weatherEffect === "drizzle" ? 1 : 2
                height: root.weatherEffect === "drizzle" ? 8 : 12
                radius: 1
                color: Qt.rgba(0.7, 0.85, 1, 0.6)
                rotation: -15

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: rainEffect.visible

                    PropertyAction { value: -10 - Math.random() * 20 }
                    NumberAnimation {
                        to: rainEffect.height + 10
                        duration: rainDrop.fallSpeed
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: rainEffect.visible

                    PropertyAction { value: Math.random() * rainEffect.width }
                    NumberAnimation {
                        to: rainDrop.x + 20
                        duration: rainDrop.fallSpeed
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    // Snow effect
    Item {
        id: snowEffect
        anchors.fill: parent
        visible: root.weatherEffect === "snow"
        
        property int flakeCount: Math.round(25 * root.weatherIntensity)

        Repeater {
            model: snowEffect.flakeCount

            Rectangle {
                id: snowFlake
                property real startX: Math.random() * snowEffect.width
                property real startY: -10
                property real fallSpeed: 3000 + Math.random() * 2000
                property real swayAmount: 20 + Math.random() * 30

                x: startX
                y: startY
                width: 3 + Math.random() * 3
                height: width
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.7 + Math.random() * 0.3)

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: snowEffect.visible

                    PropertyAction { value: -10 - Math.random() * 30 }
                    NumberAnimation {
                        to: snowEffect.height + 10
                        duration: snowFlake.fallSpeed
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: snowEffect.visible

                    PropertyAction { value: Math.random() * snowEffect.width }
                    NumberAnimation {
                        to: snowFlake.startX + snowFlake.swayAmount
                        duration: snowFlake.fallSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: snowFlake.startX - snowFlake.swayAmount
                        duration: snowFlake.fallSpeed / 2
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // Thunderstorm effect (rain + lightning)
    Item {
        id: thunderstormEffect
        anchors.fill: parent
        visible: root.weatherEffect === "thunderstorm"

        // Rain component
        Repeater {
            model: 25

            Rectangle {
                id: stormRainDrop
                property real startX: Math.random() * thunderstormEffect.width
                property real fallSpeed: 500 + Math.random() * 300

                x: startX
                y: -10
                width: 2
                height: 15
                radius: 1
                color: Qt.rgba(0.7, 0.85, 1, 0.7)
                rotation: -20

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: thunderstormEffect.visible

                    PropertyAction { value: -15 - Math.random() * 20 }
                    NumberAnimation {
                        to: thunderstormEffect.height + 15
                        duration: stormRainDrop.fallSpeed
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: thunderstormEffect.visible

                    PropertyAction { value: Math.random() * thunderstormEffect.width }
                    NumberAnimation {
                        to: stormRainDrop.x + 30
                        duration: stormRainDrop.fallSpeed
                        easing.type: Easing.Linear
                    }
                }
            }
        }

        // Lightning flash
        Rectangle {
            id: lightningFlash
            anchors.fill: parent
            color: Qt.rgba(1, 1, 0.9, 0.8)
            opacity: 0
            visible: opacity > 0

            SequentialAnimation {
                loops: Animation.Infinite
                running: thunderstormEffect.visible

                PauseAnimation { duration: 3000 + Math.random() * 5000 }
                
                NumberAnimation {
                    target: lightningFlash
                    property: "opacity"
                    to: 0.9
                    duration: 50
                }
                NumberAnimation {
                    target: lightningFlash
                    property: "opacity"
                    to: 0
                    duration: 100
                }
                NumberAnimation {
                    target: lightningFlash
                    property: "opacity"
                    to: 0.7
                    duration: 50
                }
                NumberAnimation {
                    target: lightningFlash
                    property: "opacity"
                    to: 0
                    duration: 150
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // SUN/MOON ARC
    // ═══════════════════════════════════════════════════════════

    // Sun arc container
    Item {
        id: arcContainer
        anchors.fill: parent

        // Arc dimensions - elliptical arc that fits within the container
        property real arcWidth: width - 40  // Horizontal span
        property real arcHeight: Math.min(70, height * 0.5)  // Vertical height of the arc
        property real arcCenterX: width / 2
        property real arcCenterY: height - 12  // Position at bottom edge

        // The arc path (upper half of ellipse only)
        Canvas {
            id: arcCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = WeatherService.effectiveIsDay ? 
                    "rgba(255, 255, 255, 0.3)" : "rgba(255, 255, 255, 0.15)";
                ctx.lineWidth = 1.5;
                
                var cx = arcContainer.arcCenterX;
                var cy = arcContainer.arcCenterY;
                var rx = arcContainer.arcWidth / 2;
                var ry = arcContainer.arcHeight;
                
                // Draw only the upper half of the ellipse manually
                ctx.beginPath();
                ctx.moveTo(cx - rx, cy);
                
                // Use quadratic bezier curves to approximate upper ellipse arc
                var steps = 50;
                for (var i = 0; i <= steps; i++) {
                    var angle = Math.PI - (Math.PI * i / steps);  // PI to 0
                    var x = cx + rx * Math.cos(angle);
                    var y = cy - ry * Math.sin(angle);  // Subtract to go up
                    ctx.lineTo(x, y);
                }
                
                ctx.stroke();
            }

            Component.onCompleted: requestPaint()
            
            Connections {
                target: WeatherService
                function onEffectiveIsDayChanged() { arcCanvas.requestPaint() }
            }
            
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        // Horizon line
        Rectangle {
            x: arcContainer.arcCenterX - arcContainer.arcWidth / 2 - 8
            y: arcContainer.arcCenterY
            width: arcContainer.arcWidth + 16
            height: 1
            color: Qt.rgba(1, 1, 1, 0.2)
        }

        // Sun/Moon indicator
        Rectangle {
            id: celestialBody
            width: 20
            height: 20
            radius: 10

            property real progress: WeatherService.effectiveSunProgress
            
            // Elliptical arc position calculation
            property real angle: Math.PI * (1 - progress)  // PI to 0
            property real posX: arcContainer.arcCenterX + (arcContainer.arcWidth / 2) * Math.cos(angle) - width / 2
            property real posY: arcContainer.arcCenterY - arcContainer.arcHeight * Math.sin(angle) - height / 2

            x: posX
            y: posY

            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

            gradient: Gradient {
                GradientStop { 
                    position: 0.0
                    color: WeatherService.effectiveIsDay ? "#FFF9C4" : "#FFFFFF"
                }
                GradientStop { 
                    position: 0.5
                    color: WeatherService.effectiveIsDay ? "#FFE082" : "#E8E8E8"
                }
                GradientStop { 
                    position: 1.0
                    color: WeatherService.effectiveIsDay ? "#FFB74D" : "#C0C0C0"
                }
            }

            // Outer glow
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 12
                height: parent.height + 12
                radius: width / 2
                color: "transparent"
                border.color: WeatherService.effectiveIsDay ? 
                    Qt.rgba(1, 0.95, 0.7, 0.4) : Qt.rgba(1, 1, 1, 0.2)
                border.width: 3
                z: -1
            }

            // Inner glow
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                radius: width / 2
                color: "transparent"
                border.color: WeatherService.effectiveIsDay ? 
                    Qt.rgba(1, 0.95, 0.7, 0.6) : Qt.rgba(1, 1, 1, 0.3)
                border.width: 2
                z: -1
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // TEXT CONTENT
    // ═══════════════════════════════════════════════════════════

    // Time of day label (top left)
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 2

        Text {
            text: WeatherService.effectiveTimeOfDay
            color: root.textPrimary
            font.family: Config.theme.font
            font.pixelSize: Config.theme.fontSize + 4
            font.weight: Font.Bold
        }

        Text {
            text: WeatherService.effectiveWeatherDescription
            color: root.textSecondary
            font.family: Config.theme.font
            font.pixelSize: Config.theme.fontSize - 2
        }
    }

    // Temperature (top right)
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        text: Math.round(WeatherService.currentTemp) + Config.weather.unit + "°"
        color: root.textPrimary
        font.family: Config.theme.font
        font.pixelSize: Config.theme.fontSize + 6
        font.weight: Font.Medium
    }

    // ═══════════════════════════════════════════════════════════
    // DEBUG CONTROLS
    // ═══════════════════════════════════════════════════════════

    // Debug controls
    Column {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        spacing: 4
        visible: root.showDebugControls && WeatherService.debugMode

        // Hour display and indicator
        Row {
            spacing: 4

            Text {
                text: {
                    var h = Math.floor(WeatherService.debugHour);
                    var m = Math.round((WeatherService.debugHour - h) * 60);
                    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
                }
                color: "#fff"
                font.pixelSize: 11
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 20; height: 20
                radius: 10
                color: WeatherService.debugIsDay ? "#FFE082" : "#C0C0C0"
                Text { 
                    anchors.centerIn: parent
                    text: WeatherService.debugIsDay ? "☀" : "☽"
                    font.pixelSize: 12
                }
            }
        }

        // Hour controls
        Row {
            spacing: 4

            Rectangle {
                width: 24; height: 20
                radius: 4
                color: "#555"
                Text { anchors.centerIn: parent; text: "−1h"; font.pixelSize: 8; color: "#fff" }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: WeatherService.debugHour = (WeatherService.debugHour - 1 + 24) % 24
                }
            }
            Rectangle {
                width: 24; height: 20
                radius: 4
                color: "#555"
                Text { anchors.centerIn: parent; text: "+1h"; font.pixelSize: 8; color: "#fff" }
                MouseArea { 
                    anchors.fill: parent
                    onClicked: WeatherService.debugHour = (WeatherService.debugHour + 1) % 24
                }
            }
        }

        // Weather code control
        Row {
            spacing: 4

            Rectangle {
                width: 60; height: 20
                radius: 4
                color: "#555"
                
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: WeatherService.effectiveWeatherSymbol; font.pixelSize: 12 }
                    Text { 
                        text: WeatherService.effectiveWeatherEffect.substring(0, 3)
                        font.pixelSize: 8
                        color: "#fff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: {
                        // All effect codes: clear, clouds, fog, drizzle, rain, snow, thunderstorm
                        var codes = [0, 2, 3, 45, 51, 61, 65, 71, 75, 80, 95, 96];
                        var idx = codes.indexOf(WeatherService.debugWeatherCode);
                        WeatherService.debugWeatherCode = codes[(idx + 1) % codes.length];
                    }
                }
            }
        }
    }

    // Debug toggle button
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 8
        width: 20; height: 20
        radius: 10
        color: WeatherService.debugMode ? Colors.primary : "#555"
        opacity: 0.8
        visible: root.showDebugControls

        Text {
            anchors.centerIn: parent
            text: "D"
            font.pixelSize: 10
            font.bold: true
            color: "#fff"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: WeatherService.debugMode = !WeatherService.debugMode
        }
    }
}
