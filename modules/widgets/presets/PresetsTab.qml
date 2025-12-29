import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

// Import Button and CheckBox
import "." as Presets

Item {
    id: root
    focus: true

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property var presets: []

    // Create mode state
    property bool createMode: false
    property string presetNameToCreate: ""
    property var selectedConfigFiles: availableConfigFiles.slice() // Select all by default

    // Available config files to choose from
    readonly property var availableConfigFiles: [
        "ai.js", "bar.js", "desktop.js", "dock.js", "hyprland.js",
        "lockscreen.js", "notch.js", "overview.js", "performance.js",
        "prefix.js", "system.js", "theme.js", "weather.js", "workspaces.js"
    ]

    // List model
    ListModel {
        id: presetsModel
    }

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && presetsModel.count > 0) {
            resultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredPresets();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        searchInput.focusInput();
        updateFilteredPresets();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredPresets() {
        var newFilteredPresets = [];

        var createButtonText = "Create new preset";
        var isCreateSpecific = false;
        var presetNameToCreate = "";

        if (searchText.length === 0) {
            newFilteredPresets = presets.slice();
        } else {
            newFilteredPresets = presets.filter(function (preset) {
                return preset.name.toLowerCase().includes(searchText.toLowerCase());
            });

            if (newFilteredPresets.length === 0 && searchText.length > 0) {
                createButtonText = `Create preset "${searchText}"`;
                isCreateSpecific = true;
                presetNameToCreate = searchText;
            }
        }

        if (!createMode) {
            newFilteredPresets.unshift({
                name: createButtonText,
                isCreateButton: !isCreateSpecific,
                isCreateSpecificButton: isCreateSpecific,
                presetNameToCreate: presetNameToCreate,
                configFiles: [],
                icon: "plus"
            });
        }

        // Update model
        presetsModel.clear();
        for (var i = 0; i < newFilteredPresets.length; i++) {
            var preset = newFilteredPresets[i];
            presetsModel.append({
                presetId: preset.isCreateButton || preset.isCreateSpecificButton ? "__create__" : preset.name,
                presetData: preset
            });
        }

        if (!createMode) {
            if (searchText.length > 0 && newFilteredPresets.length > 0) {
                selectedIndex = 0;
                resultsList.currentIndex = 0;
            } else if (searchText.length === 0) {
                selectedIndex = -1;
                resultsList.currentIndex = -1;
            }
        }
    }

    function enterCreateMode(presetName) {
        createMode = true;
        presetNameToCreate = presetName || "";
        selectedConfigFiles = availableConfigFiles.slice(); // Select all by default
        root.forceActiveFocus();
    }

    function cancelCreateMode() {
        createMode = false;
        presetNameToCreate = "";
        selectedConfigFiles = availableConfigFiles.slice();
        searchInput.focusInput();
        updateFilteredPresets();
    }

    function confirmCreatePreset() {
        if (presetNameToCreate.trim() !== "" && selectedConfigFiles.length > 0) {
            PresetsService.savePreset(presetNameToCreate.trim(), selectedConfigFiles);
            cancelCreateMode();
        }
    }

    function loadPreset(presetName) {
        PresetsService.loadPreset(presetName);
        Visibilities.setActiveModule(""); // Close popup
    }

    // Connect to service
    Connections {
        target: PresetsService
        function onPresetsUpdated() {
            root.presets = PresetsService.presets;
            updateFilteredPresets();
        }
    }

    Component.onCompleted: {
        root.presets = PresetsService.presets;
        updateFilteredPresets();
    }

    implicitWidth: 400
    implicitHeight: 7 * 48 + 56

    MouseArea {
        anchors.fill: parent
        enabled: root.createMode
        z: -10

        onClicked: {
            if (root.createMode) {
                root.cancelCreateMode();
            }
        }
    }

    Behavior on height {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Left panel: Search + Lista
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Search input
            SearchInput {
                id: searchInput
                width: parent.width
                height: 48
                anchors.top: parent.top
                text: root.searchText
                placeholderText: createMode ? "Enter preset name..." : "Search or create preset..."
                iconText: ""
                prefixIcon: ""

                onSearchTextChanged: text => {
                    if (createMode) {
                        root.presetNameToCreate = text;
                    } else {
                        root.searchText = text;
                    }
                }

                onAccepted: {
                    if (createMode) {
                        root.confirmCreatePreset();
                    } else {
                        if (root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
                            let selectedPreset = root.presets[root.selectedIndex];
                            if (selectedPreset) {
                                if (selectedPreset.isCreateSpecificButton) {
                                    root.enterCreateMode(selectedPreset.presetNameToCreate);
                                } else if (selectedPreset.isCreateButton) {
                                    root.enterCreateMode();
                                } else {
                                    root.loadPreset(selectedPreset.name);
                                }
                            }
                        }
                    }
                }

                onEscapePressed: {
                    if (createMode) {
                        root.cancelCreateMode();
                    } else {
                        Visibilities.setActiveModule("");
                    }
                }

                onDownPressed: {
                    if (!createMode && resultsList.count > 0) {
                        if (root.selectedIndex === -1) {
                            root.selectedIndex = 0;
                            resultsList.currentIndex = 0;
                        } else if (root.selectedIndex < resultsList.count - 1) {
                            root.selectedIndex++;
                            resultsList.currentIndex = root.selectedIndex;
                        }
                    }
                }

                onUpPressed: {
                    if (!createMode) {
                        if (root.selectedIndex > 0) {
                            root.selectedIndex--;
                            resultsList.currentIndex = root.selectedIndex;
                        } else if (root.selectedIndex === 0 && root.searchText.length === 0) {
                            root.selectedIndex = -1;
                            resultsList.currentIndex = -1;
                        }
                    }
                }
            }

            ListView {
                id: resultsList
                width: parent.width
                anchors.top: searchInput.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 8
                visible: !createMode
                clip: true
                interactive: !createMode
                cacheBuffer: 96
                reuseItems: false

                model: presetsModel
                currentIndex: root.selectedIndex

                Behavior on contentY {
                    enabled: Config.animDuration > 0 && resultsList.enableScrollAnimation && !resultsList.moving
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                property bool enableScrollAnimation: true

                onCurrentIndexChanged: {
                    if (currentIndex !== root.selectedIndex) {
                        root.selectedIndex = currentIndex;
                    }
                }

                delegate: Rectangle {
                    required property string presetId
                    required property var presetData

                    property var modelData: presetData

                    width: resultsList.width
                    height: 48
                    color: "transparent"
                    radius: 16

                    Behavior on height {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                    clip: true

                    property bool isExpanded: false
                    property color textColor: {
                        if (resultsList.currentIndex === model.index) {
                            return Styling.styledRectItem("primary");
                        } else {
                            return Colors.overSurface;
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: !resultsList.moving
                        acceptedButtons: Qt.LeftButton

                        onEntered: {
                            if (resultsList.moving)
                                return;
                            if (!createMode) {
                                root.selectedIndex = index;
                                resultsList.currentIndex = index;
                            }
                        }

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.isCreateSpecificButton) {
                                    root.enterCreateMode(modelData.presetNameToCreate);
                                } else if (modelData.isCreateButton) {
                                    root.enterCreateMode();
                                } else {
                                    root.loadPreset(modelData.name);
                                }
                            }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        height: 32
                        spacing: 8

                        StyledRect {
                            id: iconBackground
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            variant: {
                                if (resultsList.currentIndex === model.index) {
                                    return "overprimary";
                                } else if (modelData.isCreateButton) {
                                    return "primary";
                                } else {
                                    return "common";
                                }
                            }
                            radius: Styling.radius(-4)

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (modelData.isCreateButton || modelData.isCreateSpecificButton) {
                                        return Icons.plus;
                                    } else {
                                        return Icons.magicWand;
                                    }
                                }
                                color: iconBackground.item
                                font.family: Icons.font
                                font.pixelSize: 16
                                textFormat: Text.RichText
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name
                                color: textColor
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    if (modelData.isCreateButton || modelData.isCreateSpecificButton) {
                                        return "Create a new preset";
                                    } else {
                                        return `${modelData.configFiles.length} config files`;
                                    }
                                }
                                color: Colors.outline
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                elide: Text.ElideRight
                                visible: !modelData.isCreateButton && !modelData.isCreateSpecificButton
                            }
                        }
                    }

                    StyledRect {
                        anchors.fill: parent
                        anchors.topMargin: 0
                        anchors.bottomMargin: 0
                        variant: "primary"
                        radius: Styling.radius(4)
                        visible: root.selectedIndex >= 0 && root.selectedIndex === index

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: createMode
                    z: 1000
                    acceptedButtons: Qt.LeftButton

                    onClicked: mouse => {
                        if (createMode) {
                            root.cancelCreateMode();
                            mouse.accepted = true;
                        }
                    }
                }
            }

            // Create mode UI
            Item {
                anchors.fill: parent
                visible: createMode
                z: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Text {
                        text: "Create New Preset"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize + 4
                        font.weight: Font.Bold
                        color: Colors.overSurface
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Preset name:"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overSurface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    TextField {
                        Layout.fillWidth: true
                        text: root.presetNameToCreate
                        placeholderText: "Enter preset name..."
                        onTextChanged: root.presetNameToCreate = text
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                    }

                    Text {
                        text: "Select config files to save:"
                        font.family: Config.theme.font
                        font.pixelSize: Config.theme.fontSize
                        color: Colors.overSurface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Repeater {
                            model: availableConfigFiles

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8

                                    CheckBox {
                                        checked: root.selectedConfigFiles.includes(modelData)
                                        onCheckedChanged: {
                                            if (checked && !root.selectedConfigFiles.includes(modelData)) {
                                                root.selectedConfigFiles.push(modelData);
                                            } else if (!checked) {
                                                const index = root.selectedConfigFiles.indexOf(modelData);
                                                if (index > -1) {
                                                    root.selectedConfigFiles.splice(index, 1);
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData
                                        color: Colors.overSurface
                                        font.family: Config.theme.font
                                        font.pixelSize: Config.theme.fontSize
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Button {
                            text: "Cancel"
                            onClicked: root.cancelCreateMode()
                        }

                        Button {
                            text: "Create"
                            enabled: root.presetNameToCreate.trim() !== "" && root.selectedConfigFiles.length > 0
                            onClicked: root.confirmCreatePreset()
                        }
                    }
                }
            }
        }
    }
}