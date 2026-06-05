import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

CheckBox {
    id: control

    required property color color

    property color uncheckedBorderColor: color
    property color checkedBorderColor: color
    property color hoveredBorderColor: "#2196F3" //random for now
    property color disabledBorderColor: "#BDBDBD"
    property int borderWidth: 2

    // 1. Configure the core Material parameters
    Material.accent: color // Default primary theme color

    // Signal stuff
    signal boxToggled(bool isChecked)

    onCheckedChanged: {
        // Broadcasts the checked state (true/false) to your other files
        boxToggled(checked) 
    }

    // 2. Add the custom border overlay layer directly to the native indicator
    Rectangle {
        parent: control.indicator
        anchors.fill: parent
        radius: 2 
        color: "transparent" // Let the native Material fill/checkmark show through
        border.width: control.borderWidth
        
        // Dynamic border color state engine
        border.color: {
            if (!control.enabled) return control.disabledBorderColor
            if (control.pressed) return control.checkedBorderColor
            if (control.hovered) return control.hoveredBorderColor
            if (control.checked) return control.checkedBorderColor
            return control.uncheckedBorderColor
        }
    }
}