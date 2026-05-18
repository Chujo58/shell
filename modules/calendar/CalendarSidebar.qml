pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

CustomMouseArea {
    id: root

    required property CalendarState calState

    readonly property int currMonth: calState.currentDate.getMonth()
    readonly property int currYear: calState.currentDate.getFullYear()
    readonly property int upcomingHours: GlobalConfig.services.calendar.agendaDays * 24
    readonly property list<var> upcomingEvents: GCalendar.events.filter(ev => {
            if (!ev)
                return false;

            const now = Date.now();

            if (ev.isAllDay) {
                const start = new Date(`${ev.start}T00:00:00`).getTime();
                return start >= now - 86400000;
            }

            return ev.startTime >= now;
        }).slice(0, 5)

    Layout.row: 1
    Layout.columnSpan: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.calState.currentDate = new Date()

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
    }

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        CalendarGrid {
            Layout.fillWidth: true

            currMonth: root.currMonth
            currYear: root.currYear

            onMonthPrevious: root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
            onMonthNext: root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
            onTodayClicked: root.calState.currentDate = new Date()
        }

        StyledRect {
            Layout.fillWidth: true
            visible: GCalendar.enabled && root.upcomingEvents.length > 0
            implicitHeight: eventsCol.implicitHeight + Tokens.padding.large * 2

            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding.large

            ColumnLayout {
                id: eventsCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                StyledText {
                    text: qsTr("Upcoming")
                    color: Colours.palette.m3primary
                    font.pointSize: Tokens.fontSize.small
                    font.weight: 600
                }

                Repeater {
                    model: root.upcomingEvents

                    RowLayout {
                        id: eventRow

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.fillHeight: true
                            radius: 1.5
                            color: Colours.palette.m3tertiary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: eventRow.modelData.summary
                                color: Colours.palette.m3onSurface
                                font.pointSize: Tokens.fontSize.small
                                font.weight: 500
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    let line = GCalendar.formatEventTime(eventRow.modelData, root.upcomingHours);
                                    if (eventRow.modelData.location)
                                        line += ` · ${eventRow.modelData.location}`;
                                    return line;
                                }
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Tokens.fontSize.small * 0.9
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}