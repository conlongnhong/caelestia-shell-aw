pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Màn hình")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            visible: !DisplayManager.available
            first: true
            last: true
            icon: "monitor_off"
            label: qsTr("Backend màn hình không khả dụng")
            subtext: DisplayManager.error || qsTr("Cần Hyprland và hyprctl để quản lý output")
        }

        Repeater {
            id: monitorRepeater

            model: DisplayManager.monitors

            ConnectedRect {
                id: monitorRow

                required property var modelData
                required property int index
                Layout.fillWidth: true

                implicitHeight: monitorLayout.implicitHeight + Tokens.padding.medium * 2
                first: index === 0
                last: index === monitorRepeater.count - 1

                StateLayer {
                    onClicked: {
                        root.nState.selectedDisplayName = monitorRow.modelData.name;
                        root.nState.openSubPage(1);
                    }
                }

                RowLayout {
                    id: monitorLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon { text: monitorRow.modelData.focused ? "monitor" : "desktop_windows"; fontStyle: Tokens.font.icon.medium }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText { Layout.fillWidth: true; text: monitorRow.modelData.description || monitorRow.modelData.name; font: Tokens.font.body.small; elide: Text.ElideRight }
                        StyledText { Layout.fillWidth: true; text: `${DisplayManager.modeText(monitorRow.modelData)} • ${monitorRow.modelData.scale}×`; color: Colours.palette.m3outline; font: Tokens.font.label.small; elide: Text.ElideRight }
                    }
                    MaterialIcon { text: "chevron_right"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.medium }
                }
            }
        }

        SectionHeader { text: qsTr("Ánh sáng ban đêm") }

        ToggleRow {
            first: true
            text: qsTr("Giảm ánh sáng xanh")
            subtext: DisplayManager.nightLightAvailable ? qsTr("Dùng hyprsunset qua IPC của Hyprland") : qsTr("hyprsunset chưa chạy hoặc không khả dụng")
            checked: DisplayManager.nightLightEnabled
            enabled: DisplayManager.nightLightAvailable
            opacity: enabled ? 1 : 0.55
            onToggled: DisplayManager.setNightLightEnabled(checked)
        }

        StepperRow {
            last: true
            label: qsTr("Nhiệt độ màu")
            subtext: qsTr("Giá trị thấp hơn cho màu ấm hơn (Kelvin)")
            value: DisplayManager.nightLightTemperature
            from: 1000
            to: 6000
            stepSize: 100
            enabled: DisplayManager.nightLightAvailable
            opacity: enabled ? 1 : 0.55
            onMoved: value => DisplayManager.setNightLightTemperature(value)
        }

        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            implicitHeight: refreshButton.implicitHeight + Tokens.padding.medium * 2
            first: true
            last: true

            IconTextButton {
                id: refreshButton

                anchors.centerIn: parent
                icon: "refresh"
                text: qsTr("Làm mới output")
                type: IconTextButton.Tonal
                disabled: DisplayManager.refreshing
                onClicked: DisplayManager.refresh()
            }
        }
    }
}
