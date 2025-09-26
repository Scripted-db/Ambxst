import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.modules.theme
import qs.modules.components

BgRect {
    id: clockContainer

    property string currentTime: ""
    property string weatherText: ""

    Layout.preferredWidth: weatherDisplay.implicitWidth + timeDisplay.implicitWidth + 36
    Layout.preferredHeight: 36

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: weatherDisplay
            text: clockContainer.weatherText
            color: Colors.adapter.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
        }

        Text {
            id: timeDisplay
            text: clockContainer.currentTime
            color: Colors.adapter.overBackground
            font.pixelSize: Config.theme.fontSize
            font.family: Config.theme.font
            font.bold: true
        }
    }

    Process {
        id: weatherProcess
        running: false
        command: ["curl", "wttr.in/?format=%c+%t"]

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                clockContainer.weatherText = text.trim();
            }
        }

        onExited: function(code) {
            if (code !== 0) {
                console.log("Weather fetch failed");
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            clockContainer.currentTime = Qt.formatDateTime(now, "hh:mm:ss");
        }
    }

    Timer {
        interval: 600000 // 10 minutes
        running: true
        repeat: true
        onTriggered: {
            weatherProcess.running = true;
        }
    }

    Component.onCompleted: {
        weatherProcess.running = true;
    }
}
