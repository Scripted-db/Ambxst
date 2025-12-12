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

    // Current category being viewed
    property string currentCategory: "ambxst"

    // Edit mode state
    property bool editMode: false
    property int editingIndex: -1
    property var editingBind: null
    property bool isEditingAmbxst: false

    // Edit form state
    property var editModifiers: []
    property string editKey: ""
    property string editDispatcher: ""
    property string editArgument: ""
    property string editFlags: ""

    readonly property var availableModifiers: ["SUPER", "SHIFT", "CTRL", "ALT"]

    function openEditDialog(bind, index, isAmbxst) {
        root.editingIndex = index;
        root.editingBind = bind;
        root.isEditingAmbxst = isAmbxst;

        // Initialize edit form state
        const bindData = isAmbxst ? bind.bind : bind;
        root.editModifiers = bindData.modifiers ? bindData.modifiers.slice() : [];
        root.editKey = bindData.key || "";
        root.editDispatcher = bindData.dispatcher || "";
        root.editArgument = bindData.argument || "";
        root.editFlags = bindData.flags || "";

        root.editMode = true;
    }

    function closeEditDialog() {
        root.editMode = false;
    }

    function hasModifier(mod) {
        return root.editModifiers.indexOf(mod) !== -1;
    }

    function toggleModifier(mod) {
        let newMods = [];
        let found = false;
        for (let i = 0; i < root.editModifiers.length; i++) {
            if (root.editModifiers[i] === mod) {
                found = true;
            } else {
                newMods.push(root.editModifiers[i]);
            }
        }
        if (!found) {
            newMods.push(mod);
        }
        root.editModifiers = newMods;
    }

    function saveEdit() {
        if (root.isEditingAmbxst) {
            // Save ambxst bind
            const path = root.editingBind.path.split(".");
            // path = ["ambxst", "dashboard"|"system", "bindName"]
            const section = path[1];
            const bindName = path[2];

            const adapter = Config.keybindsLoader.adapter;
            if (adapter && adapter.ambxst && adapter.ambxst[section] && adapter.ambxst[section][bindName]) {
                adapter.ambxst[section][bindName].modifiers = root.editModifiers;
                adapter.ambxst[section][bindName].key = root.editKey;
                // dispatcher and argument are fixed for ambxst binds
            }
        } else {
            // Save custom bind
            const customBinds = Config.keybindsLoader.adapter.custom;
            if (customBinds && customBinds[root.editingIndex]) {
                let newBinds = [];
                for (let i = 0; i < customBinds.length; i++) {
                    if (i === root.editingIndex) {
                        let updatedBind = Object.assign({}, customBinds[i]);
                        updatedBind.modifiers = root.editModifiers;
                        updatedBind.key = root.editKey;
                        updatedBind.dispatcher = root.editDispatcher;
                        updatedBind.argument = root.editArgument;
                        if (root.editFlags) {
                            updatedBind.flags = root.editFlags;
                        }
                        newBinds.push(updatedBind);
                    } else {
                        newBinds.push(customBinds[i]);
                    }
                }
                Config.keybindsLoader.adapter.custom = newBinds;
            }
        }

        root.editMode = false;
    }

    readonly property var categories: [
        { id: "ambxst", label: "Ambxst", icon: Icons.widgets },
        { id: "custom", label: "Custom", icon: Icons.gear }
    ]

    function formatModifiers(modifiers) {
        if (!modifiers || modifiers.length === 0) return "";
        return modifiers.join(" + ");
    }

    function formatKeybind(bind) {
        const mods = formatModifiers(bind.modifiers);
        return mods ? mods + " + " + bind.key : bind.key;
    }

    // Get ambxst binds as a flat list
    function getAmbxstBinds() {
        const adapter = Config.keybindsLoader.adapter;
        if (!adapter || !adapter.ambxst) return [];

        const binds = [];
        const ambxst = adapter.ambxst;

        // Dashboard binds
        if (ambxst.dashboard) {
            const dashboardKeys = ["widgets", "clipboard", "emoji", "tmux", "kanban", "wallpapers", "assistant", "notes"];
            for (const key of dashboardKeys) {
                if (ambxst.dashboard[key]) {
                    binds.push({
                        category: "Dashboard",
                        name: key.charAt(0).toUpperCase() + key.slice(1),
                        path: "ambxst.dashboard." + key,
                        bind: ambxst.dashboard[key]
                    });
                }
            }
        }

        // System binds
        if (ambxst.system) {
            const systemKeys = ["overview", "powermenu", "config", "lockscreen"];
            for (const key of systemKeys) {
                if (ambxst.system[key]) {
                    binds.push({
                        category: "System",
                        name: key.charAt(0).toUpperCase() + key.slice(1),
                        path: "ambxst.system." + key,
                        bind: ambxst.system[key]
                    });
                }
            }
        }

        return binds;
    }

    // Get custom binds
    function getCustomBinds() {
        const adapter = Config.keybindsLoader.adapter;
        if (!adapter || !adapter.custom) return [];
        return adapter.custom;
    }

    // Main content - slides left when editing
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.editMode

        // Horizontal slide + fade animation
        opacity: root.editMode ? 0 : 1
        transform: Translate {
            x: root.editMode ? -30 : 0

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 8

            // Header
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: titlebar.height

                PanelTitlebar {
                    id: titlebar
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    title: "Keybinds"
                    statusText: ""

                    actions: [
                        {
                            icon: Icons.sync,
                            tooltip: "Reload binds",
                            onClicked: function() {
                                Config.keybindsLoader.reload();
                            }
                        }
                    ]
                }
            }

            // Category selector
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: categoryRow.height

                Row {
                    id: categoryRow
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Repeater {
                        model: root.categories

                        delegate: StyledRect {
                            id: categoryTag
                            required property var modelData
                            required property int index

                            property bool isSelected: root.currentCategory === modelData.id
                            property bool isHovered: false

                            variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                            enableShadow: true
                            width: categoryContent.width + 32
                            height: 36
                            radius: Styling.radius(-2)

                            Row {
                                id: categoryContent
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: categoryTag.modelData.icon
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: categoryTag.itemColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: categoryTag.modelData.label
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: categoryTag.isSelected ? Font.Bold : Font.Normal
                                    color: categoryTag.itemColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: categoryTag.isHovered = true
                                onExited: categoryTag.isHovered = false
                                onClicked: root.currentCategory = categoryTag.modelData.id
                            }
                        }
                    }
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: root.contentWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    // Ambxst binds view
                    Repeater {
                        id: ambxstRepeater
                        model: root.currentCategory === "ambxst" ? root.getAmbxstBinds() : []

                        delegate: BindItem {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            bindName: modelData.name
                            keybindText: root.formatKeybind(modelData.bind)
                            dispatcher: modelData.bind.dispatcher
                            argument: modelData.bind.argument || ""
                            isAmbxst: true

                            onEditRequested: {
                                root.openEditDialog(modelData, index, true);
                            }
                        }
                    }

                    // Custom binds view
                    Repeater {
                        id: customRepeater
                        model: root.currentCategory === "custom" ? root.getCustomBinds() : []

                        delegate: BindItem {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            bindName: modelData.dispatcher
                            keybindText: root.formatKeybind(modelData)
                            dispatcher: modelData.dispatcher
                            argument: modelData.argument || ""
                            isEnabled: modelData.enabled !== false
                            isAmbxst: false

                            onToggleEnabled: {
                                const customBinds = Config.keybindsLoader.adapter.custom;
                                if (customBinds && customBinds[index]) {
                                    let newBinds = [];
                                    for (let i = 0; i < customBinds.length; i++) {
                                        if (i === index) {
                                            let updatedBind = Object.assign({}, customBinds[i]);
                                            updatedBind.enabled = !isEnabled;
                                            newBinds.push(updatedBind);
                                        } else {
                                            newBinds.push(customBinds[i]);
                                        }
                                    }
                                    Config.keybindsLoader.adapter.custom = newBinds;
                                }
                            }

                            onEditRequested: {
                                root.openEditDialog(modelData, index, false);
                            }
                        }
                    }

                    // Empty state
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        visible: (root.currentCategory === "ambxst" && ambxstRepeater.count === 0) ||
                                 (root.currentCategory === "custom" && customRepeater.count === 0)
                        text: root.currentCategory === "ambxst" ? "No Ambxst binds configured" : "No custom binds configured"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        color: Colors.overSurfaceVariant
                    }
                }
            }
        }
    }

    // Edit view (shown when editMode is true) - slides in from right
    Item {
        id: editContainer
        anchors.fill: parent
        clip: true

        // Horizontal slide + fade animation (enters from right)
        opacity: root.editMode ? 1 : 0
        transform: Translate {
            x: root.editMode ? 0 : 30

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration / 2
                easing.type: Easing.OutQuart
            }
        }

        // Prevent interaction when hidden
        enabled: root.editMode

        // Block interaction with elements behind when active
        MouseArea {
            anchors.fill: parent
            enabled: root.editMode
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: event => event.accepted = true
            onReleased: event => event.accepted = true
            onWheel: event => event.accepted = true
        }

        Flickable {
            id: editFlickable
            anchors.fill: parent
            contentHeight: editContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: editContent
                width: editFlickable.width
                spacing: 8

                // Header with back button
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: editTitlebar.height

                    RowLayout {
                        id: editTitlebar
                        width: root.contentWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        // Back button
                        StyledRect {
                            id: backButton
                            variant: backButtonArea.containsMouse ? "focus" : "common"
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: Styling.radius(-2)

                            Text {
                                anchors.centerIn: parent
                                text: Icons.caretLeft
                                font.family: Icons.font
                                font.pixelSize: 16
                                color: backButton.itemColor
                            }

                            MouseArea {
                                id: backButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeEditDialog()
                            }
                        }

                        // Title
                        Text {
                            text: "Edit Keybind"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: Font.Medium
                            color: Colors.overBackground
                            Layout.fillWidth: true
                        }

                        // Save button
                        StyledRect {
                            id: saveButton
                            variant: saveButtonArea.containsMouse ? "primaryfocus" : "primary"
                            Layout.preferredWidth: saveButtonContent.width + 24
                            Layout.preferredHeight: 36
                            radius: Styling.radius(-2)

                            Row {
                                id: saveButtonContent
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Icons.accept
                                    font.family: Icons.font
                                    font.pixelSize: 14
                                    color: saveButton.itemColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Save"
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: Font.Medium
                                    color: saveButton.itemColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: saveButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.saveEdit()
                            }
                        }
                    }
                }

                // Edit form content
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: formColumn.implicitHeight

                    ColumnLayout {
                        id: formColumn
                        width: root.contentWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        // Bind name/info
                        Text {
                            visible: root.editingBind !== null
                            text: root.editingBind ? (root.editingBind.name || root.editingBind.dispatcher || "") : ""
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(1)
                            font.weight: Font.Medium
                            color: Colors.overBackground
                        }

                        // Preview at top
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            variant: "common"
                            radius: Styling.radius(-2)

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    const mods = root.formatModifiers(root.editModifiers);
                                    const key = root.editKey || "?";
                                    return mods ? mods + " + " + key : key;
                                }
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(2)
                                font.weight: Font.Bold
                                color: Colors.primary
                            }
                        }

                        // Modifiers section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Modifiers"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.availableModifiers

                                    delegate: StyledRect {
                                        id: modTag
                                        required property string modelData
                                        required property int index

                                        property bool isSelected: root.hasModifier(modelData)
                                        property bool isHovered: false

                                        variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                                        width: modLabel.width + 32
                                        height: 40
                                        radius: Styling.radius(-2)

                                        Text {
                                            id: modLabel
                                            anchors.centerIn: parent
                                            text: modTag.modelData
                                            font.family: Config.theme.font
                                            font.pixelSize: Styling.fontSize(0)
                                            font.weight: modTag.isSelected ? Font.Bold : Font.Normal
                                            color: modTag.itemColor
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: modTag.isHovered = true
                                            onExited: modTag.isHovered = false
                                            onClicked: root.toggleModifier(modTag.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // Key input
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Key"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                variant: keyInput.activeFocus ? "focus" : "common"
                                radius: Styling.radius(-2)

                                TextInput {
                                    id: keyInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: root.editKey
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    onTextChanged: root.editKey = text.toUpperCase()

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !keyInput.text && !keyInput.activeFocus
                                        text: "e.g. R, TAB, ESCAPE..."
                                        font: keyInput.font
                                        color: Colors.overSurfaceVariant
                                    }
                                }
                            }
                        }

                        // Dispatcher input (only for custom binds)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: !root.isEditingAmbxst

                            Text {
                                text: "Dispatcher"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                variant: dispatcherInput.activeFocus ? "focus" : "common"
                                radius: Styling.radius(-2)

                                TextInput {
                                    id: dispatcherInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: root.editDispatcher
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    onTextChanged: root.editDispatcher = text

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !dispatcherInput.text && !dispatcherInput.activeFocus
                                        text: "e.g. exec, workspace, killactive..."
                                        font: dispatcherInput.font
                                        color: Colors.overSurfaceVariant
                                    }
                                }
                            }
                        }

                        // Argument input (only for custom binds)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: !root.isEditingAmbxst

                            Text {
                                text: "Argument"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                variant: argumentInput.activeFocus ? "focus" : "common"
                                radius: Styling.radius(-2)

                                TextInput {
                                    id: argumentInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: root.editArgument
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    onTextChanged: root.editArgument = text

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !argumentInput.text && !argumentInput.activeFocus
                                        text: "e.g. kitty, 1, playerctl play-pause..."
                                        font: argumentInput.font
                                        color: Colors.overSurfaceVariant
                                    }
                                }
                            }
                        }

                        // Flags input (only for custom binds)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: !root.isEditingAmbxst

                            Text {
                                text: "Flags (optional)"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-1)
                                font.weight: Font.Medium
                                color: Colors.overSurfaceVariant
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                variant: flagsInput.activeFocus ? "focus" : "common"
                                radius: Styling.radius(-2)

                                TextInput {
                                    id: flagsInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: root.editFlags
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    color: Colors.overBackground
                                    verticalAlignment: Text.AlignVCenter
                                    selectByMouse: true
                                    onTextChanged: root.editFlags = text

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !flagsInput.text && !flagsInput.activeFocus
                                        text: "e.g. m, l, e, le..."
                                        font: flagsInput.font
                                        color: Colors.overSurfaceVariant
                                    }
                                }
                            }

                            Text {
                                text: "l=locked, e=repeat, m=mouse, r=release"
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-2)
                                color: Colors.overSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }

    // BindItem component
    component BindItem: StyledRect {
        id: bindItem

        property string bindName: ""
        property string keybindText: ""
        property string dispatcher: ""
        property string argument: ""
        property bool isEnabled: true
        property bool isAmbxst: true
        property bool isHovered: false

        signal editRequested()
        signal toggleEnabled()

        variant: isHovered ? "focus" : "common"
        height: 48
        radius: Styling.radius(-2)
        enableShadow: true
        opacity: isEnabled ? 1 : 0.5

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Checkbox for custom binds (styled like OLED Mode)
            Item {
                id: checkboxItem
                visible: !bindItem.isAmbxst
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Item {
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        radius: Styling.radius(-4)
                        color: Colors.background
                        visible: !bindItem.isEnabled
                    }

                    StyledRect {
                        variant: "primary"
                        anchors.fill: parent
                        radius: Styling.radius(-4)
                        visible: bindItem.isEnabled
                        opacity: bindItem.isEnabled ? 1.0 : 0.0

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Icons.accept
                            color: Config.resolveColor(Config.theme.srPrimary.itemColor)
                            font.family: Icons.font
                            font.pixelSize: 16
                            scale: bindItem.isEnabled ? 1.0 : 0.0

                            Behavior on scale {
                                enabled: Config.animDuration > 0
                                NumberAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.5
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        bindItem.toggleEnabled();
                        mouse.accepted = true;
                    }
                }
            }

            // Info column - what the bind does
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: bindItem.bindName
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.Medium
                    color: bindItem.itemColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: bindItem.argument || bindItem.dispatcher
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.overSurfaceVariant
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                }
            }

            // Keybind display at the end
            StyledRect {
                variant: "pane"
                Layout.preferredWidth: keybindLabel.width + 24
                Layout.preferredHeight: 28
                radius: Styling.radius(-4)

                Text {
                    id: keybindLabel
                    anchors.centerIn: parent
                    text: bindItem.keybindText
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    font.weight: Font.Medium
                    color: Colors.primary
                }
            }
        }

        // Click anywhere to edit
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: bindItem.isHovered = true
            onExited: bindItem.isHovered = false
            onClicked: bindItem.editRequested()
        }
    }
}
