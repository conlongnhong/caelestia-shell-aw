pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var monitors: []
    property bool available: false
    property bool refreshing: false
    property string error: ""
    property bool nightLightAvailable: false
    property bool nightLightEnabled: false
    property int nightLightTemperature: 4500

    function refresh(): void {
        if (!refreshProc.running) {
            refreshing = true;
            refreshProc.running = true;
        }
    }

    function modeText(monitor: var): string {
        return `${monitor.width}x${monitor.height}@${Number(monitor.refreshRate).toFixed(2)}`;
    }

    function applyMonitor(monitor: var, mode: string, scale: real, transform: int, x: int, y: int): void {
        if (!available || !monitor?.name)
            return;
        const safeMode = /^\d+x\d+@[\d.]+$/.test(mode) ? mode : modeText(monitor);
        const safeScale = Math.max(0.5, Math.min(4, Number(scale)));
        const safeTransform = Math.max(0, Math.min(7, Math.round(transform)));
        const safeX = Math.round(Number(x));
        const safeY = Math.round(Number(y));
        applyProc.command = ["hyprctl", "keyword", "monitor", `${monitor.name},${safeMode},${safeX}x${safeY},${safeScale},transform,${safeTransform}`];
        applyProc.running = true;
    }

    function setNightLightEnabled(enabled: bool): void {
        if (!nightLightAvailable)
            return;
        nightLightEnabled = enabled;
        nightLightProc.command = enabled
            ? ["hyprctl", "hyprsunset", "temperature", nightLightTemperature.toString()]
            : ["hyprctl", "hyprsunset", "identity"];
        nightLightProc.running = true;
    }

    function setNightLightTemperature(temperature: int): void {
        nightLightTemperature = Math.max(1000, Math.min(6000, Math.round(temperature)));
        if (nightLightEnabled)
            setNightLightEnabled(true);
    }

    Component.onCompleted: {
        refresh();
        nightLightProbe.running = true;
    }

    Connections {
        function onConfigReloaded(): void { root.refresh(); }

        target: Hypr
    }

    Timer {
        id: refreshTimer

        interval: 250
        onTriggered: root.refresh()
    }

    Process {
        id: refreshProc

        command: ["hyprctl", "-j", "monitors", "all"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text || "[]");
                    root.monitors = Array.isArray(parsed) ? parsed.filter(m => m && m.name && !m.disabled) : [];
                    root.available = true;
                    root.error = "";
                } catch (e) {
                    root.monitors = [];
                    root.available = false;
                    root.error = qsTr("Không đọc được trạng thái màn hình Hyprland");
                }
            }
        }
        stderr: StdioCollector {}
        onExited: code => {
            root.refreshing = false;
            if (code !== 0) {
                root.available = false;
                root.error = qsTr("Backend màn hình Hyprland không khả dụng");
            }
        }
    }

    Process {
        id: applyProc

        stderr: StdioCollector { id: applyError }
        onExited: code => {
            if (code !== 0)
                root.error = applyError.text.trim() || qsTr("Không thể áp dụng cấu hình màn hình");
            refreshTimer.restart();
        }
    }

    Process {
        id: nightLightProbe

        command: ["hyprctl", "hyprsunset", "profile"]
        onExited: code => root.nightLightAvailable = code === 0
    }

    Process {
        id: nightLightProc

        onExited: code => {
            if (code !== 0) {
                root.nightLightAvailable = false;
                root.nightLightEnabled = false;
            }
        }
    }
}
