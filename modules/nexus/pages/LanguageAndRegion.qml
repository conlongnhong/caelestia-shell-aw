import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24 giờ")
        },
        MenuItem {
            text: qsTr("12 giờ")
        }
    ]

    title: qsTr("Ngôn ngữ & khu vực")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: qsTr("Ngôn ngữ")
        }

        // Read-only: the shell follows the system locale (no in-shell translations yet)
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

            RowLayout {
                id: localeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Ngôn ngữ hệ thống")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Theo ngôn ngữ hệ thống (%1)").arg(Qt.locale().name)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    text: Qt.locale().nativeLanguageName || Qt.locale().name
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Weather
        SectionHeader {
            text: qsTr("Thời tiết")
        }

        // Placeholder until the map-based location picker lands
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: comingSoon.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: comingSoon

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.padding.extraSmall

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "map"
                    color: Colours.palette.m3outlineVariant
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Tính năng chọn vị trí sắp ra mắt")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Chọn vị trí thời tiết trên bản đồ trong bản cập nhật sau")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Units
        SectionHeader {
            text: qsTr("Đơn vị")
        }

        SelectRow {
            first: true
            label: qsTr("Nhiệt độ")
            subtext: qsTr("Đơn vị nhiệt độ thời tiết")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheit = root.tempItems.indexOf(item) === 1
        }

        SelectRow {
            last: true
            label: qsTr("Nhiệt độ hệ thống")
            subtext: qsTr("Đơn vị nhiệt độ CPU và GPU")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1
        }

        // Time & date
        SectionHeader {
            text: qsTr("Ngày & giờ")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Định dạng đồng hồ")
            subtext: qsTr("Cách hiển thị thời gian trong toàn bộ giao diện")
            menuItems: root.clockItems
            active: root.clockItems[GlobalConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => GlobalConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }
    }
}
