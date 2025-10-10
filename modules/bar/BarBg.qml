import QtQuick
import QtQuick.Effects
import qs.modules.theme
import qs.modules.corners
import qs.config

Rectangle {
    id: root
    required property string position
    
    visible: Config.bar.showBackground
    opacity: Config.bar.bgOpacity

    gradient: Gradient {
        orientation: Config.bar.barOrientation === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
        
        GradientStop {
            property var stopData: Config.bar.barColor[0] || ["surface", 0.0]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
        
        GradientStop {
            property var stopData: Config.bar.barColor[1] || Config.bar.barColor[Config.bar.barColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
        
        GradientStop {
            property var stopData: Config.bar.barColor[2] || Config.bar.barColor[Config.bar.barColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
        
        GradientStop {
            property var stopData: Config.bar.barColor[3] || Config.bar.barColor[Config.bar.barColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
        
        GradientStop {
            property var stopData: Config.bar.barColor[4] || Config.bar.barColor[Config.bar.barColor.length - 1]
            position: stopData[1]
            color: {
                const colorValue = stopData[0];
                if (colorValue.startsWith("#") || colorValue.startsWith("rgba") || colorValue.startsWith("rgb")) {
                    return colorValue;
                }
                return Colors[colorValue] || colorValue;
            }
        }
    }

    RoundCorner {
        id: cornerLeft
        visible: Config.theme.enableCorners
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        x: root.position === "left" ? parent.width : (root.position === "right" ? -size : 0)
        y: root.position === "top" ? parent.height : (root.position === "bottom" ? -size : 0)
        corner: {
            if (root.position === "top") return RoundCorner.CornerEnum.TopLeft
            if (root.position === "bottom") return RoundCorner.CornerEnum.BottomLeft
            if (root.position === "left") return RoundCorner.CornerEnum.TopLeft
            if (root.position === "right") return RoundCorner.CornerEnum.TopRight
        }
        color: parent.color
    }

    RoundCorner {
        id: cornerRight
        visible: Config.theme.enableCorners
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        x: root.position === "left" ? parent.width : (root.position === "right" ? -size : parent.width - size)
        y: root.position === "top" ? parent.height : (root.position === "bottom" ? -size : parent.height - size)
        corner: {
            if (root.position === "top") return RoundCorner.CornerEnum.TopRight
            if (root.position === "bottom") return RoundCorner.CornerEnum.BottomRight
            if (root.position === "left") return RoundCorner.CornerEnum.BottomLeft
            if (root.position === "right") return RoundCorner.CornerEnum.BottomRight
        }
        color: parent.color
    }
}
