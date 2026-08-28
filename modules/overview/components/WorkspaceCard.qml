pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import ".."

Item {
    id: root

    required property int modelData
    required property HyprlandMonitor monitor
    required property int index
    required property Item dragLayer
    readonly property int workspaceId: modelData
    property string workspaceName: ""
    property int cardIndex: index
    property real baseWidth: Tokens.font.body.medium.pointSize * 20
    property real baseHeight: baseWidth * (9 / 16)
    readonly property real cardPadding: Tokens.padding.small
    readonly property real headerHeight: Math.max(Tokens.font.body.medium.pointSize, Tokens.font.label.medium.pointSize) + cardPadding * 2

    readonly property bool isFocused: Hypr.focusedWorkspace?.id === workspaceId
    readonly property bool isActiveOnMonitor: monitor?.activeWorkspace?.id === workspaceId
    readonly property bool isSelected: OverviewState.selectedCardIndex === cardIndex
    readonly property var toplevels: OverviewState.getToplevelsForWorkspace(workspaceId)

    signal clicked

    implicitWidth: baseWidth
    implicitHeight: baseHeight + headerHeight + Tokens.padding.extraSmall

    scale: hoverHandler.hovered || isSelected ? 1.03 : (isFocused ? 1.01 : 1.0)

    Behavior on scale {
        Anim {}
    }

    // DropArea {
    //     id: dropArea
    //     anchors.fill: parent
    //     z: 10
    //     onDropped: drop => {
    //         if (drop.source) {
    //             OverviewState.moveWindowToWorkspace(drop.source.modelData ?? drop.source, workspaceId);
    //         }
    //     }
    // }

    // Top Card Header
    Row {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        // Workspace number badge
        StyledRect {
            implicitWidth: Tokens.font.label.medium.pointSize + cardPadding * 2
            implicitHeight: implicitWidth
            radius: Tokens.rounding.full
            color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                anchors.centerIn: parent
                text: root.workspaceId
                font: Tokens.font.label.builders.medium.weight(Font.Bold).build()
                color: root.isFocused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }
        }

        // Workspace Name
        StyledText {
            text: root.workspaceName || qsTr("Workspace %1").arg(root.workspaceId)
            font: Tokens.font.body.builders.medium.scale(1.15).weight(Font.DemiBold).build()
            color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3onSurface
            anchors.verticalCenter: parent.verticalCenter
        }

        // Focused / Active Status Pill inside Header
        StyledRect {
            implicitWidth: statusText.implicitWidth + cardPadding * 2
            implicitHeight: statusText.implicitHeight + Tokens.padding.extraSmall
            radius: Tokens.rounding.full
            visible: root.isFocused || root.isActiveOnMonitor
            color: root.isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
            border.width: 1
            border.color: root.isFocused ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                id: statusText

                anchors.centerIn: parent
                text: root.isFocused ? qsTr("Focused") : qsTr("Active")
                font: Tokens.font.label.builders.medium.weight(Font.Bold).build()
                color: root.isFocused ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }
        }

        Item {
            implicitWidth: 1
            implicitHeight: 1
            width: Math.max(1, header.width - (parent.children[0].width + parent.children[1].width + (parent.children[2].visible ? parent.children[2].width : 0) + parent.children[4].width + Tokens.spacing.small * 5))
        }

        // Window count badge
        Row {
            spacing: Tokens.spacing.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.toplevels.length
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }

            MaterialIcon {
                text: "filter_none"
                fontStyle: Tokens.font.icon.small
                color: Colours.palette.m3onSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Main Card Body (16:9 Screen Preview Area) with rounded clipping
    StyledRect {
        id: cardBody

        readonly property bool isDropTarget: OverviewState.dragHoverWorkspaceId === root.workspaceId

        anchors.top: header.bottom
        anchors.topMargin: Tokens.padding.extraSmall
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.baseHeight
        radius: Tokens.rounding.large
        z: 1

        color: Colours.layer(Colours.palette.m3surfaceContainer, 0)
        border.width: root.isFocused ? 2 : (root.isDropTarget ? 1.5 : (hoverHandler.hovered || root.isSelected ? 1.5 : 1))
        border.color: root.isFocused ? Colours.palette.m3primary : (root.isDropTarget ? Colours.palette.m3tertiary : (hoverHandler.hovered || root.isSelected ? Colours.palette.m3outline : Colours.palette.m3outlineVariant))

        Component.onCompleted: OverviewState.registerWorkspaceCard(root.workspaceId, cardBody)

        Component.onDestruction: OverviewState.unregisterWorkspaceCard(root.workspaceId, cardBody)

        Behavior on border.color {
            CAnim {}
        }
        Behavior on border.width {
            Anim {}
        }

        // Curved Content Wrapper
        ClippingWrapperRectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            radius: Tokens.rounding.large

            Item {
                anchors.fill: parent

                // Wallpaper preview inside desktop card
                Image {
                    id: wallPreview

                    anchors.fill: parent
                    source: Wallpapers.current ? `file://${Wallpapers.current}` : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.35
                    asynchronous: true
                }

                // Miniature windows viewport
                Item {
                    id: innerViewport

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    z: 1

                    Repeater {
                        model: root.toplevels

                        MiniWindow {
                            monitor: root.monitor
                            cardWidth: innerViewport.width
                            cardHeight: innerViewport.height
                            dragLayer: root.dragLayer
                            homeParent: innerViewport
                        }
                    }
                }
            }
        }

        // State layer for card clicks
        StateLayer {
            id: stateLayer

            anchors.fill: parent
            radius: Tokens.rounding.large
            onClicked: root.clicked()
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
