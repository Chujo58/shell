pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import qs.components
import qs.services

Singleton {
    id: root

    readonly property CalendarState calState: CalendarState {
        reloadableId: "calendarState"
    }

    function create(parent: Item, props: var): void {
        calendarApp.createObject(parent ?? dummy, props)   
    }

    QtObject {
        id: dummy
    }

    Component {
        id: calendarApp

        FloatingWindow {
            id: win
            // property alias active: cc.active

            color: Colours.tPalette.m3surface

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: cc.implicitWidth
            implicitHeight: cc.implicitHeight

            minimumSize.width: implicitWidth
            minimumSize.height: implicitHeight
            maximumSize.width: implicitWidth
            maximumSize.height: implicitHeight

            title: qsTr("Calendar")

            Calendar {
                id: cc

                anchors.fill: parent
                screen: win.screen
                calState: root.calState
                onClose: win.destroy()
                floating: true
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}