pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.images
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.dashboard.dash as DashboardDash
import qs.modules.dashboard.media as DashboardMedia

Item {
    id: root

    required property ShellScreen screen

    readonly property real designScale: Math.min(width / 1920, height / 1080)
    readonly property real canvasX: Math.max(0, (width - 1920 * designScale) / 2)
    readonly property real canvasY: Math.max(0, (height - 1080 * designScale) / 2)
    readonly property real safeLeft: ShellState.componentsFor(screen)?.bar?.exclusiveZone ?? 52
    readonly property var screenState: ShellState.forScreen(screen)
    readonly property color cardColour: Colours.palette.m3surfaceContainer
    readonly property color cardColourHigh: Colours.palette.m3surfaceContainerHigh
    readonly property color accentColour: Colours.palette.m3primaryContainer
    readonly property color onAccentColour: Colours.palette.m3onPrimaryContainer
    readonly property color textColour: Colours.palette.m3onSurface
    readonly property color mutedColour: Colours.palette.m3onSurfaceVariant
    readonly property color outlineColour: Colours.palette.m3outline
    readonly property real cardOpacity: 0.82

    property string convertFormat: "WEBP"
    property string convertStatus: qsTr("Thả ảnh vào đây")
    property string convertOutput
    property var worldTimes: ({
            "Sydney": ["--:--", "AEST"],
            "Tokyo": ["--:--", "JST"],
            "London": ["--:--", "BST"],
            "New York": ["--:--", "EDT"]
        })

    Component.onCompleted: Weather.reload()

    function formatPercent(value: real): string {
        return `${Math.round(Math.max(0, Math.min(1, value)) * 100)}%`;
    }

    function cycleConvertFormat(): void {
        const formats = ["WEBP", "PNG", "JPG"];
        const index = formats.indexOf(convertFormat);
        convertFormat = formats[(index + 1) % formats.length];
    }

    function convertFirstUrl(urls: var): bool {
        if (!urls || urls.length === 0 || converter.running)
            return false;

        const sourceUrl = String(urls[0]);
        if (!sourceUrl.startsWith("file://")) {
            convertStatus = qsTr("Chỉ hỗ trợ tệp ảnh cục bộ");
            return false;
        }

        const input = Paths.toLocalFile(urls[0]);
        const extension = input.slice(input.lastIndexOf(".") + 1).toLowerCase();
        const supported = ["png", "jpg", "jpeg", "webp", "avif", "bmp", "tif", "tiff", "gif"];
        if (!input || !supported.includes(extension)) {
            convertStatus = qsTr("Định dạng ảnh chưa được hỗ trợ");
            return false;
        }

        const slash = input.lastIndexOf("/");
        const dot = input.lastIndexOf(".");
        const base = dot > slash ? input.slice(0, dot) : input;
        const suffix = convertFormat.toLowerCase();
        const stamp = Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        convertOutput = `${base}_caelestia_${stamp}.${suffix}`;
        convertStatus = qsTr("Đang chuyển sang %1…").arg(convertFormat);

        let args = ["-hide_banner", "-loglevel", "error", "-n", "-i", input, "-frames:v", "1"];
        if (convertFormat === "WEBP")
            args.push("-quality", "90");
        else if (convertFormat === "JPG")
            args.push("-q:v", "2");
        args.push(convertOutput);
        converter.command = ["sh", "-c", "command -v ffmpeg >/dev/null 2>&1 || exit 127; exec ffmpeg \"$@\"", "caelestia-converter", ...args];
        converter.running = true;
        return true;
    }

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    Timer {
        interval: 1000
        repeat: true
        running: Players.active?.isPlaying ?? false
        onTriggered: Players.active?.positionChanged()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!worldClockProcess.running)
                worldClockProcess.running = true;
        }
    }

    Process {
        id: worldClockProcess

        command: ["sh", "-c", "fmt='" + (GlobalConfig.services.useTwelveHourClock ? "%I:%M %p" : "%H:%M") + "'; for spec in 'Sydney|Australia/Sydney' 'Tokyo|Asia/Tokyo' 'London|Europe/London' 'New York|America/New_York'; do name=${spec%%|*}; zone=${spec#*|}; printf '%s|' \"$name\"; TZ=\"$zone\" date \"+$fmt|%Z\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = Object.assign({}, root.worldTimes);
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    const parts = line.split("|");
                    if (parts.length >= 3)
                        next[parts[0]] = [parts[1], parts[2]];
                }
                root.worldTimes = next;
            }
        }
    }

    Process {
        id: converter

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.convertStatus = qsTr("Đã lưu: %1").arg(Paths.shortenHome(root.convertOutput));
                Quickshell.execDetached(["notify-send", "-a", "Caelestia", "Chuyển ảnh hoàn tất", root.convertOutput]);
            } else {
                root.convertStatus = qsTr("Không thể chuyển ảnh");
                Quickshell.execDetached(["notify-send", "-u", "critical", "Caelestia", "Không thể chuyển ảnh bằng ffmpeg"]);
            }
        }
    }

    Item {
        id: canvas

        width: 1920
        height: 1080
        x: root.canvasX
        y: root.canvasY
        scale: root.designScale
        transformOrigin: Item.TopLeft

        Item {
            id: clockBlock

            x: Math.max(86, root.safeLeft / Math.max(root.designScale, 0.01) + 28)
            y: 158
            width: 440
            height: 178

            StyledText {
                id: largeClock

                anchors.left: parent.left
                anchors.top: parent.top
                text: `${Time.hourStr}:${Time.minuteStr}`
                color: root.textColour
                font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 2.4).weight(Font.Bold).build()
            }

            Rectangle {
                x: 0
                y: 111
                width: dateLine.implicitWidth + 22
                height: 30
                radius: height / 2
                color: Qt.alpha(root.accentColour, 0.74)
                border.width: 1
                border.color: Qt.alpha(root.outlineColour, 0.35)

                StyledText {
                    id: dateLine

                    anchors.centerIn: parent
                    text: Time.format("dddd, dd MMMM yyyy")
                    color: root.onAccentColour
                    font: Tokens.font.label.medium
                }
            }

            StyledText {
                x: 0
                y: 153
                text: "CAELESTIA  ·  HOME"
                color: root.mutedColour
                font: Tokens.font.label.builders.small.letterSpacing(1.7).build()
            }
        }

        HomeCard {
            id: mediaCard

            x: Math.max(76, root.safeLeft / Math.max(root.designScale, 0.01) + 18)
            y: 350
            width: 440
            height: 338
            baseColour: root.cardColour

            Item {
                id: mediaHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 116

                StyledClippingRect {
                    id: artFrame

                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: 118
                    height: 118
                    radius: mediaCard.radius
                    color: Qt.alpha(root.accentColour, 0.78)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "graphic_eq"
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    Image {
                        anchors.fill: parent
                        source: Players.getArtUrl(Players.active)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                }

                Column {
                    anchors.left: artFrame.right
                    anchors.right: controls.left
                    anchors.leftMargin: 17
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    StyledText {
                        width: parent.width
                        text: Players.active?.trackArtist || qsTr("Trình phát nhạc")
                        color: root.textColour
                        font: Tokens.font.title.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text: Players.active?.trackTitle || qsTr("Chưa có bài hát")
                        color: root.mutedColour
                        font: Tokens.font.body.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text: Players.active?.trackAlbum || qsTr("Mở trình phát để bắt đầu")
                        color: Qt.alpha(root.mutedColour, 0.72)
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                Column {
                    id: controls

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    HomeAction {
                        icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                        emphasized: true
                        enabled: Players.active?.canTogglePlaying ?? false
                        onClicked: Players.active?.togglePlaying()
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        HomeAction {
                            implicitWidth: 30
                            implicitHeight: 30
                            icon: "skip_previous"
                            enabled: Players.active?.canGoPrevious ?? false
                            onClicked: Players.active?.previous()
                        }

                        HomeAction {
                            implicitWidth: 30
                            implicitHeight: 30
                            icon: "skip_next"
                            enabled: Players.active?.canGoNext ?? false
                            onClicked: Players.active?.next()
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mediaHeader.bottom
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                height: 1
                color: Qt.alpha(root.outlineColour, 0.28)
            }

            DashboardMedia.LyricList {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: mediaHeader.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 20
                anchors.topMargin: 16
            }
        }

        HomeCard {
            id: converterCard

            x: 1164
            y: 32
            width: 282
            height: 252
            baseColour: root.cardColourHigh

            StyledText {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 15
                text: "PNG · JPG · WEBP · AVIF · BMP · TIFF"
                color: root.mutedColour
                font: Tokens.font.label.builders.small.scale(0.82).letterSpacing(0.35).build()
            }

            Rectangle {
                id: dropTarget

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 42
                height: 142
                radius: 24
                color: dropArea.containsDrag ? Qt.alpha(root.accentColour, 0.76) : Qt.alpha(root.cardColour, 0.34)
                border.width: 2
                border.color: dropArea.containsDrag ? root.onAccentColour : Qt.alpha(root.outlineColour, 0.66)

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 34
                    spacing: 8

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: converter.running ? "progress_activity" : "add_photo_alternate"
                        color: dropArea.containsDrag ? root.onAccentColour : root.mutedColour
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        width: parent.width
                        text: root.convertStatus
                        color: dropArea.containsDrag ? root.onAccentColour : root.mutedColour
                        font: Tokens.font.body.small
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideMiddle
                    }
                }

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    onDropped: drop => {
                        if (root.convertFirstUrl(drop.urls))
                            drop.acceptProposedAction();
                    }
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: formatButton.verticalCenter
                text: qsTr("Chuyển sang")
                color: root.mutedColour
                font: Tokens.font.body.small
            }

            StyledClippingRect {
                id: formatButton

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                width: 116
                height: 42
                radius: height / 2
                color: Qt.alpha(root.accentColour, 0.8)

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    MaterialIcon {
                        text: "sync"
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: root.convertFormat
                        color: root.onAccentColour
                        font: Tokens.font.label.medium
                    }

                    MaterialIcon {
                        text: "keyboard_arrow_down"
                        color: root.onAccentColour
                        fontStyle: Tokens.font.icon.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleConvertFormat()
                }
            }
        }

        HomeCard {
            id: worldClockCard

            x: 1462
            y: 32
            width: 286
            height: 252
            baseColour: root.cardColour

            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: 14
                anchors.leftMargin: 16
                spacing: 7

                MaterialIcon {
                    text: "location_on"
                    color: root.mutedColour
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: Weather.city || qsTr("Giờ địa phương")
                    color: root.mutedColour
                    font: Tokens.font.label.medium
                }
            }

            StyledText {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 48
                text: Time.timeStr
                color: root.textColour
                font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
            }

            StyledText {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 91
                text: Time.format("dddd, dd MMMM")
                color: root.mutedColour
                font: Tokens.font.body.small
            }

            Grid {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 13
                columns: 2
                spacing: 7

                Repeater {
                    model: ["Sydney", "Tokyo", "London", "New York"]

                    Rectangle {
                        required property string modelData

                        width: 126
                        height: 51
                        radius: 17
                        color: Qt.alpha(root.accentColour, 0.66)

                        StyledText {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            anchors.topMargin: 7
                            text: parent.modelData
                            color: root.mutedColour
                            font: Tokens.font.label.small
                        }

                        StyledText {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 10
                            anchors.bottomMargin: 6
                            text: root.worldTimes[parent.modelData]?.[0] ?? "--:--"
                            color: root.onAccentColour
                            font: Tokens.font.title.small
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 9
                            anchors.topMargin: 8
                            text: root.worldTimes[parent.modelData]?.[1] ?? ""
                            color: Qt.alpha(root.onAccentColour, 0.62)
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }

        Column {
            x: 1770
            y: 32
            width: 122
            spacing: 12

            MetricCard {
                icon: "memory"
                label: "CPU"
                valueText: root.formatPercent(Cpu.percentage)
                progress: Cpu.percentage
            }

            MetricCard {
                icon: "memory_alt"
                label: "RAM"
                valueText: root.formatPercent(Memory.percentage)
                progress: Memory.percentage
            }

            MetricCard {
                icon: "hard_disk"
                label: qsTr("Ổ đĩa")
                valueText: root.formatPercent(Storage.primaryDisk?.perc ?? Storage.percentage)
                progress: Storage.primaryDisk?.perc ?? Storage.percentage
            }

            MetricCard {
                icon: Weather.icon
                label: Weather.city || qsTr("Thời tiết")
                valueText: Weather.temp
                progress: 0
                showProgress: false
            }
        }

        HomeCard {
            id: profileCard

            x: 1462
            y: 310
            width: 286
            height: 218
            baseColour: root.cardColourHigh

            StyledClippingRect {
                id: avatar

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 18
                anchors.topMargin: 18
                width: 64
                height: 64
                radius: width / 2
                color: root.accentColour

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "person"
                    color: root.onAccentColour
                    fontStyle: Tokens.font.icon.large
                }

                CachingImage {
                    anchors.fill: parent
                    path: `${Paths.home}/.face`
                    fillMode: Image.PreserveAspectCrop
                }
            }

            Column {
                anchors.left: avatar.right
                anchors.right: parent.right
                anchors.leftMargin: 13
                anchors.rightMargin: 16
                anchors.verticalCenter: avatar.verticalCenter
                spacing: 4

                StyledText {
                    width: parent.width
                    text: `${SysInfo.user}@${SysInfo.hostname}`
                    color: root.textColour
                    font: Tokens.font.title.small
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: qsTr("Hoạt động %1").arg(SysInfo.uptime)
                    color: root.mutedColour
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            Row {
                anchors.left: parent.left
                anchors.top: avatar.bottom
                anchors.leftMargin: 18
                anchors.topMargin: 15
                spacing: 6

                MaterialIcon {
                    text: Weather.icon
                    color: root.mutedColour
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    width: 218
                    text: Weather.description
                    color: root.mutedColour
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                spacing: 9

                Rectangle {
                    width: 126
                    height: 43
                    radius: height / 2
                    color: root.onAccentColour

                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        MaterialIcon {
                            text: "lock"
                            color: root.accentColour
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: qsTr("Khóa máy")
                            color: root.accentColour
                            font: Tokens.font.label.medium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["caelestia", "shell", "lock", "lock"])
                    }
                }

                HomeAction {
                    icon: "settings"
                    onClicked: WindowFactory.create(root.screen)
                }

                HomeAction {
                    icon: "power_settings_new"
                    onClicked: {
                        if (root.screenState)
                            root.screenState.session = !root.screenState.session;
                    }
                }
            }
        }

        HomeCard {
            id: calendarCard

            x: 1462
            y: 552
            width: 286
            height: 268
            baseColour: root.cardColour
            clip: true

            Loader {
                anchors.fill: parent
                active: root.screenState !== null

                sourceComponent: DashboardDash.Calendar {
                    screenState: root.screenState
                }
            }
        }
    }

    component HomeCard: Rectangle {
        property color baseColour: root.cardColour

        radius: 28
        color: Qt.alpha(baseColour, root.cardOpacity)
        border.width: 1
        border.color: Qt.alpha(root.outlineColour, 0.3)

        Behavior on color {
            CAnim {}
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    component HomeAction: Rectangle {
        id: action

        property string icon
        property bool emphasized: false
        signal clicked

        implicitWidth: emphasized ? 44 : 42
        implicitHeight: implicitWidth
        radius: width / 2
        color: emphasized ? root.onAccentColour : Qt.alpha(root.accentColour, 0.84)
        opacity: enabled ? 1 : 0.38

        MaterialIcon {
            anchors.centerIn: parent
            text: action.icon
            color: action.emphasized ? root.accentColour : root.onAccentColour
            fontStyle: action.emphasized ? Tokens.font.icon.medium : Tokens.font.icon.small
            fill: 1
        }

        MouseArea {
            anchors.fill: parent
            enabled: action.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component MetricCard: HomeCard {
        id: metric

        required property string icon
        required property string label
        required property string valueText
        required property real progress
        property bool showProgress: true

        width: 122
        height: 112
        radius: 27
        baseColour: root.cardColourHigh

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, metric.progress))
            height: 5
            radius: 3
            color: Colours.palette.m3primary
            visible: metric.showProgress
            opacity: 0.72

            Behavior on width {
                Anim {}
            }
        }

        MaterialIcon {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 15
            text: metric.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        StyledText {
            anchors.left: parent.left
            anchors.bottom: labelText.top
            anchors.leftMargin: 15
            anchors.bottomMargin: 1
            text: metric.valueText
            color: root.textColour
            font: Tokens.font.title.builders.large.weight(Font.Bold).build()
        }

        StyledText {
            id: labelText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 15
            anchors.rightMargin: 10
            anchors.bottomMargin: 12
            text: metric.label
            color: root.mutedColour
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }
}
