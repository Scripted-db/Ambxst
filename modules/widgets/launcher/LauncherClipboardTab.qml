import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Rectangle {
    id: root
    focus: true

    Keys.onEscapePressed: {
        root.itemSelected();
    }

    property string searchText: ""
    property bool showResults: searchText.length > 0
    property int selectedIndex: -1
    property int selectedImageIndex: -1
    property var imageItems: []
    property var textItems: []
    property bool isImageSectionFocused: false
    property bool hasNavigatedFromSearch: false

    property int imgSize: 78

    signal itemSelected

    onSelectedIndexChanged: {
        if (selectedIndex === -1 && textResultsList.count > 0) {
            textResultsList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onSearchTextChanged: {
        updateFilteredItems();
    }

    function clearSearch() {
        searchText = "";
        selectedIndex = -1;
        selectedImageIndex = -1;
        isImageSectionFocused = false;
        hasNavigatedFromSearch = false;
        searchInput.focusInput();
        updateFilteredItems();
    }

    function focusSearchInput() {
        searchInput.focusInput();
    }

    function updateFilteredItems() {
        var newImageItems = [];
        var newTextItems = [];

        for (var i = 0; i < ClipboardService.items.length; i++) {
            var item = ClipboardService.items[i];
            var content = item.preview || "";

            if (searchText.length === 0 || content.toLowerCase().includes(searchText.toLowerCase())) {
                if (item.isImage) {
                    newImageItems.push(item);
                } else {
                    newTextItems.push(item);
                }
            }
        }

        imageItems = newImageItems;
        textItems = newTextItems;

        if (searchText.length > 0 && textItems.length > 0 && !isImageSectionFocused) {
            selectedIndex = 0;
            textResultsList.currentIndex = 0;
        } else if (searchText.length === 0) {
            selectedIndex = -1;
            selectedImageIndex = -1;
            textResultsList.currentIndex = -1;
        }
    }

    function refreshClipboardHistory() {
        ClipboardService.list();
    }

    function copyToClipboard(itemId) {
        copyProcess.command = ["bash", "-c", "cliphist decode \"" + itemId + "\" | wl-copy"];
        copyProcess.running = true;
    }

    implicitWidth: 400
    implicitHeight: mainLayout.implicitHeight
    color: "transparent"

    Behavior on height {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    // Conexiones al servicio
    Connections {
        target: ClipboardService
        function onListCompleted() {
            updateFilteredItems();
        }
    }

    // Proceso para copiar al portapapeles
    Process {
        id: copyProcess
        running: false

        onExited: function (code) {
            if (code === 0) {
                root.itemSelected();
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Barra de búsqueda
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            text: root.searchText
            placeholderText: "Search clipboard history..."
            iconText: ""

            onSearchTextChanged: text => {
                root.searchText = text;
            }

            onAccepted: {
                if (root.isImageSectionFocused && root.selectedImageIndex >= 0 && root.selectedImageIndex < root.imageItems.length) {
                    var selectedImage = root.imageItems[root.selectedImageIndex];
                    root.copyToClipboard(selectedImage.id);
                } else if (!root.isImageSectionFocused && root.selectedIndex >= 0 && root.selectedIndex < root.textItems.length) {
                    var selectedText = root.textItems[root.selectedIndex];
                    root.copyToClipboard(selectedText.id);
                }
            }

            onEscapePressed: {
                root.itemSelected();
            }

            onDownPressed: {
                if (!root.hasNavigatedFromSearch) {
                    // Primera vez presionando down desde search
                    root.hasNavigatedFromSearch = true;
                    if (root.imageItems.length > 0) {
                        // Ir primero a la sección de imágenes si hay imágenes
                        root.isImageSectionFocused = true;
                        root.selectedIndex = -1;
                        textResultsList.currentIndex = -1;
                        if (root.selectedImageIndex === -1) {
                            root.selectedImageIndex = 0;
                        }
                        imageResultsList.currentIndex = root.selectedImageIndex;
                    } else if (textResultsList.count > 0) {
                        // Si no hay imágenes, ir directo a textos
                        root.isImageSectionFocused = false;
                        if (root.selectedIndex === -1) {
                            root.selectedIndex = 0;
                            textResultsList.currentIndex = 0;
                        }
                    }
                } else {
                    // Ya navegamos desde search, ahora navegamos dentro de secciones
                    if (root.isImageSectionFocused) {
                        // Cambiar de sección de imágenes a textos
                        root.isImageSectionFocused = false;
                        if (root.textItems.length > 0) {
                            root.selectedIndex = 0;
                            textResultsList.currentIndex = 0;
                        }
                    } else if (textResultsList.count > 0 && root.selectedIndex >= 0) {
                        if (root.selectedIndex < textResultsList.count - 1) {
                            root.selectedIndex++;
                            textResultsList.currentIndex = root.selectedIndex;
                        }
                    }
                }
            }

            onUpPressed: {
                if (root.isImageSectionFocused) {
                    // Al estar en imágenes y presionar up, regresar al search
                    root.isImageSectionFocused = false;
                    root.selectedImageIndex = -1;
                    root.hasNavigatedFromSearch = false;
                    imageResultsList.currentIndex = -1;
                } else if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    textResultsList.currentIndex = root.selectedIndex;
                } else if (root.selectedIndex === 0 && root.imageItems.length > 0) {
                    // Cambiar de textos a imágenes
                    root.isImageSectionFocused = true;
                    root.selectedIndex = -1;
                    textResultsList.currentIndex = -1;
                    if (root.selectedImageIndex === -1) {
                        root.selectedImageIndex = 0;
                    }
                } else if (root.selectedIndex === 0 && root.imageItems.length === 0) {
                    // No hay imágenes, regresar al search
                    root.selectedIndex = -1;
                    root.hasNavigatedFromSearch = false;
                    textResultsList.currentIndex = -1;
                }
            }

            onLeftPressed: {
                if (root.isImageSectionFocused && root.selectedImageIndex > 0) {
                    root.selectedImageIndex--;
                    imageResultsList.currentIndex = root.selectedImageIndex;
                }
            }

            onRightPressed: {
                if (root.isImageSectionFocused && root.selectedImageIndex < root.imageItems.length - 1) {
                    root.selectedImageIndex++;
                    imageResultsList.currentIndex = root.selectedImageIndex;
                }
            }
        }

        // Contenedor de resultados del clipboard
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Sección de imágenes horizontal
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.imgSize
                visible: root.imageItems.length > 0 && root.searchText.length === 0

                ClippingRectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.isImageSectionFocused ? Colors.adapter.primary : Colors.adapter.outline
                    border.width: 0
                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutQuart
                        }
                    }

                    ListView {
                        id: imageResultsList
                        anchors.fill: parent
                        anchors.margins: 0
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true

                        model: root.imageItems
                        currentIndex: root.selectedImageIndex

                        onCurrentIndexChanged: {
                            if (currentIndex !== root.selectedImageIndex && root.isImageSectionFocused) {
                                root.selectedImageIndex = currentIndex;
                            }
                        }

                        delegate: ClippingRectangle {
                            required property var modelData
                            required property int index

                            width: root.imgSize
                            height: width
                            color: root.isImageSectionFocused && root.selectedImageIndex === index ? Colors.adapter.primary : Colors.adapter.surface
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true

                                onEntered: {
                                    if (!root.isImageSectionFocused) {
                                        root.isImageSectionFocused = true;
                                        root.selectedIndex = -1;
                                        textResultsList.currentIndex = -1;
                                    }
                                    root.selectedImageIndex = index;
                                    imageResultsList.currentIndex = index;
                                }

                                onClicked: {
                                    root.copyToClipboard(modelData.id);
                                }
                            }

                            // Preview de imagen real o placeholder
                            Item {
                                anchors.centerIn: parent
                                width: root.imgSize
                                height: width

                                // Imagen real si está disponible
                                Image {
                                    id: imagePreview
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    source: {
                                        // Forzar re-evaluación cuando el cache cambia
                                        ClipboardService.revision;
                                        return ClipboardService.getImageData(modelData.id);
                                    }
                                    clip: true

                                    Component.onCompleted: {
                                        // Cargar imagen on-demand si no está en cache
                                        if (!ClipboardService.getImageData(modelData.id)) {
                                            ClipboardService.decodeToDataUrl(modelData.id, modelData.mime);
                                        }
                                    }

                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            console.log("Error loading image for ID:", modelData.id);
                                        }
                                    }
                                }

                                // Placeholder cuando la imagen no está disponible
                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.adapter.primary
                                    radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                    visible: imagePreview.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: Icons.image
                                        font.family: Icons.font
                                        font.pixelSize: 24
                                        color: Colors.adapter.overPrimary
                                    }
                                }

                                // Indicador de carga
                                Rectangle {
                                    anchors.fill: parent
                                    color: Colors.adapter.surface
                                    radius: Config.roundness > 0 ? Config.roundness - 4 : 0
                                    visible: imagePreview.status === Image.Loading
                                    opacity: 0.8

                                    Text {
                                        anchors.centerIn: parent
                                        text: "..."
                                        font.family: Config.theme.font
                                        font.pixelSize: 16
                                        color: Colors.adapter.overSurface
                                    }
                                }
                            }

                            // Highlight cuando está seleccionado
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Colors.adapter.primary
                                border.width: 0
                                radius: Config.roundness > 0 ? Config.roundness + 4 : 0

                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        highlight: Rectangle {
                            color: "transparent"
                            z: 100
                            border.color: Colors.adapter.primary
                            border.width: 4
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                            visible: root.isImageSectionFocused
                        }

                        highlightMoveDuration: Config.animDuration / 2
                        highlightMoveVelocity: -1
                    }
                }
            }

            // Scrollbar separador para imágenes
            ScrollBar {
                id: imageScrollBar
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                visible: root.imageItems.length > 0 && root.searchText.length === 0
                orientation: Qt.Horizontal

                size: imageResultsList.width / imageResultsList.contentWidth
                position: imageResultsList.contentX / imageResultsList.contentWidth

                background: Rectangle {
                    color: Colors.surface
                    radius: Config.roundness
                }

                contentItem: Rectangle {
                    color: Colors.adapter.primary
                    radius: Config.roundness
                }

                onPositionChanged: {
                    if (pressed) {
                        imageResultsList.contentX = position * imageResultsList.contentWidth;
                    }
                }
            }

            // Lista de textos vertical
            ListView {
                id: textResultsList
                Layout.fillWidth: true
                Layout.preferredHeight: root.searchText.length > 0 ? 5 * 48 : 3 * 48
                visible: true
                clip: true

                model: root.textItems
                currentIndex: root.selectedIndex

                onCurrentIndexChanged: {
                    if (currentIndex !== root.selectedIndex && !root.isImageSectionFocused) {
                        root.selectedIndex = currentIndex;
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: textResultsList.width
                    height: 48
                    color: "transparent"
                    radius: 16

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            if (root.isImageSectionFocused) {
                                root.isImageSectionFocused = false;
                                root.selectedImageIndex = -1;
                            }
                            root.selectedIndex = index;
                            textResultsList.currentIndex = index;
                        }
                        onClicked: {
                            root.copyToClipboard(modelData.id);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            color: root.selectedIndex === index && !root.isImageSectionFocused ? Colors.adapter.overPrimary : Colors.surface
                            radius: Config.roundness > 0 ? Config.roundness - 4 : 0

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Icons.clip
                                color: root.selectedIndex === index && !root.isImageSectionFocused ? Colors.adapter.primary : Colors.adapter.overBackground
                                font.family: Icons.font
                                font.pixelSize: 16

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.preview
                            color: root.selectedIndex === index && !root.isImageSectionFocused ? Colors.adapter.overPrimary : Colors.adapter.overBackground
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            font.weight: Font.Bold
                            elide: Text.ElideRight

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }
                    }
                }

                highlight: Rectangle {
                    color: Colors.adapter.primary
                    radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                    visible: root.selectedIndex >= 0 && !root.isImageSectionFocused
                }

                highlightMoveDuration: Config.animDuration / 2
                highlightMoveVelocity: -1
            }
        }

        // Mensaje cuando no hay elementos
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            visible: ClipboardService.items.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    text: Icons.clipboard
                    font.family: Icons.font
                    font.pixelSize: 48
                    color: Colors.adapter.overBackground
                    opacity: 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "No clipboard history"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize + 2
                    font.weight: Font.Bold
                    color: Colors.adapter.overBackground
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Copy something to get started"
                    font.family: Config.theme.font
                    font.pixelSize: Config.theme.fontSize
                    color: Colors.adapter.overBackground
                    opacity: 0.7
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component.onCompleted: {
        refreshClipboardHistory();
        Qt.callLater(() => {
            focusSearchInput();
        });
    }
}
