pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

CustomMouseArea {
    id: root

    required property DashboardState dashState

    readonly property int currMonth: dashState.currentDate.getMonth()
    readonly property int currYear: dashState.currentDate.getFullYear()

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y > 0)
            root.dashState.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
        else if (event.angleDelta.y < 0)
            root.dashState.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    acceptedButtons: Qt.MiddleButton
    onClicked: root.dashState.currentDate = new Date()

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        CalendarGrid {
            Layout.fillWidth: true

            currMonth: root.currMonth
            currYear: root.currYear
            inDashboard: true

            onMonthPrevious: root.dashState.currentDate = new Date(root.currYear, root.currMonth - 1, 1)
            onMonthNext: root.dashState.currentDate = new Date(root.currYear, root.currMonth + 1, 1)
            onTodayClicked: root.dashState.currentDate = new Date()
        }
    }
}
