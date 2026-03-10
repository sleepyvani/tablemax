import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.ComboBox {
    id: root

    property string placeholder: "Select..."
    property bool searchable: false

    implicitWidth: 220
    implicitHeight: 32

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    opacity: enabled ? 1.0 : 0.5

    // ─── Trigger ───
    contentItem: RowLayout {
        spacing: 0

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            text: root.displayText || root.placeholder
            font: root.font
            color: root.displayText ? Theme.foreground : Theme.mutedForeground
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.rightMargin: 10
            text: "⌄"
            font.pixelSize: 14
            color: Theme.mutedForeground
            rotation: root.popup.visible ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutBack }
            }
        }
    }

    background: Rectangle {
        radius: Theme.radius
        color: {
            if (root.down) return Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.5)
            if (root.hovered) return Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.4)
            return Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.3)
        }
        border.width: 1
        border.color: root.popup.visible ? Theme.ring
                    : root.hovered ? Qt.lighter(Theme.input, 1.3)
                    : Theme.input

        Behavior on color { ColorAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }

    // ─── Dropdown Items ───
    delegate: T.ItemDelegate {
        id: delegateItem
        width: root.width - 8
        height: 32
        x: 4
        highlighted: root.highlightedIndex === index

        contentItem: RowLayout {
            spacing: 8

            // Selected checkmark
            Item {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.foreground
                    visible: root.currentIndex === index

                    scale: root.currentIndex === index ? 1.0 : 0.3
                    opacity: root.currentIndex === index ? 1.0 : 0.0

                    Behavior on scale {
                        NumberAnimation { duration: Theme.duration; easing.type: Easing.OutBack }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Theme.durationFast }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: modelData
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: delegateItem.highlighted ? Theme.foreground : Theme.mutedForeground
                elide: Text.ElideRight

                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }

        background: Rectangle {
            radius: Theme.radiusSm
            color: delegateItem.highlighted
                   ? Theme.accent
                   : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic }
            }
        }
    }

    // ─── Popup ───
    popup: T.Popup {
        id: selectPopup

        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 280)
        topPadding: 4
        bottomPadding: 4
        leftPadding: 0
        rightPadding: 0

        // Smooth open animation
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: Theme.durationSlow
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.92; to: 1.0
                    duration: Theme.durationSlow
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
                NumberAnimation {
                    property: "y"
                    from: root.height - 4
                    to: root.height + 4
                    duration: Theme.durationSlow
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Smooth close animation
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1; to: 0
                    duration: Theme.durationFast
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 1.0; to: 0.95
                    duration: Theme.durationFast
                    easing.type: Easing.InCubic
                }
            }
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: selectPopup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            // Smooth scrollbar
            T.ScrollBar.vertical: T.ScrollBar {
                policy: listView.contentHeight > selectPopup.height ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: Theme.border
                    opacity: parent.active ? 0.8 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.durationSlow } }
                }
                background: Item {}
            }

            // Smooth highlight follow
            highlight: Rectangle {
                color: "transparent"
            }

            // Stagger animation on items appearing
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                NumberAnimation { property: "x"; from: -8; to: 4; duration: 180; easing.type: Easing.OutCubic }
            }
        }

        background: Rectangle {
            color: Theme.popover
            border.width: 1
            border.color: Theme.border
            radius: Theme.radiusMd

            // Subtle shadow effect via layered darker rect
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                z: -1
                radius: Theme.radiusMd + 1
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.3)
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    Behavior on opacity { NumberAnimation { duration: Theme.duration } }
}
