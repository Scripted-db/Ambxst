pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool isRecording: false
    property string duration: ""
    property string lastError: ""

    property string videosDir: ""

    // Resolve XDG_VIDEOS_DIR
    property Process xdgVideosProcess: Process {
        id: xdgVideosProcess
        command: ["bash", "-c", "xdg-user-dir VIDEOS"]
        running: true // Run on startup
        stdout: StdioCollector {
            onTextChanged: {
                // Not strictly necessary here as we read in onExited
            }
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                var dir = xdgVideosProcess.stdout.text.trim();
                if (dir === "") {
                    dir = Quickshell.env("HOME") + "/Videos";
                }
                root.videosDir = dir + "/Recordings";
            } else {
                root.videosDir = Quickshell.env("HOME") + "/Videos/Recordings";
            }
        }
    }

    // Poll status
    property Timer statusTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            checkProcess.running = true
        }
    }

    property Process checkProcess: Process {
        id: checkProcess
        command: ["bash", "-c", "pgrep -f 'gpu-screen-recorder' | grep -v $$ > /dev/null"]
        onExited: exitCode => {
            var wasRecording = root.isRecording;
            root.isRecording = (exitCode === 0);
            
            if (root.isRecording && !wasRecording) {
                console.log("[ScreenRecorder] Detected running instance.");
            }

            if (root.isRecording) {
                timeProcess.running = true;
            } else {
                root.duration = "";
            }
        }
    }

    property Process timeProcess: Process {
        id: timeProcess
        command: ["bash", "-c", "pid=$(pgrep -f 'gpu-screen-recorder' | head -n 1); if [ -n \"$pid\" ]; then ps -o etime= -p \"$pid\"; fi"]
        stdout: StdioCollector {
            onTextChanged: {
                root.duration = text.trim();
            }
        }
    }

    function toggleRecording() {
        if (isRecording) {
            stopProcess.running = true;
        } else {
            // Default behavior: Portal, no audio
            startRecording("portal", "", false, false);
        }
    }

    function startRecording(mode, regionStr, recordAudioOutput, recordAudioInput) {
        if (isRecording) return;
        
        var cmd = "gpu-screen-recorder -o \"" + root.videosDir + "/$(date +%Y-%m-%d-%H-%M-%S).mp4\"";
        
        // Quality and Codec settings
        cmd += " -q ultra -k h265 -f 60";
        
        // Mode
        if (mode === "screen") {
            cmd += " -w screen";
        } else if (mode === "portal") {
            cmd += " -w portal";
        } else if (mode === "region") {
            cmd += " -w region -region " + regionStr;
        } else {
            cmd += " -w portal";
        }
        
        // Audio
        if (recordAudioOutput) {
            cmd += " -a default_output";
        }
        if (recordAudioInput) {
            cmd += " -a default_input";
        }
        
        console.log("[ScreenRecorder] Starting with command: " + cmd);
        startProcess.command = ["bash", "-c", cmd];
        
        prepareProcess.running = true;
    }
    
    // 1. Ensure directory exists
    property Process prepareProcess: Process {
        id: prepareProcess
        command: ["mkdir", "-p", root.videosDir]
        onExited: exitCode => {
            notifyStartProcess.running = true;
            startProcess.running = true;
        }
    }

    // 2. Notify start
    property Process notifyStartProcess: Process {
        id: notifyStartProcess
        command: ["notify-send", "Screen Recorder", "Starting recording..."]
    }

    // 3. Start recording (Foreground)
    property Process startProcess: Process {
        id: startProcess
        command: ["bash", "-c", "echo 'Error: Command not set'"]
        
        stdout: StdioCollector {
            onTextChanged: console.log("[ScreenRecorder] OUT: " + text)
        }
        stderr: StdioCollector {
            id: stderrCollector
            onTextChanged: {
                console.warn("[ScreenRecorder] ERR: " + text)
                root.lastError = text
            }
        }
        
        onExited: exitCode => {
            console.log("[ScreenRecorder] Exited with code: " + exitCode)
            if (exitCode !== 0 && exitCode !== 130) {
                root.isRecording = false
                notifyErrorProcess.running = true
            } else {
                notifySavedProcess.running = true
            }
        }
    }

    property Process notifyErrorProcess: Process {
        id: notifyErrorProcess
        command: ["notify-send", "-u", "critical", "Screen Recorder Error", "Failed to start. Check logs."]
    }

    property Process notifySavedProcess: Process {
        id: notifySavedProcess
        command: ["notify-send", "Screen Recorder", "Recording saved to " + root.videosDir]
    }
    
    property Process stopProcess: Process {
        id: stopProcess
        command: ["killall", "-SIGINT", "gpu-screen-recorder"]
    }
}
