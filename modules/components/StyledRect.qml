pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.config
import qs.modules.theme

ClippingRectangle {
    id: root

    clip: true
    antialiasing: true
    contentUnderBorder: true

    required property string variant

    property string gradientOrientation: "vertical"
    property bool enableShadow: false
    property bool enableBorder: true
    property bool animateRadius: true
    property real backgroundOpacity: -1  // -1 means use config value

    // Static mode: caches the rendered content to a texture, reducing GPU work.
    // Use for StyledRects that don't animate or change frequently.
    // Automatically disabled during theme changes to allow repaint.
    property bool cacheContent: false
    readonly property bool _effectiveCacheEnabled: cacheContent && !_isInvalidating

    // Track when we're invalidating due to theme change
    property bool _isInvalidating: false

    readonly property var variantConfig: Styling.getStyledRectConfig(variant) || {}

    readonly property var gradientStops: variantConfig.gradient

    readonly property string gradientType: variantConfig.gradientType

    readonly property real gradientAngle: variantConfig.gradientAngle

    readonly property real gradientCenterX: variantConfig.gradientCenterX

    readonly property real gradientCenterY: variantConfig.gradientCenterY

    readonly property real halftoneDotMin: variantConfig.halftoneDotMin

    readonly property real halftoneDotMax: variantConfig.halftoneDotMax

    readonly property real halftoneStart: variantConfig.halftoneStart

    readonly property real halftoneEnd: variantConfig.halftoneEnd

    readonly property color halftoneDotColor: Config.resolveColor(variantConfig.halftoneDotColor)

    readonly property color halftoneBackgroundColor: Config.resolveColor(variantConfig.halftoneBackgroundColor)

    readonly property var borderData: variantConfig.border

    readonly property color solidColor: Config.resolveColor(variantConfig.color)
    readonly property bool hasSolidColor: variantConfig.color !== undefined && variantConfig.color !== ""

    readonly property color itemColor: Config.resolveColor(variantConfig.itemColor)
    property color item: itemColor

    readonly property real rectOpacity: backgroundOpacity >= 0 ? backgroundOpacity : variantConfig.opacity

    // Check if this variant needs a gradient texture
    readonly property bool needsGradientTexture: gradientType === "linear" || gradientType === "radial"

    radius: variantConfig.radius !== undefined ? variantConfig.radius : Styling.radius(0)
    color: (hasSolidColor && gradientType !== "linear" && gradientType !== "radial" && gradientType !== "halftone") ? solidColor : "transparent"

    Behavior on radius {
        enabled: root.animateRadius && Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration / 4
        }
    }

    // Local gradient texture - only created when needed (lazy loading)
    Loader {
        id: gradientTextureLoader
        active: root.needsGradientTexture
        visible: false

        sourceComponent: Item {
            id: textureContainer

            // Track cache version to know when to repaint
            property int cacheVersion: GradientCache.version

            // Track if canvas has been painted at least once
            property bool ready: false

            Canvas {
                id: gradientCanvas
                width: 256
                height: 32
                visible: false

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const stops = GradientCache.getResolvedStops(root.gradientStops);
                    if (!stops || stops.length === 0)
                        return;

                    const grad = ctx.createLinearGradient(0, 0, width, 0);
                    for (let i = 0; i < stops.length; i++) {
                        const s = stops[i];
                        grad.addColorStop(s[1], s[0]);
                    }

                    ctx.fillStyle = grad;
                    ctx.fillRect(0, 0, width, height);
                }

                onPainted: textureContainer.ready = true

                Component.onCompleted: requestPaint()
            }

            ShaderEffectSource {
                id: gradientSource
                sourceItem: gradientCanvas
                hideSource: true
                smooth: true
                wrapMode: ShaderEffectSource.ClampToEdge
                visible: false
                // Only capture when canvas is ready
                live: textureContainer.ready
            }

            // Repaint when cache version changes (theme colors changed)
            onCacheVersionChanged: gradientCanvas.requestPaint()

            // Repaint when gradient stops change (variant changed)
            Connections {
                target: root
                function onGradientStopsChanged() {
                    gradientCanvas.requestPaint();
                }
            }

            // Expose the source for shaders (only when ready)
            property var source: ready ? gradientSource : null
        }
    }

    // Linear gradient shader
    Loader {
        anchors.fill: parent
        active: root.gradientType === "linear" && gradientTextureLoader.item?.source !== null

        sourceComponent: ShaderEffect {
            opacity: root.rectOpacity

            property real angle: root.gradientAngle
            property real canvasWidth: width
            property real canvasHeight: height
            property var gradTex: gradientTextureLoader.item?.source ?? null

            vertexShader: "linear_gradient.vert.qsb"
            fragmentShader: "linear_gradient.frag.qsb"
        }
    }

    // Radial gradient shader
    Loader {
        anchors.fill: parent
        active: root.gradientType === "radial" && gradientTextureLoader.item?.source !== null

        sourceComponent: ShaderEffect {
            opacity: root.rectOpacity

            property real centerX: root.gradientCenterX
            property real centerY: root.gradientCenterY
            property real canvasWidth: width
            property real canvasHeight: height
            property var gradTex: gradientTextureLoader.item?.source ?? null

            vertexShader: "radial_gradient.vert.qsb"
            fragmentShader: "radial_gradient.frag.qsb"
        }
    }

    // Halftone gradient - no texture needed, purely procedural
    Loader {
        anchors.fill: parent
        active: root.gradientType === "halftone"

        sourceComponent: ShaderEffect {
            opacity: root.rectOpacity

            property real angle: root.gradientAngle
            property real dotMinSize: root.halftoneDotMin
            property real dotMaxSize: root.halftoneDotMax
            property real gradientStart: root.halftoneStart
            property real gradientEnd: root.halftoneEnd
            property vector4d dotColor: {
                const c = root.halftoneDotColor || Qt.rgba(1, 1, 1, 1);
                return Qt.vector4d(c.r, c.g, c.b, c.a);
            }
            property vector4d backgroundColor: {
                const c = root.halftoneBackgroundColor || Qt.rgba(0, 0.5, 1, 1);
                return Qt.vector4d(c.r, c.g, c.b, c.a);
            }
            property real canvasWidth: width
            property real canvasHeight: height

            vertexShader: "halftone.vert.qsb"
            fragmentShader: "halftone.frag.qsb"
        }
    }

    // Shadow effect and/or content caching
    // When cacheContent is true, renders to texture once (reduces GPU redraw)
    // When enableShadow is true, applies shadow effect
    layer.enabled: enableShadow || _effectiveCacheEnabled
    layer.effect: enableShadow ? shadowEffect : null

    Component {
        id: shadowEffect
        Shadow {}
    }

    // Temporarily disable cache when theme changes to allow repaint
    Connections {
        target: GradientCache
        function onVersionChanged() {
            if (root.cacheContent) {
                root._isInvalidating = true;
                // Re-enable cache after a frame to capture the new render
                Qt.callLater(() => { root._isInvalidating = false; });
            }
        }
    }

    // Border overlay to avoid ClippingRectangle artifacts
    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        color: "transparent"
        border.color: Config.resolveColor(borderData[0])
        border.width: borderData[1]
        visible: root.enableBorder
    }
}
