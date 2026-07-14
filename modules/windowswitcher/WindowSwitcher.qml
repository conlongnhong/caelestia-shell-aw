pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.misc
import qs.services
import qs.utils

Scope {
    id: root

    property var clients: []
    property var mruAddresses: []
    property int selectedIndex: -1
    property string originWorkspace: ""
    property string targetScreen: ""
    property bool switching
    property bool overlayVisible
    property bool presented
    property double openedAtMs

    function normaliseAddress(client: var): string {
        const address = String(client?.address ?? "");
        return address.startsWith("0x") ? address.slice(2) : address;
    }

    function selectorFor(client: var): string {
        const address = normaliseAddress(client);
        return address ? `address:0x${address}` : "";
    }

    function rememberActive(client: var): void {
        if (switching || !client)
            return;

        const address = normaliseAddress(client);
        if (!address)
            return;

        const updated = mruAddresses.filter(a => a !== address);
        updated.unshift(address);
        mruAddresses = updated.slice(0, 128);
    }

    function isSwitchable(client: var): bool {
        if (!client || !normaliseAddress(client))
            return false;

        const ipc = client.lastIpcObject ?? {};
        // Foreign-toplevel objects can outlive their Hyprland IPC entry briefly.
        // Only show clients confirmed by the current `hyprctl clients` snapshot.
        if (ipc.mapped !== true || ipc.hidden === true || ipc.noFocus === true)
            return false;

        return String(client.title ?? "").trim().length > 0 || String(ipc.class ?? "").trim().length > 0;
    }

    function activeAddressFor(candidates: var): string {
        const reported = normaliseAddress(Hyprland.activeToplevel);
        if (reported && candidates.some(client => normaliseAddress(client) === reported))
            return reported;

        const activated = candidates.find(client => client.activated === true);
        if (activated)
            return normaliseAddress(activated);

        const focused = candidates.find(client => Number(client.lastIpcObject?.focusHistoryID ?? -1) === 0);
        return normaliseAddress(focused);
    }

    function orderedClients(): var {
        const unique = new Map();
        for (const client of Hypr.toplevels.values) {
            if (isSwitchable(client))
                unique.set(normaliseAddress(client), client);
        }

        const allClients = Array.from(unique.values());
        const activeAddress = activeAddressFor(allClients);
        const order = new Map();
        for (let i = 0; i < mruAddresses.length; ++i)
            order.set(mruAddresses[i], i);

        return allClients.sort((a, b) => {
            const aa = normaliseAddress(a);
            const ba = normaliseAddress(b);
            if (aa === activeAddress)
                return -1;
            if (ba === activeAddress)
                return 1;

            const ai = order.has(aa) ? order.get(aa) : Number.MAX_SAFE_INTEGER;
            const bi = order.has(ba) ? order.get(ba) : Number.MAX_SAFE_INTEGER;
            if (ai !== bi)
                return ai - bi;

            const ah = Number(a.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);
            const bh = Number(b.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);
            if (ah !== bh)
                return ah - bh;
            return String(a.title ?? "").localeCompare(String(b.title ?? ""));
        });
    }

    function currentNormalWorkspace(): string {
        let name = String(Hypr.focusedWorkspace?.name ?? "");
        if (!name || name.startsWith("special:"))
            name = String(Hypr.focusedMonitor?.activeWorkspace?.name ?? "");
        if (!name || name.startsWith("special:"))
            name = String(Hypr.activeWsId);
        return name;
    }

    function screenForActiveMonitor(): string {
        const monitor = Hypr.focusedMonitor;
        const screen = Screens.screens.find(s => Hypr.monitorFor(s) === monitor);
        return screen?.name ?? Screens.screens[0]?.name ?? "";
    }

    function start(direction: int): void {
        if (switching) {
            step(direction);
            return;
        }

        const available = orderedClients();
        if (available.length === 0)
            return;

        const activeAddress = activeAddressFor(available);
        const activeIndex = available.findIndex(client => normaliseAddress(client) === activeAddress);
        closeTimer.stop();
        clients = available;
        originWorkspace = currentNormalWorkspace();
        targetScreen = screenForActiveMonitor();
        switching = true;
        overlayVisible = true;
        openedAtMs = Date.now();
        selectedIndex = activeIndex >= 0 ? (activeIndex + direction + available.length) % available.length : direction >= 0 ? 0 : available.length - 1;

        Qt.callLater(() => {
            if (root.switching)
                root.presented = true;
        });
    }

    function step(direction: int): void {
        if (!switching) {
            start(direction);
            return;
        }
        if (clients.length === 0) {
            cancel();
            return;
        }

        selectedIndex = (selectedIndex + direction + clients.length) % clients.length;
    }

    function reconcileClients(): void {
        if (!switching)
            return;

        const selectedAddress = normaliseAddress(clients[selectedIndex]);
        const available = orderedClients();
        if (available.length === 0) {
            cancel();
            return;
        }

        clients = available;
        const newIndex = available.findIndex(client => normaliseAddress(client) === selectedAddress);
        selectedIndex = newIndex >= 0 ? newIndex : Math.min(selectedIndex, available.length - 1);
    }

    function luaEscape(value: string): string {
        return value.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
    }

    function activate(client: var): void {
        const selector = selectorFor(client);
        if (!selector)
            return;

        if (String(client.workspace?.name ?? "") === "special:minimized") {
            let moveRequest;
            if (Hypr.usingLua) {
                const windowArg = luaEscape(selector);
                const workspaceArg = luaEscape(originWorkspace);
                moveRequest = `hl.dsp.window.move({ window = "${windowArg}", workspace = "${workspaceArg}", follow = true })`;
            } else {
                moveRequest = `movetoworkspace ${originWorkspace},${selector}`;
            }

            const focusRequest = Hypr.usingLua ? `hl.dsp.focus({ window = "${luaEscape(selector)}" })` : `focuswindow ${selector}`;
            Hypr.extras.batchMessage([`dispatch ${moveRequest}`, `dispatch ${focusRequest}`]);
            return;
        }

        if (Hypr.usingLua)
            Hypr.dispatch(`hl.dsp.focus({ window = "${luaEscape(selector)}" })`);
        else
            Hypr.dispatch(`focuswindow ${selector}`);
    }

    function finish(activateSelection: bool): void {
        if (!switching)
            return;

        const selected = selectedIndex >= 0 && selectedIndex < clients.length ? clients[selectedIndex] : null;
        switching = false;
        presented = false;
        closeTimer.restart();

        if (activateSelection && selected)
            activate(selected);
    }

    function commit(): void {
        finish(true);
    }

    function cancel(): void {
        finish(false);
    }

    Component.onCompleted: rememberActive(Hyprland.activeToplevel)

    Timer {
        id: closeTimer

        interval: 180
        onTriggered: {
            root.overlayVisible = false;
            root.clients = [];
            root.selectedIndex = -1;
        }
    }

    Timer {
        id: reconcileTimer

        interval: 60
        onTriggered: root.reconcileClients()
    }

    Connections {
        target: Hyprland

        function onActiveToplevelChanged(): void {
            root.rememberActive(Hyprland.activeToplevel);
        }

        function onRawEvent(event: HyprlandEvent): void {
            if (root.switching && ["openwindow", "closewindow", "movewindow", "movewindowv2", "minimize"].includes(event.name))
                reconcileTimer.restart();
        }
    }

    Connections {
        target: Hypr.toplevels

        function onValuesChanged(): void {
            if (root.switching)
                reconcileTimer.restart();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherNext"
        description: qsTr("Chuyển tới cửa sổ tiếp theo")
        onPressed: root.start(1)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherPrev"
        description: qsTr("Chuyển tới cửa sổ trước")
        onPressed: root.start(-1)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "windowSwitcherCommit"
        description: qsTr("Mở cửa sổ đã chọn")
        onReleased: root.commit()
    }

    IpcHandler {
        function next(): void {
            root.start(1);
        }

        function previous(): void {
            root.start(-1);
        }

        function commit(): void {
            root.commit();
        }

        function cancel(): void {
            root.cancel();
        }

        function state(): string {
            return JSON.stringify({
                switching: root.switching,
                selectedIndex: root.selectedIndex,
                selectedAddress: root.normaliseAddress(root.clients[root.selectedIndex]),
                count: root.clients.length
            });
        }

        target: "windowSwitcher"
    }

    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            readonly property real outerMargin: Math.max(20, Math.min(width, height) * 0.035)
            readonly property real cardWidth: Math.min(320, Math.max(210, width * 0.22))
            readonly property real cardHeight: Math.min(cardWidth * 0.68, height * 0.42)

            screen: modelData
            name: "window-switcher"
            visible: root.overlayVisible && root.targetScreen === modelData.name
            color: "transparent"

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.switching && visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            onVisibleChanged: {
                if (visible)
                    keyHandler.forceActiveFocus();
            }

            Item {
                id: keyHandler

                anchors.fill: parent
                focus: root.switching && win.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.cancel();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.commit();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        // The Tab that opened the layer can arrive once more while keyboard
                        // focus is being transferred. Ignore only that immediate duplicate.
                        if (Date.now() - root.openedAtMs >= 90)
                            root.step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
                        event.accepted = true;
                    }
                }

                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr) {
                        root.commit();
                        event.accepted = true;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colours.palette.m3scrim
                    opacity: root.presented ? 0.48 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    TapHandler {
                        onTapped: root.cancel()
                    }
                }

                Rectangle {
                    id: panel

                    anchors.centerIn: parent

                    width: Math.min(win.width - win.outerMargin * 2, Math.max(280, root.clients.length * win.cardWidth + Math.max(0, root.clients.length - 1) * Tokens.spacing.medium + Tokens.padding.extraLarge * 2))
                    height: content.implicitHeight + Tokens.padding.extraLarge * 2

                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.extraLarge
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant
                    clip: true

                    opacity: root.presented ? 1 : 0
                    scale: root.presented ? 1 : 0.96

                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Column {
                        id: content

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.padding.extraLarge
                        spacing: Tokens.spacing.medium

                        StyledText {
                            width: parent.width
                            text: qsTr("Chuyển cửa sổ")
                            font: Tokens.font.title.medium
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        ListView {
                            id: list

                            width: parent.width
                            height: win.cardHeight

                            orientation: ListView.Horizontal
                            spacing: Tokens.spacing.medium
                            clip: true
                            model: win.visible ? root.clients : []
                            currentIndex: root.selectedIndex
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: Tokens.anim.durations.expressiveFastSpatial
                            highlightResizeDuration: 0
                            preferredHighlightBegin: Math.max(0, width / 2 - win.cardWidth / 2)
                            preferredHighlightEnd: Math.min(width, width / 2 + win.cardWidth / 2)
                            highlightRangeMode: ListView.ApplyRange

                            highlight: Rectangle {
                                width: win.cardWidth
                                height: list.height
                                color: "transparent"
                                radius: Tokens.rounding.large
                                border.width: 3
                                border.color: Colours.palette.m3primary
                            }

                            delegate: Item {
                                id: card

                                required property var modelData
                                required property int index

                                readonly property bool selected: index === root.selectedIndex

                                width: win.cardWidth
                                height: list.height
                                scale: selected ? 0.97 : 0.93
                                opacity: selected ? 1 : 0.78

                                Behavior on scale {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }

                                Behavior on opacity {
                                    Anim {
                                        type: Anim.FastEffects
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 5

                                    color: card.selected ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh
                                    radius: Tokens.rounding.large
                                    clip: true

                                    Behavior on color {
                                        CAnim {}
                                    }

                                    Rectangle {
                                        id: previewFrame

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: details.top
                                        anchors.margins: Tokens.padding.small

                                        color: Colours.palette.m3surface
                                        radius: Tokens.rounding.medium
                                        clip: true

                                        ScreencopyView {
                                            id: preview

                                            anchors.centerIn: parent
                                            width: Math.min(parent.width, implicitWidth)
                                            height: Math.min(parent.height, implicitHeight)

                                            captureSource: card.modelData?.wayland ?? null // qmllint disable unresolved-type
                                            live: false
                                            constraintSize.width: parent.width
                                            constraintSize.height: parent.height
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: Tokens.spacing.extraSmall
                                            visible: !preview.hasContent

                                            MaterialIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "web_asset_off"
                                                color: Colours.palette.m3outline
                                                fontStyle: Tokens.font.icon.extraLarge
                                            }

                                            StyledText {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: Math.min(implicitWidth, previewFrame.width - Tokens.padding.large * 2)
                                                text: qsTr("Không có ảnh xem trước")
                                                color: Colours.palette.m3outline
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Item {
                                        id: details

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: Math.max(icon.height, title.implicitHeight + workspace.implicitHeight) + Tokens.padding.medium * 2

                                        IconImage {
                                            id: icon

                                            anchors.left: parent.left
                                            anchors.leftMargin: Tokens.padding.medium
                                            anchors.verticalCenter: parent.verticalCenter
                                            implicitSize: 34
                                            source: Icons.getAppIcon(card.modelData?.lastIpcObject.class ?? "", "image-missing")
                                        }

                                        StyledText {
                                            id: title

                                            anchors.left: icon.right
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.leftMargin: Tokens.spacing.medium
                                            anchors.rightMargin: Tokens.padding.medium
                                            anchors.topMargin: Tokens.padding.medium

                                            text: card.modelData?.title ?? qsTr("Cửa sổ không có tiêu đề")
                                            font: Tokens.font.body.medium
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            id: workspace

                                            anchors.left: title.left
                                            anchors.right: title.right
                                            anchors.top: title.bottom

                                            text: card.modelData?.workspace?.name === "special:minimized" ? qsTr("Đã thu nhỏ") : qsTr("Không gian %1").arg(card.modelData?.workspace?.name ?? "?")
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    TapHandler {
                                        onTapped: {
                                            root.selectedIndex = card.index;
                                            root.commit();
                                        }
                                    }
                                }
                            }
                        }

                        StyledText {
                            width: parent.width
                            text: qsTr("Giữ Alt và nhấn Tab để chọn • Thả Alt để mở • Esc để hủy")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
