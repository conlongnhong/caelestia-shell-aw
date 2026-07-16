pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

Singleton {
    id: root

    readonly property var optionSpecs: ({
            "animations:enabled": {
                type: "bool"
            },
            "decoration:blur:enabled": {
                type: "bool"
            },
            "decoration:shadow:enabled": {
                type: "bool"
            },
            "general:gaps_in": {
                type: "intVector",
                minimum: 0,
                maximum: 100
            },
            "general:gaps_out": {
                type: "intVector",
                minimum: 0,
                maximum: 100
            },
            "general:border_size": {
                type: "int",
                minimum: 0,
                maximum: 20
            },
            "decoration:rounding": {
                type: "int",
                minimum: 0,
                maximum: 100
            },
            "general:allow_tearing": {
                type: "bool"
            }
        })
    readonly property list<string> gameModeKeys: ["animations:enabled", "decoration:shadow:enabled", "decoration:blur:enabled", "general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "general:allow_tearing"]

    readonly property var monitors: Hypr.monitors.values
    readonly property int monitorCount: monitors.length
    readonly property int workspaceCount: Hypr.workspaces.values.length
    readonly property int windowCount: Hypr.toplevels.values.length
    readonly property string focusedMonitorName: Hypr.focusedMonitor?.name ?? ""
    readonly property string activeWorkspaceName: Hypr.focusedWorkspace?.name ?? ""

    // Monitor data is requested only after Quickshell's provider probe completes.
    // Requiring it here prevents Standard commands from racing an unresolved Lua provider.
    readonly property bool optionsReady: Object.keys(Hypr.options).length > 0
    readonly property bool providerReady: optionsReady && Hypr.providerReady
    readonly property string providerName: providerReady ? (Hypr.usingLua ? "Lua" : "Standard") : qsTr("Đang phát hiện")

    readonly property bool supportsAnimations: supportsOption("animations:enabled")
    readonly property bool supportsBlur: supportsOption("decoration:blur:enabled")
    readonly property bool supportsShadow: supportsOption("decoration:shadow:enabled")
    readonly property bool supportsGapsIn: supportsOption("general:gaps_in")
    readonly property bool supportsGapsOut: supportsOption("general:gaps_out")
    readonly property bool supportsBorderSize: supportsOption("general:border_size")
    readonly property bool supportsRounding: supportsOption("decoration:rounding")

    readonly property bool animationsEnabled: _optionBool("animations:enabled", true)
    readonly property bool blurEnabled: _optionBool("decoration:blur:enabled", false)
    readonly property bool shadowEnabled: _optionBool("decoration:shadow:enabled", false)
    readonly property int gapsIn: _optionVectorFirst("general:gaps_in", 0)
    readonly property int gapsOut: _optionVectorFirst("general:gaps_out", 0)
    readonly property int borderSize: _optionInt("general:border_size", 0)
    readonly property int rounding: _optionInt("decoration:rounding", 0)

    property var pendingOptions: ({})

    function supportsOption(key: string): bool {
        return Object.keys(Hypr.options).includes(key);
    }

    function _normaliseIntVector(value: var, spec: var, clampToRange: bool): var {
        if (typeof value === "number") {
            if (isNaN(value) || !isFinite(value) || value !== Math.round(value))
                return undefined;
            const normalisedValue = clampToRange ? Math.max(spec.minimum, Math.min(spec.maximum, value)) : value;
            return normalisedValue.toString();
        }

        if (typeof value !== "string")
            return undefined;

        const trimmedValue = value.trim();
        if (!trimmedValue)
            return undefined;
        const rawParts = trimmedValue.split(/\s+/);
        if (rawParts.length > 4)
            return undefined;

        const normalisedParts = [];
        for (const part of rawParts) {
            if (!/^[+-]?\d+$/.test(part))
                return undefined;

            const numericPart = Number(part);
            if (isNaN(numericPart) || !isFinite(numericPart))
                return undefined;
            normalisedParts.push(clampToRange ? Math.max(spec.minimum, Math.min(spec.maximum, numericPart)) : numericPart);
        }
        return normalisedParts.join(" ");
    }

    function _normaliseOption(key: string, value: var, clampToRange: bool): var {
        const spec = optionSpecs[key];
        if (!spec)
            return undefined;

        if (spec.type === "bool") {
            if (value === true || value === 1 || value === "1" || value === "true")
                return true;
            if (value === false || value === 0 || value === "0" || value === "false")
                return false;

            const numericBool = Number(value);
            return isNaN(numericBool) || !isFinite(numericBool) ? undefined : numericBool !== 0;
        }

        if (spec.type === "intVector")
            return _normaliseIntVector(value, spec, clampToRange);

        const numericValue = Number(value);
        if (isNaN(numericValue) || !isFinite(numericValue))
            return undefined;

        const roundedValue = Math.round(numericValue);
        if (!clampToRange)
            return roundedValue;
        return Math.max(spec.minimum, Math.min(spec.maximum, roundedValue));
    }

    function _currentOption(key: string): var {
        if (!supportsOption(key))
            return undefined;
        return _normaliseOption(key, Hypr.options[key], false);
    }

    function _optionBool(key: string, fallback: bool): bool {
        const value = _currentOption(key);
        return value === undefined ? fallback : value;
    }

    function _optionInt(key: string, fallback: int): int {
        const value = _currentOption(key);
        return value === undefined ? fallback : value;
    }

    function _optionVectorFirst(key: string, fallback: int): int {
        const value = _currentOption(key);
        if (value === undefined)
            return fallback;
        return Number(value.split(" ")[0]);
    }

    function _queueOption(key: string, value: var, clampToRange: bool): bool {
        if (!providerReady || !supportsOption(key))
            return false;

        const normalised = _normaliseOption(key, value, clampToRange);
        if (normalised === undefined)
            return false;

        const next = Object.assign({}, pendingOptions);
        next[key] = normalised;
        pendingOptions = next;
        applyTimer.restart();
        return true;
    }

    function flushOptions(): void {
        if (!providerReady || Object.keys(pendingOptions).length === 0)
            return;

        const options = Object.assign({}, pendingOptions);
        pendingOptions = {};
        Hypr.extras.applyOptions(options);
    }

    function setAnimationsEnabled(enabled: bool): void {
        _queueOption("animations:enabled", enabled, true);
    }

    function setBlurEnabled(enabled: bool): void {
        _queueOption("decoration:blur:enabled", enabled, true);
    }

    function setShadowEnabled(enabled: bool): void {
        _queueOption("decoration:shadow:enabled", enabled, true);
    }

    function setGapsIn(value: int): void {
        _queueOption("general:gaps_in", value, true);
    }

    function setGapsOut(value: int): void {
        _queueOption("general:gaps_out", value, true);
    }

    function setBorderSize(value: int): void {
        _queueOption("general:border_size", value, true);
    }

    function setRounding(value: int): void {
        _queueOption("decoration:rounding", value, true);
    }

    function snapshotGameModeOptions(): var {
        const snapshot = {};
        for (const key of gameModeKeys) {
            const value = _currentOption(key);
            if (value !== undefined)
                snapshot[key] = value;
        }
        return snapshot;
    }

    function applyGameModeOverrides(): void {
        const overrides = {
            "animations:enabled": false,
            "decoration:shadow:enabled": false,
            "decoration:blur:enabled": false,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": true
        };

        for (const key of gameModeKeys)
            _queueOption(key, overrides[key], true);
    }

    function restoreGameModeOptions(snapshot: var): void {
        if (!snapshot || typeof snapshot !== "object" || Array.isArray(snapshot))
            return;

        for (const key of gameModeKeys) {
            if (key in snapshot)
                _queueOption(key, snapshot[key], false);
        }
    }

    function refresh(): void {
        Hypr.extras.refreshOptions();
        Hypr.extras.refreshDevices();
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function reload(): void {
        if (providerReady)
            Hypr.extras.message("reload");
    }

    onProviderReadyChanged: {
        if (providerReady && Object.keys(pendingOptions).length > 0)
            applyTimer.restart();
    }

    Timer {
        id: applyTimer

        interval: 0
        onTriggered: root.flushOptions()
    }
}
