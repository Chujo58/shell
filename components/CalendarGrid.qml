pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

ColumnLayout {
    id: root

    required property int currMonth
    required property int currYear

    spacing: Tokens.spacing.small

    signal monthPrevious()
    signal monthNext()
    signal todayClicked()

    RowLayout {
        id: monthNavigationRow

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: prevMonthText.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                id: prevMonthStateLayer

                radius: Tokens.rounding.full
                onClicked: root.monthPrevious()
            }

            MaterialIcon {
                id: prevMonthText

                anchors.centerIn: parent
                text: "chevron_left"
                color: Colours.palette.m3tertiary
                font.pointSize: Tokens.font.size.normal
                font.weight: 700
            }
        }

        Item {
            implicitWidth: implicitHeight
            implicitHeight: prevMonthText.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                id: todayDateStateLayer

                radius: Tokens.rounding.full
                onClicked: root.todayClicked()
            }

            MaterialIcon {
                id: todayDateText

                anchors.centerIn: parent
                text: "today"
                color: Colours.palette.m3tertiary
                font.pointSize: Tokens.font.size.normal
                font.weight: 700
            }
        }

        Item {
            Layout.fillWidth: true

            implicitWidth: monthYearDisplay.implicitWidth + Tokens.padding.small * 2
            implicitHeight: monthYearDisplay.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                onClicked: {
                    root.todayClicked();
                }

                anchors.fill: monthYearDisplay
                anchors.margins: -Tokens.padding.small
                anchors.leftMargin: -Tokens.padding.normal
                anchors.rightMargin: -Tokens.padding.normal

                radius: Tokens.rounding.full
                disabled: {
                    const now = new Date();
                    return root.currMonth === now.getMonth() && root.currYear === now.getFullYear();
                }
            }

            StyledText {
                id: monthYearDisplay

                anchors.centerIn: parent
                text: grid.title
                color: Colours.palette.m3primary
                font.pointSize: Tokens.font.size.normal
                font.weight: 500
                font.capitalization: Font.Capitalize
            }
        }

        Item {
            implicitWidth: implicitHeight
            implicitHeight: nextMonthText.implicitHeight + Tokens.padding.small * 2

            StateLayer {
                id: nextMonthStateLayer

                onClicked: {
                    root.monthNext();
                }

                radius: Tokens.rounding.full
            }

            MaterialIcon {
                id: nextMonthText

                anchors.centerIn: parent
                text: "chevron_right"
                color: Colours.palette.m3tertiary
                font.pointSize: Tokens.font.size.normal
                font.weight: 700
            }
        }
    }

    DayOfWeekRow {
        id: daysRow

        Layout.fillWidth: true
        locale: grid.locale

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font.weight: 500
            color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight

        MonthGrid {
            id: grid

            month: root.currMonth
            year: root.currYear

            anchors.fill: parent

            spacing: 3
            locale: Qt.locale()

            delegate: Item {
                id: dayItem

                required property var model
                readonly property bool hasEvent: GCalendar.hasEvent(model.date)

                implicitWidth: implicitHeight
                implicitHeight: text.implicitHeight + Tokens.padding.small * 2

                StyledText {
                    id: text

                    anchors.centerIn: parent

                    horizontalAlignment: Text.AlignHCenter
                    text: grid.locale.toString(dayItem.model.day)
                    color: {
                        const dayOfWeek = dayItem.model.date.getUTCDay();
                        if (dayOfWeek === 0 || dayOfWeek === 6)
                            return Colours.palette.m3secondary;

                        return Colours.palette.m3onSurfaceVariant;
                    }
                    opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 500
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 4
                    height: 4
                    radius: 2
                    color: Colours.palette.m3tertiary
                    visible: dayItem.hasEvent
                    opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                }
            }
        }

        StyledRect {
            id: todayIndicator

            readonly property Item todayItem: grid.contentItem.children.find(c => c.model.today) ?? null
            property Item today

            onTodayItemChanged: {
                if (todayItem)
                    today = todayItem;
            }

            x: today ? today.x + (today.width - implicitWidth) / 2 : 0
            y: today?.y ?? 0

            implicitWidth: today?.implicitWidth ?? 0
            implicitHeight: today?.implicitHeight ?? 0

            clip: true
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            opacity: todayItem ? 1 : 0
            scale: todayItem ? 1 : 0.7

            Colouriser {
                x: -todayIndicator.x
                y: -todayIndicator.y

                implicitWidth: grid.width
                implicitHeight: grid.height

                source: grid
                sourceColor: Colours.palette.m3onSurface
                colorizationColor: Colours.palette.m3onPrimary
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on x {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            Behavior on y {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }
}
