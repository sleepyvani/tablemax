import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import "Icons.js" as Icons

T.ComboBox {
    id: root

    property string placeholder: "Select..."
    property bool searchable: false

    implicitWidth: 220
    implicitHeight: 32

    font.family: Theme.sans
    font.pixelSize: Theme.t13

    opacity: enabled ? 1.0 : 0.5

    // ─── Trigger ───
    contentItem: RowLayout {
        spacing: 0

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            text: root.displayText || root.placeholder
            font: root.font
            color: root.displayText ? Theme.fg : Theme.fgMuted
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        FlatIcon {
            Layout.rightMargin: 8
            icon: Icons.down
            size: 10
            color: Theme.fgMuted
            rotation: root.popup.visible ? 180 : 0
            Behavior on rotation {
                NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack }
            }
        }
    }

    background: Rectangle {
        radius: Theme.r6
        color: {
            if (root.down)    return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
            if (root.hovered) return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
            return Theme.bgSurface
        }
        border.width: 1
        border.color: root.popup.visible
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.7)
                    : root.hovered ? Theme.borderLight : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
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
            FlatIcon {
                icon: Icons.check
                size: 10
                color: Theme.accent
                visible: root.currentIndex === index
                scale:   root.currentIndex === index ? 1.0 : 0.3
                opacity: root.currentIndex === index ? 1.0 : 0.0
                Behavior on scale   { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            }
            Item { visible: root.currentIndex !== index; implicitWidth: 10 }

            Text {
                Layout.fillWidth: true
                text: modelData
                font.family: Theme.sans
                font.pixelSize: Theme.t12
                color: delegateItem.highlighted ? Theme.fg : Theme.fgMuted
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
        }

        background: Rectangle {
            radius: Theme.r4
            color: delegateItem.highlighted ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
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

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale";   from: 0.95; to: 1.0; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { property: "y";       from: root.height - 4; to: root.height + 4; duration: Theme.slow; easing.type: Easing.OutCubic }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale";   from: 1.0; to: 0.95; duration: Theme.fast; easing.type: Easing.InCubic }
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

            T.ScrollBar.vertical: T.ScrollBar {
                policy: listView.contentHeight > selectPopup.height ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    implicitWidth: 4; radius: 2
                    color: Theme.fgDim
                    opacity: parent.active ? 0.5 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.slow } }
                }
                background: Item {}
            }

            highlight: Rectangle { color: "transparent" }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                NumberAnimation { property: "x"; from: -8; to: 4; duration: 180; easing.type: Easing.OutCubic }
            }
        }

        background: Rectangle {
            color: Theme.bgSurface
            border.width: 1
            border.color: Theme.border
            radius: Theme.r8

            Rectangle {
                anchors.fill: parent; anchors.margins: -1; z: -1
                radius: Theme.r8 + 1; color: "transparent"
                border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
}
