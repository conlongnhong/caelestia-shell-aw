pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            label: qsTr("Hình nền & kiểu dáng"),
            icon: "palette",
            description: qsTr("Hình nền, phông chữ, màu sắc"),
            category: "appearance"
        },

        // Connectivity
        // TODO
        // {
        //     label: qsTr("Màn hình"),
        //     icon: "monitor",
        //     description: qsTr("Cấu hình đầu ra"),
        //     category: "connectivity"
        // },
        {
            label: qsTr("Mạng"),
            icon: "wifi",
            description: qsTr("Wi-Fi, Ethernet"),
            category: "connectivity"
        },
        {
            label: qsTr("Thiết bị đã kết nối"),
            icon: "devices_other",
            description: qsTr("Bluetooth, ghép đôi"),
            category: "connectivity",
            noFill: true
        },
        {
            label: qsTr("Âm thanh"),
            icon: "volume_up",
            description: qsTr("Âm lượng ứng dụng, thiết bị âm thanh"),
            category: "connectivity"
        },

        // System
        {
            label: qsTr("Cập nhật"),
            icon: "update",
            description: qsTr("Cập nhật hệ thống"),
            category: "system"
        },
        {
            label: qsTr("Tiện ích bổ sung"),
            icon: "extension",
            description: qsTr("Quản lý tiện ích bổ sung"),
            category: "system"
        },

        // Shell
        {
            label: qsTr("Bảng"),
            icon: "dock_to_bottom",
            description: qsTr("Bảng điều khiển, thanh tác vụ, trình khởi chạy, thanh bên"),
            category: "shell"
        },
        {
            label: qsTr("Ứng dụng"),
            icon: "apps",
            description: qsTr("Ứng dụng mặc định, yêu thích và ứng dụng ẩn"),
            category: "shell"
        },
        {
            label: qsTr("Dịch vụ"),
            icon: "build",
            description: qsTr("Chu kỳ cập nhật, nguồn lời bài hát"),
            category: "shell"
        },
        {
            label: qsTr("Ngôn ngữ & khu vực"),
            icon: "globe",
            description: qsTr("Ngôn ngữ giao diện, vị trí thời tiết, đơn vị hiển thị"),
            category: "shell"
        },

        // About
        {
            label: qsTr("Giới thiệu"),
            icon: "info",
            description: qsTr("Thông tin hệ thống, ghi công"),
            category: "about"
        },
    ]
}
