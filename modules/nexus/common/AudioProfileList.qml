pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

ItemList {
    id: root

    property var node: null
    readonly property var profiles: AudioProfiles.profilesForNode(node)
    readonly property string activeProfile: AudioProfiles.activeProfileForNode(node)

    showList: AudioProfiles.available && profiles.length > 0
    placeholderIcon: "tune"
    placeholderText: AudioProfiles.available ? qsTr("Thiết bị không cung cấp profile") : qsTr("Không có backend profile âm thanh")
    model: ScriptModel { values: root.profiles }

    delegate: Item {
        id: profileRow

        required property var modelData
        required property int index
        readonly property bool active: modelData?.name === root.activeProfile

        anchors.left: root.list.contentItem.left
        anchors.right: root.list.contentItem.right
        implicitHeight: profileLayout.implicitHeight + Tokens.padding.medium * 2

        StateLayer {
            radius: Tokens.rounding.extraSmall
            bottomLeftRadius: profileRow.index === root.list.count - 1 ? Tokens.rounding.extraLarge : radius
            bottomRightRadius: bottomLeftRadius
            onClicked: AudioProfiles.setProfile(root.node, profileRow.modelData.name)
        }
        RowLayout {
            id: profileLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: profileRow.modelData?.description || profileRow.modelData?.name || qsTr("Không rõ")
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
            MaterialIcon {
                text: "check"
                color: Colours.palette.m3primary
                opacity: profileRow.active ? 1 : 0

                Behavior on opacity { Anim { type: Anim.DefaultEffects } }
            }
        }
    }
}
