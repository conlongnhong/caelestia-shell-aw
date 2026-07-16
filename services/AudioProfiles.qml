pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool refreshing: false
    property var cards: []
    property string error: ""

    function refresh(): void {
        if (!refreshProc.running) {
            refreshing = true;
            refreshProc.running = true;
        }
    }

    function cardForNode(node: var): var {
        if (!node)
            return null;
        const props = node.properties ?? {};
        const cardId = String(props["device.id"] ?? "");
        const cardName = String(props["alsa.card_name"] ?? props["device.name"] ?? "");
        return cards.find(card => String(card.index) === cardId || card.name === cardName || card.properties?.["device.name"] === cardName) ?? null;
    }

    function profilesForNode(node: var): var {
        const card = cardForNode(node);
        if (!card)
            return [];
        const profiles = Array.isArray(card.profiles) ? card.profiles : Object.values(card.profiles ?? {});
        return profiles.filter(profile => profile && profile.available !== "no");
    }

    function activeProfileForNode(node: var): string {
        const active = cardForNode(node)?.active_profile;
        return typeof active === "string" ? active : (active?.name ?? "");
    }

    function setProfile(node: var, profileName: string): void {
        const card = cardForNode(node);
        if (!available || !card || !profileName || setProc.running)
            return;
        setProc.command = ["pactl", "set-card-profile", String(card.index), profileName];
        setProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: refreshProc

        command: ["pactl", "-f", "json", "list", "cards"]
        environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text || "[]");
                    root.cards = Array.isArray(parsed) ? parsed : [];
                    root.available = true;
                    root.error = "";
                } catch (e) {
                    root.cards = [];
                    root.available = false;
                    root.error = qsTr("Không đọc được profile âm thanh");
                }
            }
        }
        onExited: code => {
            root.refreshing = false;
            if (code !== 0) {
                root.available = false;
                root.cards = [];
                root.error = qsTr("pactl không khả dụng");
            }
        }
    }

    Process {
        id: setProc

        onExited: code => {
            if (code !== 0)
                root.error = qsTr("Không thể đổi profile âm thanh");
            root.refresh();
        }
    }
}
