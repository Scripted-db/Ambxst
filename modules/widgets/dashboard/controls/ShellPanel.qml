pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root

    property int maxContentWidth: 480
    readonly property int contentWidth: Math.min(width, maxContentWidth)
    readonly property real sideMargin: (width - contentWidth) / 2

    // Inline component for toggle rows
    component ToggleRow: RowLayout {
        id: toggleRowRoot
        property string label: ""
        property bool checked: false
        signal toggled(bool value)

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: toggleRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        Switch {
            id: toggleSwitch
            checked: toggleRowRoot.checked
            onCheckedChanged: toggleRowRoot.toggled(checked)

            indicator: Rectangle {
                implicitWidth: 40
                implicitHeight: 20
                x: toggleSwitch.leftPadding
                y: parent.height / 2 - height / 2
                radius: height / 2
                color: toggleSwitch.checked ? Colors.primary : Colors.surfaceBright
                border.color: toggleSwitch.checked ? Colors.primary : Colors.outline

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }

                Rectangle {
                    x: toggleSwitch.checked ? parent.width - width - 2 : 2
                    y: 2
                    width: parent.height - 4
                    height: width
                    radius: width / 2
                    color: toggleSwitch.checked ? Colors.background : Colors.overSurfaceVariant

                    Behavior on x {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                    }
                }
            }
            background: null
        }
    }

    // Inline component for number input rows
    component NumberInputRow: RowLayout {
        id: numberInputRowRoot
        property string label: ""
        property int value: 0
        property int minValue: 0
        property int maxValue: 100
        property string suffix: ""
        signal valueEdited(int newValue)

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: numberInputRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.fillWidth: true
        }

        StyledRect {
            variant: "common"
            Layout.preferredWidth: 60
            Layout.preferredHeight: 32
            radius: Styling.radius(-2)

            TextInput {
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                selectByMouse: true
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator { bottom: numberInputRowRoot.minValue; top: numberInputRowRoot.maxValue }
                text: numberInputRowRoot.value.toString()

                onEditingFinished: {
                    let newVal = parseInt(text);
                    if (!isNaN(newVal)) {
                        newVal = Math.max(numberInputRowRoot.minValue, Math.min(numberInputRowRoot.maxValue, newVal));
                        numberInputRowRoot.valueEdited(newVal);
                    }
                }
            }
        }

        Text {
            text: numberInputRowRoot.suffix
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overSurfaceVariant
            visible: suffix !== ""
        }
    }

    // Inline component for text input rows
    component TextInputRow: RowLayout {
        id: textInputRowRoot
        property string label: ""
        property string value: ""
        property string placeholder: ""
        signal valueEdited(string newValue)

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: textInputRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.preferredWidth: 100
        }

        StyledRect {
            variant: "common"
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Styling.radius(-2)

            TextInput {
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                selectByMouse: true
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                text: textInputRowRoot.value

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: textInputRowRoot.placeholder
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    color: Colors.overSurfaceVariant
                    visible: parent.text === ""
                }

                onEditingFinished: {
                    textInputRowRoot.valueEdited(text);
                }
            }
        }
    }

    // Inline component for segmented selector rows
    component SelectorRow: RowLayout {
        id: selectorRowRoot
        property string label: ""
        property var options: []  // Array of { label: "...", value: "..." }
        property string value: ""
        signal valueSelected(string newValue)

        function getIndexFromValue(val: string): int {
            for (let i = 0; i < options.length; i++) {
                if (options[i].value === val) return i;
            }
            return 0;
        }

        function getValueFromIndex(idx: int): string {
            if (idx >= 0 && idx < options.length) {
                return options[idx].value;
            }
            return "";
        }

        Layout.fillWidth: true
        spacing: 8

        Text {
            text: selectorRowRoot.label
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(0)
            color: Colors.overBackground
            Layout.preferredWidth: 100
        }

        SegmentedSwitch {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            buttonSize: (Layout.fillWidth ? (parent.width - 100 - 8) / selectorRowRoot.options.length : 60)
            options: selectorRowRoot.options.map(opt => opt.label)
            currentIndex: selectorRowRoot.getIndexFromValue(selectorRowRoot.value)
            onIndexChanged: index => {
                let newValue = selectorRowRoot.getValueFromIndex(index);
                if (newValue !== "") {
                    selectorRowRoot.valueSelected(newValue);
                }
            }
        }
    }

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // Header wrapper
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: "Shell"
                }
            }

            // Content wrapper - centered
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    // ═══════════════════════════════════════════════════════════════
                    // BAR SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Bar"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        SelectorRow {
                            label: "Position"
                            options: [
                                { label: "Top", value: "top" },
                                { label: "Bottom", value: "bottom" }
                            ]
                            value: Config.bar.position ?? "top"
                            onValueSelected: newValue => {
                                Config.bar.position = newValue;
                                Config.saveConfig("bar");
                            }
                        }

                        TextInputRow {
                            label: "Launcher Icon"
                            value: Config.bar.launcherIcon ?? ""
                            placeholder: "Path to icon..."
                            onValueEdited: newValue => {
                                Config.bar.launcherIcon = newValue;
                                Config.saveConfig("bar");
                            }
                        }

                        ToggleRow {
                            label: "Launcher Icon Tint"
                            checked: Config.bar.launcherIconTint ?? true
                            onToggled: value => {
                                Config.bar.launcherIconTint = value;
                                Config.saveConfig("bar");
                            }
                        }

                        ToggleRow {
                            label: "Launcher Icon Full Tint"
                            checked: Config.bar.launcherIconFullTint ?? true
                            onToggled: value => {
                                Config.bar.launcherIconFullTint = value;
                                Config.saveConfig("bar");
                            }
                        }

                        NumberInputRow {
                            label: "Launcher Icon Size"
                            value: Config.bar.launcherIconSize ?? 24
                            minValue: 12
                            maxValue: 64
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.bar.launcherIconSize = newValue;
                                Config.saveConfig("bar");
                            }
                        }

                        ToggleRow {
                            label: "Enable Firefox Player"
                            checked: Config.bar.enableFirefoxPlayer ?? false
                            onToggled: value => {
                                Config.bar.enableFirefoxPlayer = value;
                                Config.saveConfig("bar");
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // ═══════════════════════════════════════════════════════════════
                    // NOTCH SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Notch"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        SelectorRow {
                            label: "Theme"
                            options: [
                                { label: "Default", value: "default" },
                                { label: "Minimal", value: "minimal" },
                                { label: "Compact", value: "compact" }
                            ]
                            value: Config.notch.theme ?? "default"
                            onValueSelected: newValue => {
                                Config.notch.theme = newValue;
                                Config.saveConfig("notch");
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // ═══════════════════════════════════════════════════════════════
                    // WORKSPACES SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Workspaces"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        NumberInputRow {
                            label: "Shown"
                            value: Config.workspaces.shown ?? 10
                            minValue: 1
                            maxValue: 20
                            onValueEdited: newValue => {
                                Config.workspaces.shown = newValue;
                                Config.saveConfig("workspaces");
                            }
                        }

                        ToggleRow {
                            label: "Show App Icons"
                            checked: Config.workspaces.showAppIcons ?? true
                            onToggled: value => {
                                Config.workspaces.showAppIcons = value;
                                Config.saveConfig("workspaces");
                            }
                        }

                        ToggleRow {
                            label: "Always Show Numbers"
                            checked: Config.workspaces.alwaysShowNumbers ?? false
                            onToggled: value => {
                                Config.workspaces.alwaysShowNumbers = value;
                                Config.saveConfig("workspaces");
                            }
                        }

                        ToggleRow {
                            label: "Show Numbers"
                            checked: Config.workspaces.showNumbers ?? false
                            onToggled: value => {
                                Config.workspaces.showNumbers = value;
                                Config.saveConfig("workspaces");
                            }
                        }

                        ToggleRow {
                            label: "Dynamic"
                            checked: Config.workspaces.dynamic ?? false
                            onToggled: value => {
                                Config.workspaces.dynamic = value;
                                Config.saveConfig("workspaces");
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // ═══════════════════════════════════════════════════════════════
                    // OVERVIEW SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Overview"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        NumberInputRow {
                            label: "Rows"
                            value: Config.overview.rows ?? 2
                            minValue: 1
                            maxValue: 5
                            onValueEdited: newValue => {
                                Config.overview.rows = newValue;
                                Config.saveConfig("overview");
                            }
                        }

                        NumberInputRow {
                            label: "Columns"
                            value: Config.overview.columns ?? 5
                            minValue: 1
                            maxValue: 10
                            onValueEdited: newValue => {
                                Config.overview.columns = newValue;
                                Config.saveConfig("overview");
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Scale"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overBackground
                                Layout.preferredWidth: 100
                            }

                            StyledSlider {
                                id: overviewScaleSlider
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                progressColor: Colors.primary
                                tooltipText: `${(value * 0.2).toFixed(2)}`
                                scroll: true
                                value: ((Config.overview.scale ?? 0.1) / 0.2)

                                onValueChanged: {
                                    let newScale = value * 0.2;
                                    if (Math.abs(newScale - (Config.overview.scale ?? 0.1)) > 0.001) {
                                        Config.overview.scale = newScale;
                                        Config.saveConfig("overview");
                                    }
                                }
                            }

                            Text {
                                text: ((Config.overview.scale ?? 0.1)).toFixed(2)
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                                color: Colors.overBackground
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 40
                            }
                        }

                        NumberInputRow {
                            label: "Workspace Spacing"
                            value: Config.overview.workspaceSpacing ?? 4
                            minValue: 0
                            maxValue: 20
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.overview.workspaceSpacing = newValue;
                                Config.saveConfig("overview");
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // ═══════════════════════════════════════════════════════════════
                    // LOCKSCREEN SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Lockscreen"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        SelectorRow {
                            label: "Position"
                            options: [
                                { label: "Top", value: "top" },
                                { label: "Center", value: "center" },
                                { label: "Bottom", value: "bottom" }
                            ]
                            value: Config.lockscreen.position ?? "bottom"
                            onValueSelected: newValue => {
                                Config.lockscreen.position = newValue;
                                Config.saveConfig("lockscreen");
                            }
                        }
                    }

                    Separator { Layout.fillWidth: true }

                    // ═══════════════════════════════════════════════════════════════
                    // DESKTOP SECTION
                    // ═══════════════════════════════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Desktop"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                            Layout.bottomMargin: -4
                        }

                        ToggleRow {
                            label: "Enabled"
                            checked: Config.desktop.enabled ?? false
                            onToggled: value => {
                                Config.desktop.enabled = value;
                                Config.saveConfig("desktop");
                            }
                        }

                        NumberInputRow {
                            label: "Icon Size"
                            value: Config.desktop.iconSize ?? 40
                            minValue: 24
                            maxValue: 96
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.desktop.iconSize = newValue;
                                Config.saveConfig("desktop");
                            }
                        }

                        NumberInputRow {
                            label: "Vertical Spacing"
                            value: Config.desktop.spacingVertical ?? 16
                            minValue: 0
                            maxValue: 48
                            suffix: "px"
                            onValueEdited: newValue => {
                                Config.desktop.spacingVertical = newValue;
                                Config.saveConfig("desktop");
                            }
                        }

                        SelectorRow {
                            label: "Text Color"
                            options: [
                                { label: "Over BG", value: "overBackground" },
                                { label: "Primary", value: "primary" },
                                { label: "Secondary", value: "secondary" }
                            ]
                            value: Config.desktop.textColor ?? "overBackground"
                            onValueSelected: newValue => {
                                Config.desktop.textColor = newValue;
                                Config.saveConfig("desktop");
                            }
                        }
                    }

                    // Bottom padding
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                    }
                }
            }
        }
    }
}
