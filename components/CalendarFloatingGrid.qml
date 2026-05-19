pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property int currMonth
    required property int currYear
    required property CalendarState calState

    signal daySelected(date clickedDate)

    implicitWidth: 450
    implicitHeight: 450 // Bumped height slightly to accommodate the new week layout row elegantly

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing ? Tokens.spacing.small : 6

        // 1. DYNAMIC MONTH & YEAR HEADER BANNER
        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing ? Tokens.spacing.small : 4
            horizontalAlignment: Text.AlignHCenter

            text: new Date(root.currYear, root.currMonth, 1).toLocaleString(Qt.locale(), "MMMM yyyy")
            color: Colours.palette.m3onSurface
            font.pointSize: Tokens.fontSize ? Tokens.fontSize.small * 1.2 : 13
            font.weight: 600
        }

        // 2. Days of the week row
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: [qsTr("Sun"), qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"), qsTr("Fri"), qsTr("Sat")]

                delegate: StyledText {
                    required property string modelData
                    text: modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                    font.weight: 600
                }
            }
        }

        // 3. MAIN 6x7 DATE GRID MATRIX
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true

            cellWidth: width / 7
            cellHeight: height / 6
            interactive: false
            clip: true

            model: 42

            delegate: Item {
                required property int index

                width: grid.cellWidth
                height: grid.cellHeight

                readonly property date cellDate: getGridDate(index, root.currYear, root.currMonth)
                readonly property bool isCurrentMonth: cellDate.getMonth() === root.currMonth
                readonly property bool isToday: cellDate.toDateString() === new Date().toDateString()
                readonly property bool isSelected: cellDate.toDateString() === root.calState.currentDate.toDateString()

                readonly property int eventCount: {
                    try {
                        if (!GCalendar || !GCalendar.enabled || !GCalendar.events)
                            return 0;
                        return GCalendar.events.filter(ev => {
                            if (!ev)
                                return false;
                            let d = ev.isAllDay ? new Date(`${ev.start}T00:00:00`) : new Date(ev.startTime);
                            return d.toDateString() === cellDate.toDateString();
                        }).length;
                    } catch (e) {
                        return 0;
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Tokens.rounding ? Tokens.rounding.large : 8

                    color: !isCurrentMonth ? "transparent" : (isSelected ? Colours.palette.m3primary : (isToday ? Colours.palette.m3surfaceVariant : "transparent"))

                    border.color: isCurrentMonth && isToday && !isSelected ? Colours.palette.m3primary : "transparent"
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        StyledText {
                            text: isCurrentMonth ? cellDate.getDate() : ""
                            Layout.alignment: Qt.AlignHCenter
                            font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                            font.weight: isSelected || isToday ? 600 : 400
                            color: isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 3
                            visible: isCurrentMonth && eventCount > 0

                            Repeater {
                                model: Math.min(eventCount, 3)

                                delegate: Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3tertiary
                                }
                            }
                        }
                    }

                    CustomMouseArea {
                        anchors.fill: parent
                        enabled: isCurrentMonth
                        onClicked: {
                            root.calState.currentDate = cellDate;
                            root.daySelected(cellDate);
                        }
                    }
                }
            }
        }

        // 4. HORIZONTAL SEPARATOR
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colours.tPalette.m3outlineVariant
            Layout.topMargin: Tokens.spacing ? Tokens.spacing.small : 4
            Layout.bottomMargin: Tokens.spacing ? Tokens.spacing.small : 4
        }

        // 5. NEW: WEEKLY CALENDAR TIMELINE STRIP
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            StyledText {
                text: qsTr("Weekly Focus")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.fontSize ? Tokens.fontSize.small * 0.9 : 10
                font.weight: 600
                Layout.leftMargin: 6
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: 7 // Always exactly 7 days in the active row block

                    delegate: Item {
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48

                        // Calculate the absolute day date bounding across week start boundaries
                        readonly property date weekDate: getSelectedWeekDate(index, root.calState.currentDate)
                        readonly property bool isWeekToday: weekDate.toDateString() === new Date().toDateString()
                        readonly property bool isWeekSelected: weekDate.toDateString() === root.calState.currentDate.toDateString()

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Tokens.rounding ? Tokens.rounding.large : 8

                            // Highlighting matches system specs but keeps week view distinct
                            color: isWeekSelected ? Colours.palette.m3tertiary : (isWeekToday ? Colours.palette.m3surfaceVariant : Colours.tPalette.m3surfaceContainerLow)

                            border.color: isWeekToday && !isWeekSelected ? Colours.palette.m3tertiary : "transparent"
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                // Little day label abbreviation (e.g. "S", "M", "T")
                                StyledText {
                                    text: weekDate.toLocaleString(Qt.locale(), "ddd").substring(0, 1)
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small * 0.8 : 9
                                    color: isWeekSelected ? Colours.palette.m3onTertiary : Colours.palette.m3onSurfaceVariant
                                    opacity: 0.7
                                }

                                // Date Number string (Kept fully visible even if from overlapping month boundary)
                                StyledText {
                                    text: weekDate.getDate()
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                    font.weight: isWeekSelected || isWeekToday ? 600 : 400
                                    color: isWeekSelected ? Colours.palette.m3onTertiary : Colours.palette.m3onSurface
                                }
                            }

                            CustomMouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.calState.currentDate = weekDate;
                                    root.daySelected(weekDate);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Mathematical calculations mapping utility helpers
    function getGridDate(idx, year, month) {
        var firstDayOfMonth = new Date(year, month, 1);
        var startOffset = firstDayOfMonth.getDay();
        var resultDate = new Date(firstDayOfMonth);
        resultDate.setDate(firstDayOfMonth.getDate() - startOffset + idx);
        return resultDate;
    }

    // Calculates individual target elements bounding a specific week row context dynamically
    function getSelectedWeekDate(idx, baseDate) {
        var current = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
        var dayOfWeekOffset = current.getDay(); // Sunday = 0, Monday = 1, etc.

        var targetDay = new Date(current);
        targetDay.setDate(current.getDate() - dayOfWeekOffset + idx);
        return targetDay;
    }
}
