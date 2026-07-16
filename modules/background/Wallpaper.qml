pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services

Item {
    id: root

    property bool completed
    property Image current: one
    readonly property url gifSource: sourceIsGif ? toFileUrl(source) : ""
    property string source: Wallpapers.current
    readonly property bool sourceIsGif: Wallpapers.isGif(source)
    readonly property bool sourceIsVideo: Wallpapers.isVideo(source)
    readonly property url videoSource: sourceIsVideo ? toFileUrl(source) : ""

    function toFileUrl(path) {
        const clean = Wallpapers.localPath(path);

        if (!clean)
            return "";
        if (clean[0] === "/") {
            // Encode path segments so # and ? remain filename characters.
            return "file://" + clean.split("/").map(segment => encodeURIComponent(segment)).join("/");
        }

        return Qt.resolvedUrl(clean);
    }
    function updateVideoPreview(): void {
        if (!sourceIsVideo)
            return;

        const preview = current === one ? two : one;
        preview.update();
    }

    Component.onCompleted: {
        if (sourceIsVideo) {
            one.update();
            completed = true;
        } else if (source) {
            Qt.callLater(() => {
                one.update();
                completed = true;
            });
        }
    }
    onSourceChanged: {
        if (sourceIsVideo) {
            const previous = current;
            current = null;
            videoUpdateTimer.restart();
            if (previous === one)
                two.update();
            else
                one.update();
        } else if (!source) {
            current = null;
        } else if (current === one) {
            two.update();
        } else {
            one.update();
        }
    }

    Timer {
        id: videoUpdateTimer

        interval: 50
        repeat: false

        onTriggered: {
            if (videoLoader.video && root.sourceIsVideo) {
                videoLoader.video.videoSource = root.videoSource;
                videoLoader.video.autoStart = !WallpaperPauser.paused;
            }
        }
    }
    Connections {
        function onPausedChanged() {
            if (videoLoader.video && root.sourceIsVideo) {
                videoLoader.video.autoStart = !WallpaperPauser.paused;
                if (WallpaperPauser.paused) {
                    videoLoader.video.pause();
                } else {
                    videoLoader.video.play();
                }
            }
        }

        ignoreUnknownSignals: true
        target: WallpaperPauser
    }
    Connections {
        function onCacheBusterChanged() {
            root.updateVideoPreview();
        }
        function onItemBustersChanged() {
            root.updateVideoPreview();
        }

        target: Wallpapers
    }
    Loader {
        active: root.completed && !root.source
        anchors.fill: parent
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                    text: "sentiment_stressed"
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                        text: qsTr("Thiếu hình nền?")
                    }
                    StyledRect {
                        color: Colours.palette.m3primary
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        radius: Tokens.rounding.full

                        FileDialog {
                            id: dialog

                            filterLabel: qsTr("Tệp hình ảnh và video")
                            filters: Wallpapers.validWallpaperExtensions
                            targetScreen: (root.QsWindow.window as QsWindow)?.screen
                            title: qsTr("Chọn hình nền")

                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }
                        StateLayer {
                            color: Colours.palette.m3onPrimary
                            radius: parent.radius

                            onClicked: dialog.open()
                        }
                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                            text: qsTr("Đặt ngay!")
                        }
                    }
                }
            }
        }
    }
    Img {
        id: one
    }
    Img {
        id: two
    }
    Loader {
        id: videoLoader

        readonly property VideoWallpaper video: item as VideoWallpaper

        active: root.sourceIsVideo
        anchors.fill: parent
        source: "VideoWallpaper.qml"

        onLoaded: {
            if (!video)
                return;

            video.autoStart = !WallpaperPauser.paused;
            video.videoSource = root.videoSource;
        }
    }
    AnimatedImage {
        id: gifWallpaper

        anchors.fill: parent
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        paused: WallpaperPauser.paused
        playing: root.sourceIsGif
        source: root.gifSource
        visible: root.sourceIsGif && status === Image.Ready
    }

    component Img: CachingImage {
        id: img

        function update(): void {
            const thumbnailBuster = Wallpapers.itemBusters[root.source] || Wallpapers.cacheBuster;
            const newPath = root.sourceIsVideo ? Wallpapers.getWallpaperThumb(root.source, thumbnailBuster) : root.source;

            if (!root.sourceIsVideo && path === root.source) {
                root.current = this;
                return;
            }

            if (root.sourceIsVideo && path === root.source && source === newPath) {
                root.current = this;
                return;
            }

            path = root.source;
            source = newPath;
        }

        anchors.fill: parent
        opacity: 0
        scale: Wallpapers.showPreview ? 1 : 0.8
        visible: !root.sourceIsVideo || !videoLoader.video || !videoLoader.video.hasRenderedFrame

        states: State {
            name: "visible"
            when: root.current === img

            PropertyChanges {
                img.opacity: 1
                img.scale: 1
            }
        }
        transitions: Transition {
            Anim {
                properties: "opacity,scale"
                target: img
            }
        }

        onStatusChanged: {
            if (status === Image.Ready)
                root.current = this;
        }
    }
}
