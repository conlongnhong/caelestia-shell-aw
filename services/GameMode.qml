pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    function applyOverrides(): bool {
        if (!HyprControl.providerReady)
            return false;

        if (!props.snapshotJson) {
            const snapshot = HyprControl.snapshotGameModeOptions();
            if (Object.keys(snapshot).length === 0)
                return false;
            props.snapshotJson = JSON.stringify(snapshot);
        }

        HyprControl.applyGameModeOverrides();
        return true;
    }

    function restoreSnapshot(): bool {
        if (!props.snapshotJson)
            return true;
        if (!HyprControl.providerReady)
            return false;

        try {
            HyprControl.restoreGameModeOptions(JSON.parse(props.snapshotJson));
        } catch (error) {
            console.warn("GameMode: unable to restore Hyprland snapshot:", error);
        }

        props.snapshotJson = "";
        return true;
    }

    function setDynamicConfs(): void {
        applyOverrides();
    }

    onEnabledChanged: {
        if (enabled) {
            const applied = applyOverrides();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Đã bật chế độ trò chơi"), applied ? qsTr("Đã tắt hiệu ứng động, làm mờ, khoảng cách và bóng đổ của Hyprland") : qsTr("Đang chờ Hyprland sẵn sàng để áp dụng"), "gamepad");
        } else {
            const restored = restoreSnapshot();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Đã tắt chế độ trò chơi"), restored ? qsTr("Đã khôi phục cài đặt Hyprland") : qsTr("Sẽ khôi phục khi Hyprland sẵn sàng"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false
        property string snapshotJson

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                reapplyTimer.restart();
        }

        target: Hypr
    }

    Connections {
        function onProviderReadyChanged(): void {
            if (!HyprControl.providerReady)
                return;

            if (props.enabled)
                root.applyOverrides();
            else
                root.restoreSnapshot();
        }

        target: HyprControl
    }

    Timer {
        id: reapplyTimer

        interval: 150
        onTriggered: {
            if (props.enabled)
                root.applyOverrides();
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
