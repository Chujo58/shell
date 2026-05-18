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

Item {
    id: root

    required property ShellScreen screen
    readonly property Session session: Session {
        id: session

        root: root
    }

    readonly property int rounding: floating ? 0 : Tokens.rounding.large

    property alias floating: session.floating

    signal close

    implicitWidth: implicitHeight * Tokens.sizes.controlCenter.ratio
    implicitHeight: screen.height * Tokens.sizes.controlCenter.heightMult

    // Stuff for the calendar:
    required property CalendarState calState

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

        CalendarSidebar {
            calState: root.calState
        }
        
        
        StyledRect {
            Layout.fillHeight: true
            topLeftRadius: root.rounding
            bottomLeftRadius: root.rounding
            // implicitWidth: navRail.implicitWidth
            color: Colours.tPalette.m3surfaceContainer
        }
    }
}