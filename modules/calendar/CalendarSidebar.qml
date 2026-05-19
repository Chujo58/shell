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
    readonly property int upcomingHours: GlobalConfig.services && GlobalConfig.services.calendar ? GlobalConfig.services.calendar.agendaDays * 24 : 48
    readonly property list<var> upcomingEvents: GCalendar && GCalendar.enabled && GCalendar.events ? GCalendar.events.filter(ev => {
        if (!ev)
            return false;
        const now = Date.now();
        if (ev.isAllDay) {
            const start = new Date(`${ev.start}T00:00:00`).getTime();
            return start >= now - 86400000;
        }
        return ev.startTime >= now;
    }).slice(0, 3) : [] // Kept to a max of 3 to leave plenty of canvas breathing room [cite: 12]

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
        anchors.margins: Tokens.padding ? Tokens.padding.large : 12
        spacing: Tokens.spacing ? Tokens.spacing.large : 12

        // SECTION 1: Mini Navigation Calendar Grid moved to the very top
        CalendarGrid {
            id: navMiniGrid
            Layout.fillWidth: true

            currMonth: root.currMonth
            currYear: root.currYear
            inDashboard: false

            onMonthPrevious: root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
            onMonthNext: root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
            onTodayClicked: root.calState.currentDate = new Date()
        }

        // SECTION 2: THE ANALOG CLOCK
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing ? Tokens.spacing.small : 6

            Item {
                id: clockContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 130
                Layout.preferredHeight: 130

                property date timeTime: new Date()

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockContainer.timeTime = new Date()
                }

                // Outer Clock Dial Face Circle Base
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Colours.tPalette.m3surfaceContainerLow || "#11111b"
                    border.color: Colours.tPalette.m3error || "#313244"
                    border.width: 2.5

                    // Hour Hand
                    Rectangle {
                        id: hourHand
                        x: 64
                        y: 30
                        width: 3
                        height: 35
                        color: Colours.palette.m3primary
                        radius: 1.5
                        transformOrigin: Item.Bottom
                        rotation: (clockContainer.timeTime.getHours() % 12) * 30 + clockContainer.timeTime.getMinutes() * 0.5
                    }

                    // Minute Hand
                    Rectangle {
                        id: minuteHand
                        x: 64.5
                        y: 15
                        width: 2
                        height: 50
                        color: Colours.palette.m3onSurface
                        radius: 1
                        transformOrigin: Item.Bottom
                        rotation: clockContainer.timeTime.getMinutes() * 6
                    }

                    // Second Hand
                    Rectangle {
                        id: secondHand
                        x: 65
                        y: 10
                        width: 1
                        height: 55
                        color: Colours.palette.m3error
                        transformOrigin: Item.Bottom
                        rotation: clockContainer.timeTime.getSeconds() * 6
                    }

                    // Center Pin Cap Dot
                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: Colours.palette.m3tertiary
                    }
                }
            }

            StyledText {
                id: digitalReadout
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter

                color: Colours.palette.m3onSurface
                font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                font.weight: 500

                // Formats into: "HH:mm:ss · yyyy-MM-dd · TZ" (e.g., 13:14:22 · 2026-05-19 · PDT)
                text: {
                    let d = clockContainer.timeTime;

                    // 24-Hour Time formatting
                    let hours = String(d.getHours()).padStart(2, '0');
                    let minutes = String(d.getMinutes()).padStart(2, '0');
                    let seconds = String(d.getSeconds()).padStart(2, '0');
                    let timeString = `${hours}:${minutes}:${seconds}`;

                    // Date formatting (YYYY-MM-DD)
                    let year = d.getFullYear();
                    let month = String(d.getMonth() + 1).padStart(2, '0');
                    let day = String(d.getDate()).padStart(2, '0');
                    let dateString = `${year}-${month}-${day}`;

                    let tzString = "Local";
                    try {
                        let formatter = new Intl.DateTimeFormat(undefined, {
                            timeZoneName: 'short'
                        });
                        let parts = formatter.formatToParts(d);
                        let tzPart = parts.find(part => part.type === 'timeZoneName');

                        if (tzPart && tzPart.value) {
                            if (/GMT|UTC|[+-]/i.test(tzPart.value)) {
                                let tzMatch = d.toString().match(/\(([^)]+)\)/);
                                if (tzMatch && tzMatch[1]) {
                                    tzString = tzMatch[1].split(' ').map(word => word[0]).join('').toUpperCase();
                                } else {
                                    tzString = tzPart.value;
                                }
                            } else {
                                tzString = tzPart.value;
                            }
                        }
                    } catch (e) {
                        tzString = "Local";
                    }

                    if (!tzString || tzString.trim() === "") {
                        tzString = "Local";
                    }

                    return `${timeString}  ·  ${dateString}  ·  ${tzString}`;
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true // Let this expand to use any remaining lower layout space
            visible: GCalendar && GCalendar.enabled && root.upcomingEvents.length > 0
            implicitHeight: eventsCol.implicitHeight + (Tokens.padding ? Tokens.padding.large * 2 : 16)

            color: Colours.tPalette.m3surfaceContainerLow
            radius: Tokens.rounding ? Tokens.rounding.large : 8

            ColumnLayout {
                id: eventsCol
                anchors.fill: parent
                anchors.margins: Tokens.padding ? Tokens.padding.large : 12
                spacing: Tokens.spacing ? Tokens.spacing.small : 6

                StyledText {
                    text: qsTr("Upcoming")
                    color: Colours.palette.m3primary
                    font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                    font.weight: 600
                }

                Repeater {
                    model: root.upcomingEvents

                    delegate: RowLayout {
                        id: eventRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Tokens.spacing ? Tokens.spacing.small : 6

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
                                font.pointSize: Tokens.fontSize ? Tokens.fontSize.small : 11
                                font.weight: 500
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (!GCalendar || !GCalendar.formatEventTime)
                                        return "";
                                    let line = GCalendar.formatEventTime(eventRow.modelData, root.upcomingHours);
                                    if (eventRow.modelData.location)
                                        line += ` · ${eventRow.modelData.location}`;
                                    return line;
                                }
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Tokens.fontSize ? Tokens.fontSize.small * 0.9 : 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
// CustomMouseArea {
//     id: root

//     required property CalendarState calState

//     readonly property int currMonth: calState.currentDate.getMonth()
//     readonly property int currYear: calState.currentDate.getFullYear()
//     readonly property int upcomingHours: GlobalConfig.services.calendar.agendaDays * 24
//     readonly property list<var> upcomingEvents: GCalendar.events.filter(ev => {
//             if (!ev)
//                 return false;

//             const now = Date.now();

//             if (ev.isAllDay) {
//                 const start = new Date(`${ev.start}T00:00:00`).getTime();
//                 return start >= now - 86400000;
//             }

//             return ev.startTime >= now;
//         }).slice(0, 5)

//     Layout.row: 1
//     Layout.columnSpan: 1
//     Layout.fillWidth: true
//     Layout.fillHeight: true

//     anchors.left: parent.left
//     anchors.right: parent.right
//     implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

//     acceptedButtons: Qt.MiddleButton
//     onClicked: root.calState.currentDate = new Date()

//     function onWheel(event: WheelEvent): void {
//         if (event.angleDelta.y > 0)
//             root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
//         else if (event.angleDelta.y < 0)
//             root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
//     }

//     ColumnLayout {
//         id: inner

//         anchors.fill: parent
//         anchors.margins: Tokens.padding.large
//         spacing: Tokens.spacing.small

//         CalendarGrid {
//             Layout.fillWidth: true

//             currMonth: root.currMonth
//             currYear: root.currYear
//             inDashboard: false

//             onMonthPrevious: root.calState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
//             onMonthNext: root.calState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
//             onTodayClicked: root.calState.currentDate = new Date()
//         }

//         StyledRect {
//             Layout.fillWidth: true
//             visible: GCalendar.enabled && root.upcomingEvents.length > 0
//             implicitHeight: eventsCol.implicitHeight + Tokens.padding.large * 2

//             color: Colours.tPalette.m3surfaceContainerLow
//             radius: Tokens.rounding.large

//             ColumnLayout {
//                 id: eventsCol

//                 anchors.fill: parent
//                 anchors.margins: Tokens.padding.large
//                 spacing: Tokens.spacing.small

//                 StyledText {
//                     text: qsTr("Upcoming")
//                     color: Colours.palette.m3primary
//                     font.pointSize: Tokens.fontSize.small
//                     font.weight: 600
//                 }

//                 Repeater {
//                     model: root.upcomingEvents

//                     RowLayout {
//                         id: eventRow

//                         required property var modelData

//                         Layout.fillWidth: true
//                         spacing: Tokens.spacing.small

//                         Rectangle {
//                             Layout.preferredWidth: 3
//                             Layout.fillHeight: true
//                             radius: 1.5
//                             color: Colours.palette.m3tertiary
//                         }

//                         ColumnLayout {
//                             Layout.fillWidth: true
//                             spacing: 0

//                             StyledText {
//                                 Layout.fillWidth: true
//                                 text: eventRow.modelData.summary
//                                 color: Colours.palette.m3onSurface
//                                 font.pointSize: Tokens.fontSize.small
//                                 font.weight: 500
//                                 elide: Text.ElideRight
//                             }

//                             StyledText {
//                                 Layout.fillWidth: true
//                                 text: {
//                                     let line = GCalendar.formatEventTime(eventRow.modelData, root.upcomingHours);
//                                     if (eventRow.modelData.location)
//                                         line += ` · ${eventRow.modelData.location}`;
//                                     return line;
//                                 }
//                                 color: Colours.palette.m3onSurfaceVariant
//                                 font.pointSize: Tokens.fontSize.small * 0.9
//                                 elide: Text.ElideRight
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
