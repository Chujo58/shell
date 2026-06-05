pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    // Calendar stuff
    required property CalendarState calState

    readonly property int currMonth: calState.currentDate.getMonth()
    readonly property int currYear: calState.currentDate.getFullYear()

    // Upcoming events stuff
    readonly property int upcomingHours: GlobalConfig.services.calendar.agendaDays * 24
    readonly property int upcomingListMaxHeight: 180
    property list<string> hiddenCals: []
    readonly property list<var> upcomingEvents: GCalendar.events.filter(ev => {
            if (!ev)
                return false;

            const now = Date.now();

            if (ev.isAllDay) {
                const start = new Date(`${ev.start}T00:00:00`).getTime();
                return start >= now - 86400000;
            }

            return ev.startTime >= now;
        })//.slice(0, 5)

    readonly property var upcomingCalendars: {
        let s = [];
        let calList = [];
        for (const ev of upcomingEvents){
            for (const cal of GCalendar.calendars){
                if (ev.calendar == cal.summary & !s.includes(ev.calendar)){
                    s.push(ev.calendar);
                    calList.push(cal);
                }
            }
        }
        return calList;
    }
    
    readonly property var upcomingEventsPerDay: {
        let rootList = [];
        let eventList = [];
        let tempCurrentDate = upcomingEvents[0].dateKey; //y-m-d
        const now = Date.now();
        for (const ev of upcomingEvents) {
            const eventCurrentDate = ev.dateKey;
            eventList.push(ev);
            if (tempCurrentDate != eventCurrentDate) {
                rootList.push(eventList);
                eventList = [];
                tempCurrentDate = eventCurrentDate;
            } 
        }
        // console.log("rootList:",rootList);
        return rootList;
    }

    // Layout stuff
    Layout.row: 1
    Layout.columnSpan: 1
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    // The small grid calendar up top!
    CustomMouseArea{
        id: gridMouse
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + Tokens.padding.large * 2

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            CalendarGrid {
                Layout.fillWidth: true

                currMonth: root.currMonth
                currYear: root.currYear

                inDashboard: false
                onMonthPrevious: root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
                onMonthNext: root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
                onTodayClicked: root.calState.currentDate = new Date()
            }
        }

        acceptedButtons: Qt.MiddleButton
        onClicked: root.calState.currentDate = new Date()

        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
            else if (event.angleDelta.y < 0)
                root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
        }
    }

    // The calendar selection part
    StyledRect {
        // Layout.fillHeight: true
        Layout.fillWidth: true

        implicitHeight: calendarList.implicitHeight + Tokens.padding.large * 2

        color: Colours.palette.m3surfaceContainerLow
        radius: Tokens.rounding.large

        ColumnLayout {
            id: calendarList

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Calendars")
                color: Colours.palette.m3primary
                font.pointSize: Tokens.fontSize.small
                font.weight: 600
            }

            Repeater {
                model: root.upcomingCalendars

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledCheckBox {
                        checked: true
                        color: modelData.backgroundColor

                        onBoxToggled: (isChecked) => {
                            if (!isChecked) {
                                if (! hiddenCals.includes(modelData.summary)){
                                    hiddenCals.push(modelData.summary);
                                }
                            } else {
                                if (hiddenCals.includes(modelData.summary)){
                                    hiddenCals = Array.from(hiddenCals).filter(item => item !== modelData.summary);
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.summary
                        color: Colours.palette.m3onSurface
                        font.pointSize: Tokens.fontSize.small
                        // font.weight: 500
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // Upcoming events part
    StyledRect {
        clip: true
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: GCalendar.enabled && root.upcomingEvents.length > 0
        implicitHeight: upcomingContent.implicitHeight + Tokens.padding.large * 2

        color: Colours.palette.m3surfaceContainerLow
        radius: Tokens.rounding.large

        ColumnLayout {
            id: upcomingContent

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Upcoming")
                color: Colours.palette.m3primary
                font.pointSize: Tokens.fontSize.small
                font.weight: 600
            }

            StyledFlickable {
                id: upcomingFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: Math.min(upcomingList.implicitHeight, root.upcomingListMaxHeight)
                contentHeight: upcomingList.implicitHeight
                clip: true

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: upcomingFlickable
                }

                ColumnLayout {
                    id: upcomingList

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.upcomingEventsPerDay

                        ColumnLayout {
                            required property var modelData
                            StyledText {
                                text: Qt.formatDateTime(modelData[0].dateKey, "ddd, MMM d")
                                // font.bold: true
                                color: Colours.palette.m3tertiary
                            }
                            Repeater {
                                model: modelData

                                RowLayout {
                                    id: eventRow

                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small
                                    visible: !hiddenCals.includes(modelData.calendar)

                                    Rectangle {
                                        Layout.preferredWidth: 3
                                        Layout.fillHeight: true
                                        radius: 1.5
                                        color: GCalendar.colorMap[eventRow.modelData.calendar]
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
        }
    }
}