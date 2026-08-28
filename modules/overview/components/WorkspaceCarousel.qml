pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import ".."

Item {
    id: root

    required property HyprlandMonitor monitor
    signal closeRequested

    readonly property var workspaceIds: OverviewState.getNormalWorkspaceIds(monitor)
    readonly property var workspaceRows: OverviewState.getNormalWorkspaceRows(monitor)
    readonly property real cardWidth: Math.max(Tokens.font.body.medium.pointSize * 20, (root.width - Tokens.padding.large * 2 - root.cardSpacing * 4) / 5)
    readonly property real cardHeight: cardWidth * (9 / 16) + Tokens.font.body.medium.pointSize + Tokens.padding.small * 2 + Tokens.padding.extraSmall
    readonly property real cardSpacing: Tokens.spacing.medium
    readonly property real sidePadding: Tokens.padding.large

    implicitWidth: parent.width
    implicitHeight: root.cardHeight * 2 + root.cardSpacing + root.sidePadding * 2 + Tokens.padding.large

    function centerFocusedWorkspace(): void {
        const focusedId = Hypr.focusedWorkspace?.id;
        const idx = root.workspaceIds.indexOf(focusedId);
        if (idx >= 0) {
            const targetY = Math.floor(idx / 5) * (root.cardHeight + root.cardSpacing);
            flickable.contentY = Math.max(0, Math.min(Math.max(0, flickable.contentHeight - flickable.height), targetY));
        } else {
            flickable.contentY = 0;
        }
    }

    Component.onCompleted: Qt.callLater(centerFocusedWorkspace)

    Connections {
        target: Hypr
        function onFocusedWorkspaceChanged(): void {
            root.centerFocusedWorkspace();
        }
    }

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.bottom: pagination.top
        anchors.bottomMargin: Tokens.padding.medium
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: rowsColumn.implicitWidth + root.sidePadding * 2
        contentHeight: rowsColumn.implicitHeight + root.sidePadding * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentY {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: container
            width: flickable.contentWidth
            height: flickable.contentHeight

            Column {
                id: rowsColumn
                x: Math.max(root.sidePadding, (container.width - implicitWidth) / 2)
                y: root.sidePadding
                spacing: root.cardSpacing

                Repeater {
                    model: root.workspaceRows

                    Row {
                        required property var modelData
                        required property int index
                        spacing: root.cardSpacing
                        visible: index === 0 || modelData.some(id => root.workspaceIds.indexOf(id) > 4)
                        height: visible ? root.cardHeight : 0

                        Repeater {
                            model: modelData

                            WorkspaceCard {
                                baseWidth: root.cardWidth
                                monitor: root.monitor
                                dragLayer: dragLayer

                                onClicked: {
                                    OverviewState.focusWorkspace(modelData, () => root.closeRequested());
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: dragLayer
        anchors.fill: parent
        clip: false
        z: 1000
    }

    Row {
        id: pagination
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.small
        visible: root.workspaceRows.length > 1

        Repeater {
            model: root.workspaceRows.length

            StyledRect {
                required property int index
                implicitWidth: (Math.floor(((Hypr.focusedWorkspace?.id ?? 1) - 1) / 5) === this.index) ? 18 : 6
                implicitHeight: 6
                radius: Tokens.rounding.full
                color: (Math.floor(((Hypr.focusedWorkspace?.id ?? 1) - 1) / 5) === this.index) ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

                Behavior on implicitWidth { Anim {} }
                Behavior on color { CAnim {} }
            }
        }
    }
}
