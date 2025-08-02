import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.globals

PanelWindow {
    id: wallpaper

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:wallpaper"
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    property string wallpaperDir: Quickshell.env("HOME") + "/Wallpapers"
    property string fallbackDir: Quickshell.env("PWD") + "/assets/wallpapers_example"
    property list<string> wallpaperPaths: []
    property int currentIndex: 0
    property string currentWallpaper: ""

    function setWallpaper(path) {
        currentWallpaper = path;
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["ln", "-sf", "${path}", "${Quickshell.env("HOME")}/.current.wall"]
                running: true
            }
        `, wallpaper);
    }

    function nextWallpaper() {
        if (wallpaperPaths.length === 0) return;
        currentIndex = (currentIndex + 1) % wallpaperPaths.length;
        setWallpaper(wallpaperPaths[currentIndex]);
    }

    function previousWallpaper() {
        if (wallpaperPaths.length === 0) return;
        currentIndex = currentIndex === 0 ? wallpaperPaths.length - 1 : currentIndex - 1;
        setWallpaper(wallpaperPaths[currentIndex]);
    }

    function setWallpaperByIndex(index) {
        if (index >= 0 && index < wallpaperPaths.length) {
            currentIndex = index;
            setWallpaper(wallpaperPaths[currentIndex]);
        }
    }

    Component.onCompleted: {
        GlobalStates.wallpaperManager = wallpaper;
        scanWallpapers.running = true;
    }

    Process {
        id: scanWallpapers
        running: false
        command: ["find", wallpaperDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                let files = text.trim().split("\n").filter(f => f.length > 0);
                if (files.length === 0) {
                    scanFallback.running = true;
                } else {
                    wallpaperPaths = files.sort();
                    if (currentWallpaper === "" && wallpaperPaths.length > 0) {
                        setWallpaper(wallpaperPaths[0]);
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    scanFallback.running = true;
                }
            }
        }
    }

    Process {
        id: scanFallback
        running: false
        command: ["find", fallbackDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.trim().split("\n").filter(f => f.length > 0);
                wallpaperPaths = files.sort();
                if (currentWallpaper === "" && wallpaperPaths.length > 0) {
                    setWallpaper(wallpaperPaths[0]);
                }
            }
        }
    }

    WallpaperImage {
        id: wallpaper1
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.current.wall"
        active: currentIndex % 2 === 0
    }

    WallpaperImage {
        id: wallpaper2
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.current.wall"
        active: currentIndex % 2 === 1
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        visible: wallpaper1.status !== Image.Ready && wallpaper2.status !== Image.Ready
        z: -1
    }

    component WallpaperImage: Item {
        property string source
        property bool active: false
        property alias status: img.status

        opacity: active ? 1.0 : 0.0
        scale: active ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        Image {
            id: img
            anchors.fill: parent
            source: parent.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true

            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("Wallpaper: Failed to load image from", source);
                }
            }
        }
    }
}
