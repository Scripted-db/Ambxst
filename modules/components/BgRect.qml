import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.theme
import qs.config

ClippingRectangle {
    color: Colors.background
    radius: Config.roundness
    border.color: Colors.adapter.overBackground
    border.width: Config.theme.currentTheme === "sticker" ? 4 : 0

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowBlur: 1
        shadowColor: Colors.adapter.shadow
        shadowOpacity: Config.theme.shadowOpacity
    }
}
