import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, mapped to GlobalConfig.notifs.fullscreen
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: qsTr("Tắt")
            icon: "notifications_off"
        },
        MenuItem {
            text: qsTr("Bật")
            icon: "notifications"
        }
    ]
    readonly property list<string> notifFullscreenValues: ["off", "on"]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: qsTr("Tắt")
            icon: "notifications_off"
        },
        MenuItem {
            text: qsTr("Quan trọng")
            icon: "priority_high"
        },
        MenuItem {
            text: qsTr("Bật")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: qsTr("Thông báo")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: qsTr("Thông báo")
        }

        SelectRow {
            first: true
            label: qsTr("Hiện trong chế độ toàn màn hình")
            subtext: qsTr("Có hiển thị thông báo trên ứng dụng toàn màn hình không")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[Math.max(0, root.notifFullscreenValues.indexOf(GlobalConfig.notifs.fullscreen))]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.notifFullscreenValues[root.notifFullscreenItems.indexOf(item)]
        }

        ToggleRow {
            text: qsTr("Tự động hết hạn")
            subtext: qsTr("Tự đóng thông báo khi hết thời gian chờ")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            text: qsTr("Mở ở trạng thái mở rộng")
            subtext: qsTr("Mặc định hiển thị thông báo ở trạng thái mở rộng")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            label: qsTr("Thời gian chờ mặc định")
            subtext: qsTr("Thời gian trước khi đóng thông báo (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Số thông báo xem trước trong nhóm")
            subtext: qsTr("Số thông báo mỗi nhóm trước khi thu gọn")
            value: GlobalConfig.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = Math.round(v)
        }

        // Toasts
        SectionHeader {
            text: qsTr("Thông báo nổi")
        }

        SelectRow {
            first: true
            label: qsTr("Hiện trong chế độ toàn màn hình")
            subtext: qsTr("Có hiển thị thông báo nổi trên ứng dụng toàn màn hình không")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(GlobalConfig.utilities.toasts.fullscreen))]
            onSelected: item => GlobalConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: qsTr("Số thông báo nổi hiển thị")
            subtext: qsTr("Số thông báo nổi tối đa cùng lúc")
            value: GlobalConfig.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: qsTr("Sự kiện thông báo nổi")
        }

        ToggleRow {
            first: true
            text: qsTr("Thay đổi trạng thái sạc")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi chế độ trò chơi")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi chế độ Không làm phiền")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi đầu ra âm thanh")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi đầu vào âm thanh")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi trạng thái khóa chữ hoa")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi trạng thái khóa số")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi bố cục bàn phím")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            text: qsTr("Thay đổi VPN")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Đang phát")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
        }
    }
}
