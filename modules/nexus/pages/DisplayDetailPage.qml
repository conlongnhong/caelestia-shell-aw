pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var monitor: DisplayManager.monitors.find(m => m.name === nState.selectedDisplayName) ?? null
    property string mode: monitor ? DisplayManager.modeText(monitor) : ""
    property real displayScale: monitor?.scale ?? 1
    property int displayTransform: monitor?.transform ?? 0
    property int displayX: monitor?.x ?? 0
    property int displayY: monitor?.y ?? 0

    title: monitor?.description || monitor?.name || qsTr("Màn hình")
    isSubPage: true

    onMonitorChanged: if (!monitor) nState.closeSubPage()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        TextFieldRow {
            label: qsTr("Độ phân giải & tần số")
            subtext: qsTr("Ví dụ: 2560x1440@144")
            value: root.mode
            emptyIsValid: false
            validate: text => /^\d+x\d+@[\d.]+$/.test(text)
            onCommitted: value => root.mode = value
        }
        StepperRow { label: qsTr("Tỉ lệ"); value: root.displayScale; from: 0.5; to: 4; stepSize: 0.05; onMoved: value => root.displayScale = value }
        StepperRow { label: qsTr("Xoay / lật"); subtext: qsTr("0–3: xoay; 4–7: lật và xoay"); value: root.displayTransform; from: 0; to: 7; stepSize: 1; onMoved: value => root.displayTransform = value }
        StepperRow { label: qsTr("Vị trí X"); value: root.displayX; from: -16384; to: 16384; stepSize: 1; onMoved: value => root.displayX = value }
        StepperRow { last: true; label: qsTr("Vị trí Y"); value: root.displayY; from: -16384; to: 16384; stepSize: 1; onMoved: value => root.displayY = value }

        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            implicitHeight: applyButton.implicitHeight + Tokens.padding.medium * 2
            first: true
            last: true

            IconTextButton {
                id: applyButton

                anchors.centerIn: parent
                icon: "check"
                text: qsTr("Áp dụng cho output này")
                type: IconTextButton.Tonal
                disabled: !root.monitor
                onClicked: DisplayManager.applyMonitor(root.monitor, root.mode, root.displayScale, root.displayTransform, root.displayX, root.displayY)
            }
        }
    }
}
