pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
pragma ComponentBehavior: Bound

/**
 * System resource monitoring service
 * Tracks CPU, GPU, RAM and disk usage percentages
 */
Singleton {
    id: root

    // CPU metrics
    property real cpuUsage: 0.0
    property var cpuPrevTotal: 0
    property var cpuPrevIdle: 0

    // RAM metrics
    property real ramUsage: 0.0
    property real ramTotal: 0
    property real ramUsed: 0
    property real ramAvailable: 0

    // GPU metrics
    property real gpuUsage: 0.0
    property string gpuVendor: "unknown"
    property bool gpuDetected: false

    // Disk metrics - map of mountpoint to usage percentage
    property var diskUsage: ({})

    // Validated disk list
    property var validDisks: []

    // Update interval in milliseconds
    property int updateInterval: 2000

    // History data for charts (max 50 points)
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property int maxHistoryPoints: 50
    
    // Total data points collected (continues incrementing forever)
    property int totalDataPoints: 0

    Component.onCompleted: {
        detectGPU();
    }

    // Watch for config changes and revalidate disks
    Connections {
        target: Config.system
        function onDisksChanged() {
            root.validateDisks();
        }
    }

    // Validate disks when Config is ready
    property bool configReady: Config.initialLoadComplete
    onConfigReadyChanged: {
        if (configReady) {
            validateDisks();
        }
    }

    // Detect GPU vendor and availability
    function detectGPU() {
        // Try NVIDIA first
        gpuDetector.running = true;
    }

    // Validate configured disks and fall back to "/" if invalid
    function validateDisks() {
        const configuredDisks = Config.system.disks || ["/"];
        validDisks = [];

        for (let i = 0; i < configuredDisks.length; i++) {
            const disk = configuredDisks[i];
            if (disk && typeof disk === 'string' && disk.trim() !== '') {
                validDisks.push(disk.trim());
            }
        }

        // Ensure at least "/" is present
        if (validDisks.length === 0) {
            validDisks = ["/"];
        }
    }

    // Update history arrays with current values
    function updateHistory() {
        // Increment total data points counter
        totalDataPoints++;
        
        // Add CPU history
        let newCpuHistory = cpuHistory.slice();
        newCpuHistory.push(cpuUsage / 100);
        if (newCpuHistory.length > maxHistoryPoints) {
            newCpuHistory.shift();
        }
        cpuHistory = newCpuHistory;

        // Add RAM history
        let newRamHistory = ramHistory.slice();
        newRamHistory.push(ramUsage / 100);
        if (newRamHistory.length > maxHistoryPoints) {
            newRamHistory.shift();
        }
        ramHistory = newRamHistory;

        // Add GPU history if detected
        if (gpuDetected) {
            let newGpuHistory = gpuHistory.slice();
            newGpuHistory.push(gpuUsage / 100);
            if (newGpuHistory.length > maxHistoryPoints) {
                newGpuHistory.shift();
            }
            gpuHistory = newGpuHistory;
        }
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuReader.running = true;
            ramReader.running = true;
            diskReader.running = true;
            
            // Only query GPU if detected
            if (root.gpuDetected) {
                if (root.gpuVendor === "nvidia") {
                    gpuReaderNvidia.running = true;
                } else if (root.gpuVendor === "amd") {
                    gpuReaderAMD.running = true;
                } else if (root.gpuVendor === "intel") {
                    gpuReaderIntel.running = true;
                }
            }

            // Update history after collecting metrics
            root.updateHistory();
        }
    }

    // GPU vendor detection
    Process {
        id: gpuDetector
        running: false
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null 2>&1 && echo nvidia || (command -v rocm-smi >/dev/null 2>&1 && echo amd || (command -v intel_gpu_top >/dev/null 2>&1 && echo intel || echo none))"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const vendor = text.trim();
                if (vendor === "nvidia" || vendor === "amd" || vendor === "intel") {
                    root.gpuVendor = vendor;
                    root.gpuDetected = true;
                } else {
                    root.gpuVendor = "unknown";
                    root.gpuDetected = false;
                }
            }
        }
    }

    // NVIDIA GPU usage reader
    Process {
        id: gpuReaderNvidia
        running: false
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;
                
                const lines = raw.split('\n');
                if (lines.length > 0) {
                    const usage = parseFloat(lines[0]) || 0;
                    root.gpuUsage = Math.max(0, Math.min(100, usage));
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.gpuUsage = 0;
            }
        }
    }

    // AMD GPU usage reader
    Process {
        id: gpuReaderAMD
        running: false
        command: ["sh", "-c", "cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo 0"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;
                
                const usage = parseFloat(raw) || 0;
                root.gpuUsage = Math.max(0, Math.min(100, usage));
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.gpuUsage = 0;
            }
        }
    }

    // Intel GPU usage reader
    Process {
        id: gpuReaderIntel
        running: false
        command: ["sh", "-c", "intel_gpu_top -J -s 100 2>/dev/null | grep -oP '\"Render/3D/0\".*?\"busy\":\\K[0-9.]+' | head -n1 || echo 0"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;
                
                const usage = parseFloat(raw) || 0;
                root.gpuUsage = Math.max(0, Math.min(100, usage));
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.gpuUsage = 0;
            }
        }
    }

    // CPU usage calculation based on /proc/stat (btop method)
    Process {
        id: cpuReader
        running: false
        command: ["cat", "/proc/stat"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;

                const lines = raw.split('\n');
                const cpuLine = lines.find(line => line.startsWith('cpu '));
                
                if (!cpuLine) return;

                const values = cpuLine.split(/\s+/).slice(1).map(v => parseInt(v) || 0);
                
                // CPU times: user, nice, system, idle, iowait, irq, softirq, steal
                const idle = values[3] + values[4]; // idle + iowait
                const total = values.reduce((sum, val) => sum + val, 0);

                if (root.cpuPrevTotal > 0) {
                    const totalDiff = total - root.cpuPrevTotal;
                    const idleDiff = idle - root.cpuPrevIdle;
                    
                    if (totalDiff > 0) {
                        const usage = ((totalDiff - idleDiff) * 100.0) / totalDiff;
                        root.cpuUsage = Math.max(0, Math.min(100, usage));
                    }
                }

                root.cpuPrevTotal = total;
                root.cpuPrevIdle = idle;
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.cpuUsage = 0;
            }
        }
    }

    // RAM usage calculation based on /proc/meminfo (btop method)
    Process {
        id: ramReader
        running: false
        command: ["cat", "/proc/meminfo"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;

                const lines = raw.split('\n');
                let memTotal = 0;
                let memAvailable = 0;

                for (const line of lines) {
                    const parts = line.split(/:\s+/);
                    if (parts.length < 2) continue;

                    const key = parts[0];
                    const valueKB = parseInt(parts[1]) || 0;

                    if (key === 'MemTotal') {
                        memTotal = valueKB;
                    } else if (key === 'MemAvailable') {
                        memAvailable = valueKB;
                    }
                }

                if (memTotal > 0) {
                    root.ramTotal = memTotal;
                    root.ramAvailable = memAvailable;
                    root.ramUsed = memTotal - memAvailable;
                    root.ramUsage = (root.ramUsed * 100.0) / memTotal;
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.ramUsage = 0;
            }
        }
    }

    // Disk usage calculation using df command
    Process {
        id: diskReader
        running: false
        command: ["sh", "-c", "LANG=C df -B1 " + root.validDisks.join(" ") + " 2>/dev/null || LANG=C df -B1 /"]
        
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = text.trim();
                if (!raw) return;

                const newDiskUsage = {};
                const lines = raw.split('\n');

                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;

                    const parts = line.split(/\s+/);
                    if (parts.length < 6) continue;

                    // Mountpoint is always the last field
                    const mountpoint = parts[parts.length - 1];
                    const used = parseInt(parts[2]) || 0;
                    const available = parseInt(parts[3]) || 0;

                    if (root.validDisks.includes(mountpoint)) {
                        // Calculate percentage as df does: used / (used + available)
                        // This accounts for reserved space not shown in total
                        const usableSpace = used + available;
                        if (usableSpace > 0) {
                            const usagePercent = (used * 100.0) / usableSpace;
                            newDiskUsage[mountpoint] = Math.max(0, Math.min(100, usagePercent));
                        }
                    }
                }

                // Fallback: ensure all configured disks have a value
                for (const disk of root.validDisks) {
                    if (!(disk in newDiskUsage)) {
                        newDiskUsage[disk] = 0.0;
                    }
                }

                root.diskUsage = newDiskUsage;
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                root.diskUsage = {};
            }
        }
    }
}
