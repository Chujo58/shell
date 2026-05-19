pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// CHANGED: Wrapped everything in a StyledRect base instead of an Item
// to ensure the entire window canvas honors the system rounding tokens
StyledRect {
    id: root

    required property ShellScreen screen
    readonly property Session session: Session {
        id: session

        root: root
    }

    readonly property int rounding: floating ? 0 : (Tokens.rounding ? Tokens.rounding.large : 8)

    property alias floating: session.floating

    signal close

    implicitWidth: implicitHeight * Tokens.sizes.controlCenter.ratio
    implicitHeight: screen.height * Tokens.sizes.controlCenter.heightMult

    required property CalendarState calState

    // Ensure the window background matches the layout theme
    color: Colours.tPalette.m3surface

    // Crucial: Clips the sidebar child from drawing over the newly rounded window corners
    clip: true
    radius: root.rounding

    GridLayout {
        anchors.fill: parent

        rowSpacing: 0
        columnSpacing: 0

        columns: 2
        rows: 2

        Loader {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.row: 0

            asynchronous: true
            active: root.floating

            sourceComponent: WindowTitle {
                screen: root.screen
                session: root.session
            }
        }

        // Column 0: Left Sidebar
        Item {
            Layout.row: 1
            Layout.column: 0
            Layout.fillHeight: true
            Layout.preferredWidth: 280

            CalendarSidebar {
                id: sideBar
                anchors.fill: parent
                anchors.left: undefined
                anchors.right: undefined
                calState: root.calState
            }
        }

        // Column 1: Main Content Workspace
        StyledRect {
            Layout.row: 1
            Layout.column: 1
            Layout.fillHeight: true
            Layout.fillWidth: true

            // Matches the outer container rounding profile perfectly
            topLeftRadius: root.rounding
            topRightRadius: root.rounding
            bottomLeftRadius: root.rounding
            bottomRightRadius: root.rounding
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                CalendarFloatingGrid {
                    id: floatingGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    calState: root.calState
                    currMonth: root.calState.currentDate.getMonth()
                    currYear: root.calState.currentDate.getFullYear()

                    onDaySelected: {
                        inspectorStack.currentIndex = 0;
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: Colours.tPalette.m3outlineVariant
                }

                StackLayout {
                    id: inspectorStack
                    Layout.preferredWidth: 260
                    Layout.fillHeight: true
                    currentIndex: 0

                    // VIEW 0: Agenda List Look
                    ColumnLayout {
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: root.calState.currentDate ? root.calState.currentDate.toLocaleString(Qt.locale(), "dddd, MMM d") : ""
                            color: Colours.palette.m3onSurface
                            font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                            font.weight: 600
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colours.tPalette.m3surfaceContainerLow
                            radius: Tokens.rounding ? Tokens.rounding.large : 8

                            ListView {
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.small
                                clip: true

                                model: root.calState.getEventsForDate ? root.calState.getEventsForDate(root.calState.currentDate) : 0

                                delegate: ItemDelegate {
                                    width: parent.width
                                    text: modelData.summary || modelData.title || qsTr("Event")
                                }

                                StyledText {
                                    text: qsTr("No events scheduled")
                                    color: Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                    anchors.centerIn: parent
                                    visible: parent.count === 0
                                }
                            }
                        }

                        Button {
                            id: addEventButton
                            text: qsTr("+ Add Event")
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing ? Tokens.spacing.small : 6

                            contentItem: StyledText {
                                text: addEventButton.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter

                                color: addEventButton.down ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                                font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                font.weight: 600
                            }

                            background: Rectangle {

                                color: addEventButton.down ? Colours.palette.m3primary : (addEventButton.hovered ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerLow)

                                radius: Tokens.rounding ? Tokens.rounding.large : 8

                                border.color: addEventButton.hovered ? Colours.palette.m3primary : Colours.tPalette.m3outlineVariant
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            onClicked: inspectorStack.currentIndex = 1
                        }
                    }

                    // VIEW 1: Creation Input
                    ColumnLayout {
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("New Event")
                            color: Colours.palette.m3onSurface
                            font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                            font.weight: 600
                        }

                        TextField {
                            id: eventTitleField
                            placeholderText: qsTr("Event Title")
                            Layout.fillWidth: true

                            // 1. Brighten and enlarge the user's active input text
                            color: Colours.palette.m3onSurface
                            font.pointSize: Tokens.fontSize ? Tokens.fontSize.small * 1.3 : 14
                            font.weight: 500

                            // 2. Add padding inside the text box so the cursor and characters aren't jammed against the border
                            leftPadding: 14
                            rightPadding: 14
                            topPadding: 10
                            bottomPadding: 10

                            // 3. Brighten and style the placeholder text for when the field is empty
                            placeholderTextColor: Colours.palette.m3onSurfaceVariant

                            background: Rectangle {
                                color: Colours.tPalette.m3surfaceContainerLow
                                radius: Tokens.rounding ? Tokens.rounding.large : 8

                                // Animates a sharp, clean accent border when you click into the box
                                border.color: eventTitleField.activeFocus ? Colours.palette.m3primary : Colours.tPalette.m3outlineVariant
                                border.width: eventTitleField.activeFocus ? 2 : 1

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing ? Tokens.spacing.small : 6

                            Button {
                                id: cancelEventButton
                                text: qsTr("Cancel")
                                Layout.fillWidth: true

                                contentItem: StyledText {
                                    text: cancelEventButton.text
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: cancelEventButton.down ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurfaceVariant
                                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                    font.weight: 600
                                }

                                background: Rectangle {
                                    color: cancelEventButton.down ? Colours.tPalette.m3surfaceContainerHigh : (cancelEventButton.hovered ? Colours.tPalette.m3surfaceContainerLow : "transparent")
                                    radius: Tokens.rounding ? Tokens.rounding.large : 8
                                    border.color: cancelEventButton.hovered ? Colours.palette.m3onSurfaceVariant : Colours.tPalette.m3outlineVariant
                                    border.width: 1

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                onClicked: {
                                    eventTitleField.text = "";
                                    inspectorStack.currentIndex = 0;
                                }
                            }

                            Button {
                                id: saveEventButton
                                text: qsTr("Save")
                                Layout.fillWidth: true
                                highlighted: true

                                contentItem: StyledText {
                                    text: saveEventButton.text
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: Colours.palette.m3onPrimary
                                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                    font.weight: 600
                                }

                                background: Rectangle {
                                    color: saveEventButton.down ? Colours.palette.m3primary : (saveEventButton.hovered ? Colours.palette.m3primary : Colours.palette.m3primary)
                                    opacity: saveEventButton.hovered ? 0.9 : 1.0
                                    radius: Tokens.rounding ? Tokens.rounding.large : 8

                                    border.color: saveEventButton.hovered ? Colours.palette.m3onPrimary : "transparent"
                                    border.width: 1

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                onClicked: {
                                    if (eventTitleField.text.trim() !== "" && root.calState.addEvent) {
                                        root.calState.addEvent(root.calState.currentDate, eventTitleField.text.trim());
                                    }
                                    eventTitleField.text = "";
                                    inspectorStack.currentIndex = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
