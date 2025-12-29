pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Available presets
    property var presets: []

    // Current preset being loaded/saved
    property string currentPreset: ""

    // Config directory paths
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/Ambxst"
    readonly property string presetsDir: configDir + "/presets"

    // Signal when presets change
    signal presetsUpdated()

    // Scan presets directory
    function scanPresets() {
        scanProcess.running = true
    }

    // Load a preset by name
    function loadPreset(presetName: string) {
        if (presetName === "") {
            console.warn("Cannot load empty preset name")
            return
        }

        console.log("Loading preset:", presetName)
        currentPreset = presetName

        // For now, just show a message - full implementation needs restart
        Quickshell.execDetached(["notify-send", "Preset Loaded", `Preset "${presetName}" loaded. Restart Ambxst to apply changes.`])

        // TODO: Implement proper config loading without restart
    }

    // Save current config as preset
    function savePreset(presetName: string, configFiles: var) {
        if (presetName === "") {
            console.warn("Cannot save preset with empty name")
            return
        }

        if (configFiles.length === 0) {
            console.warn("No config files selected for preset")
            return
        }

        console.log("Saving preset:", presetName, "with files:", configFiles)

        // Create preset directory and copy config files
        const presetPath = presetsDir + "/" + presetName
        const createCmd = `mkdir -p "${presetPath}"`

        let copyCmd = ""
        for (const configFile of configFiles) {
            const jsonFile = configFile.replace('.js', '.json')
            const srcPath = configDir + "/" + jsonFile
            const dstPath = presetPath + "/" + jsonFile
            copyCmd += `cp "${srcPath}" "${dstPath}" && `
        }
        copyCmd = copyCmd.slice(0, -4) // Remove last " && "

        const fullCmd = `${createCmd} && ${copyCmd}`
        saveProcess.command = ["sh", "-c", fullCmd]
        saveProcess.running = true

        root.pendingPresetName = presetName
    }

    // Internal properties for saving
    property string pendingPresetName: ""

    // Scan presets process
    Process {
        id: scanProcess
        command: ["find", presetsDir, "-mindepth", "1", "-maxdepth", "1", "-type", "d"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(line => line.length > 0)
                const newPresets = []

                for (const line of lines) {
                    const presetName = line.split('/').pop()
                    const presetPath = line

                    // Find JSON files in preset directory
                    const configFilesProcess = Qt.createQmlObject(`
                        import Quickshell.Io
                        Process {
                            property string presetPath: ""
                            property string presetName: ""
                            command: ["find", presetPath, "-name", "*.json"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    const files = text.trim().split('\n').filter(f => f.length > 0)
                                    const configNames = files.map(f => f.split('/').pop().replace('.json', '.js'))
                                    // Update the preset in the list
                                    const updatedPresets = root.presets.map(p =>
                                        p.name === presetName ?
                                        {...p, configFiles: configNames} : p
                                    )
                                    root.presets = updatedPresets
                                    root.presetsUpdated()
                                }
                            }
                        }
                    `, root)
                    configFilesProcess.presetPath = presetPath
                    configFilesProcess.presetName = presetName

                    newPresets.push({
                        name: presetName,
                        path: presetPath,
                        configFiles: [] // Will be filled by configFilesProcess
                    })
                }

                root.presets = newPresets
                root.presetsUpdated()
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("Failed to scan presets directory")
                root.presets = []
                root.presetsUpdated()
            }
        }
    }

    // Save process
    Process {
        id: saveProcess
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                console.log("Preset saved successfully:", root.pendingPresetName)
                Quickshell.execDetached(["notify-send", "Preset Saved", `Preset "${root.pendingPresetName}" saved successfully.`])
                root.scanProcess.running = true
            } else {
                console.warn("Failed to save preset:", root.pendingPresetName)
                Quickshell.execDetached(["notify-send", "Error", `Failed to save preset "${root.pendingPresetName}".`])
            }
            root.pendingPresetName = ""
        }
    }

    // Directory watcher
    FileView {
        path: presetsDir
        watchChanges: true
        printErrors: false

        onFileChanged: {
            console.log("Presets directory changed, rescanning...")
            scanProcess.running = true
        }
    }

    // Initialize
    Component.onCompleted: {
        console.log("PresetsService created, presetsDir:", presetsDir)
        // Create presets directory if it doesn't exist
        const initProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["mkdir", "-p", "${presetsDir}"]
                running: true
                onExited: function(exitCode) {
                    if (exitCode === 0) {
                        root.scanProcess.running = true
                    }
                }
            }
        `, root)
    }
}