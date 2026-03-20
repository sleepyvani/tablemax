// RedisKeyBrowser.qml — Redis key-value browser with type-specific editors
// Inspired by RedisInsight — click any key to open an inline value editor

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    property var resultModel: null
    property int totalRows: resultModel ? resultModel.totalRows : 0
    property int totalColumns: resultModel ? resultModel.totalColumns : 0
    property string searchQuery: ""
    property int selectedKeyIdx: -1

    // Filter keys by search query
    function keyMatchesSearch(row) {
        if (!searchQuery) return true
        return getKeyName(row).toLowerCase().indexOf(searchQuery.toLowerCase()) >= 0
    }

    signal toast(string message, string type)

    TextEdit { id: _clip; visible: false }

    // ── Main split layout ──────────────────────────────────────
    RowLayout {
        anchors.fill: parent; spacing: 0

        // ── LEFT: Key List ─────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: selectedKeyIdx >= 0 ? 280 : parent.width
            Layout.fillHeight: true
            spacing: 0
            clip: true

            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

            // Toolbar
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40; color: Theme.bgElevated
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s6

                    FlatIcon { icon: Icons.key; size: 14; color: Theme.error }

                    FlatInput {
                        id: searchInput
                        Layout.fillWidth: true; Layout.preferredHeight: 26
                        placeholderText: "Search keys…"
                        onTextChanged: root.searchQuery = text
                    }

                    Text {
                        text: {
                            var vis = 0
                            for (var i = 0; i < totalRows; i++) if (keyMatchesSearch(i)) vis++
                            return searchQuery ? vis + "/" + totalRows : totalRows + " keys"
                        }
                        font.pixelSize: Theme.t11; color: Theme.fgDim; font.family: Theme.sans
                    }

                    Rectangle {
                        width: 22; height: 22; radius: Theme.r4; color: clsMa.containsMouse ? Theme.bgHover : "transparent"
                        visible: root.searchQuery !== ""
                        FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 10; color: Theme.fgMuted }
                        MouseArea { id: clsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: searchInput.text = "" }
                    }
                }
                DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            }

            // Key List
            ListView {
                id: keyListView
                Layout.fillWidth: true; Layout.fillHeight: true
                model: totalRows; clip: true; spacing: 0
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 3; radius: 2; color: Theme.borderLight; opacity: 0.5 }
                }

                delegate: Rectangle {
                    id: keyDelegate
                    required property int index
                    property int keyIdx: index
                    property bool matchesSearch: root.keyMatchesSearch(keyIdx)
                    property bool selected: root.selectedKeyIdx === keyIdx

                    width: keyListView.width; height: matchesSearch ? 44 : 0
                    visible: matchesSearch
                    color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                                   : keyMa.containsMouse ? Theme.bgHover
                                   : keyIdx % 2 === 0 ? "transparent"
                                   : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    // Selected left bar
                    Rectangle {
                        width: 3; height: parent.height; color: Theme.accent
                        visible: keyDelegate.selected; anchors.left: parent.left
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: selected ? Theme.s12 + 3 : Theme.s12
                        anchors.rightMargin: Theme.s8
                        spacing: Theme.s8

                        // Type icon badge
                        Rectangle {
                            width: 26; height: 26; radius: Theme.r6
                            color: getTypeColor(getRedisType(keyDelegate.keyIdx), 0.12)
                            FlatIcon {
                                anchors.centerIn: parent
                                icon: getTypeIcon(getRedisType(keyDelegate.keyIdx))
                                size: 12; color: getTypeColor(getRedisType(keyDelegate.keyIdx), 1)
                            }
                        }

                        // Key name + preview
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text {
                                text: getKeyName(keyDelegate.keyIdx)
                                font.pixelSize: Theme.t12; font.family: Theme.mono
                                color: keyDelegate.selected ? Theme.fg : Theme.fg
                                elide: Text.ElideMiddle; Layout.fillWidth: true
                            }
                            Text {
                                text: getKeyPreview(keyDelegate.keyIdx)
                                font.pixelSize: Theme.t11; font.family: Theme.mono
                                color: Theme.fgMuted; elide: Text.ElideRight; Layout.fillWidth: true
                                visible: text !== ""
                            }
                        }

                        // Type badge
                        Rectangle {
                            width: typeLbl.implicitWidth + Theme.s8; height: 16; radius: Theme.rFull
                            color: getTypeColor(getRedisType(keyDelegate.keyIdx), 0.1)
                            Text {
                                id: typeLbl; anchors.centerIn: parent
                                text: getRedisType(keyDelegate.keyIdx).toUpperCase()
                                font.pixelSize: 9; font.weight: Font.Bold
                                font.family: Theme.sans; color: getTypeColor(getRedisType(keyDelegate.keyIdx), 1)
                            }
                        }

                        // TTL badge
                        Rectangle {
                            visible: getTTL(keyDelegate.keyIdx) !== ""
                            width: ttlLbl.implicitWidth + Theme.s6; height: 16; radius: Theme.rFull
                            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                            RowLayout {
                                anchors.centerIn: parent; spacing: 2
                                FlatIcon { icon: Icons.clock; size: 8; color: Theme.fgMuted }
                                Text { id: ttlLbl; text: getTTL(keyDelegate.keyIdx); font.pixelSize: 9; color: Theme.fgMuted; font.family: Theme.sans }
                            }
                        }
                    }

                    MouseArea {
                        id: keyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedKeyIdx = root.selectedKeyIdx === keyDelegate.keyIdx ? -1 : keyDelegate.keyIdx
                    }

                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.25 }
                }
            }

            // Empty state
            FlatEmpty {
                Layout.alignment: Qt.AlignHCenter; visible: totalRows === 0
                icon: Icons.key; title: "No keys"; description: "Run a Redis command to see results"
            }
        }

        // Vertical divider
        DashedLine {
            Layout.fillHeight: true; Layout.preferredWidth: 1
            color: Theme.border; visible: selectedKeyIdx >= 0
        }

        // ── RIGHT: Value Editor ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: Theme.bg
            visible: selectedKeyIdx >= 0
            clip: true

            property string _type: selectedKeyIdx >= 0 ? getRedisType(selectedKeyIdx) : ""
            property string _keyName: selectedKeyIdx >= 0 ? getKeyName(selectedKeyIdx) : ""
            property string _rawValue: selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // Value Editor Header
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 44; color: Theme.bgElevated

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                        // Type icon
                        Rectangle {
                            width: 28; height: 28; radius: Theme.r6
                            color: getTypeColor(parent.parent.parent._type, 0.12)
                            FlatIcon {
                                anchors.centerIn: parent
                                icon: getTypeIcon(parent.parent.parent._type)
                                size: 14; color: getTypeColor(parent.parent.parent._type, 1)
                            }
                        }

                        // Key name
                        Text {
                            text: parent.parent._type || ""
                            font.pixelSize: Theme.t11; font.family: Theme.mono
                            font.weight: Font.Bold
                            color: getTypeColor(parent.parent._type, 1)
                            Layout.preferredWidth: implicitWidth
                        }

                        Text {
                            text: selectedKeyIdx >= 0 ? getKeyName(selectedKeyIdx) : ""
                            font.pixelSize: Theme.t12; font.family: Theme.mono
                            color: Theme.fg; elide: Text.ElideMiddle; Layout.fillWidth: true
                        }

                        // TTL info
                        Rectangle {
                            visible: selectedKeyIdx >= 0 && getTTL(selectedKeyIdx) !== ""
                            width: ttlDetailLbl.implicitWidth + Theme.s12; height: 22; radius: Theme.r4
                            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
                            border.width: 1; border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.2)
                            RowLayout { anchors.centerIn: parent; spacing: Theme.s4
                                FlatIcon { icon: Icons.clock; size: 10; color: Theme.warning }
                                Text { id: ttlDetailLbl; text: "TTL: " + (selectedKeyIdx >= 0 ? getTTL(selectedKeyIdx) : ""); font.pixelSize: Theme.t11; color: Theme.warning; font.family: Theme.sans }
                            }
                        }

                        // Copy key name
                        Rectangle {
                            width: 26; height: 26; radius: Theme.r4
                            color: copyKeyNameMa.containsMouse ? Theme.bgHover : "transparent"
                            FlatTooltip { visible: copyKeyNameMa.containsMouse; text: "Copy key name"; y: 30 }
                            FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 11; color: Theme.fgMuted }
                            MouseArea { id: copyKeyNameMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { _clip.text = selectedKeyIdx >= 0 ? getKeyName(selectedKeyIdx) : ""; _clip.selectAll(); _clip.copy(); root.toast("Key name copied", "success") }
                            }
                        }

                        // Delete key button
                        Rectangle {
                            width: 26; height: 26; radius: Theme.r4
                            color: delKeyMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) : "transparent"
                            FlatTooltip { visible: delKeyMa.containsMouse; text: "Delete key (DEL)"; y: 30 }
                            FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 11; color: delKeyMa.containsMouse ? Theme.error : Theme.fgMuted }
                            MouseArea { id: delKeyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var key = selectedKeyIdx >= 0 ? getKeyName(selectedKeyIdx) : ""
                                    if (key && databaseService) {
                                        databaseService.executeQuery("DEL " + key, resultModel)
                                        root.toast("Key deleted: " + key, "destructive")
                                        root.selectedKeyIdx = -1
                                    }
                                }
                            }
                        }

                        // Close panel
                        Rectangle {
                            width: 26; height: 26; radius: Theme.r4; color: closePanelMa.containsMouse ? Theme.bgHover : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 11; color: Theme.fgMuted }
                            MouseArea { id: closePanelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedKeyIdx = -1 }
                        }
                    }

                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                }

                // ── String Editor ──────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "string"
                    spacing: 0

                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentWidth: width; contentHeight: stringEdit.implicitHeight + Theme.s24
                        clip: true; boundsBehavior: Flickable.StopAtBounds

                        TextEdit {
                            id: stringEdit
                            width: parent.width
                            topPadding: Theme.s12; leftPadding: Theme.s16; rightPadding: Theme.s16; bottomPadding: Theme.s12
                            font.family: Theme.mono; font.pixelSize: Theme.t13; color: Theme.fg
                            selectionColor: Theme.accentDim; selectedTextColor: Theme.fg
                            wrapMode: TextEdit.Wrap; selectByMouse: true; textFormat: TextEdit.PlainText
                            text: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "string" ? getKeyValue(selectedKeyIdx) : ""
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }
                    }

                    // String action bar
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 44; color: Theme.bgElevated
                        DashedLine { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                            Text {
                                text: stringEdit.text.length + " chars"
                                font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim
                            }

                            Item { Layout.fillWidth: true }

                            FlatButton {
                                text: "Copy Value"; variant: "ghost"; size: "sm"
                                onClicked: { _clip.text = stringEdit.text; _clip.selectAll(); _clip.copy(); root.toast("Value copied", "success") }
                            }
                            FlatButton {
                                text: "Save"
                                size: "sm"
                                onClicked: {
                                    var key = selectedKeyIdx >= 0 ? getKeyName(selectedKeyIdx) : ""
                                    if (key && databaseService) {
                                        databaseService.executeQuery("SET " + key + " \'" + stringEdit.text.replace(/'/g, "\\'") + "\'", resultModel)
                                        root.toast("Saved: " + key, "success")
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Hash Editor ────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "hash"
                    spacing: 0

                    // Hash header
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                        RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                            Text { text: "FIELD"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 150 }
                            Text { text: "VALUE"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.fillWidth: true }
                        }
                        DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
                    }

                    // Hash fields list (parse from JSON-like value)
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        model: {
                            var raw = selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""
                            return parseHashEntries(raw)
                        }

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width; height: 34
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s6

                                Text { text: modelData.field || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.accent; Layout.preferredWidth: 150; elide: Text.ElideRight }
                                Text { text: modelData.value || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; elide: Text.ElideRight }

                                Rectangle {
                                    width: 22; height: 22; radius: Theme.r4; color: hCopyMa.containsMouse ? Theme.bgHover : "transparent"
                                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 10; color: Theme.fgMuted }
                                    MouseArea { id: hCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { _clip.text = modelData.field + "\t" + modelData.value; _clip.selectAll(); _clip.copy(); root.toast("Copied", "success") }
                                    }
                                }
                            }
                            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.25 }
                        }
                    }
                }

                // ── List Editor ────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "list"
                    spacing: 0

                    // List header
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                        RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                            Text { text: "INDEX"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 60 }
                            Text { text: "VALUE"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.fillWidth: true }
                        }
                        DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
                    }

                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        model: {
                            var raw = selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""
                            return parseListEntries(raw)
                        }

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view.width; height: 34
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s8

                                Text { text: modelData.idx !== undefined ? modelData.idx : index; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 60 }
                                Text { text: modelData.value || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; elide: Text.ElideRight }

                                Rectangle {
                                    width: 22; height: 22; radius: Theme.r4; color: lCopyMa.containsMouse ? Theme.bgHover : "transparent"
                                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 10; color: Theme.fgMuted }
                                    MouseArea { id: lCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { _clip.text = modelData.value || ""; _clip.selectAll(); _clip.copy(); root.toast("Copied", "success") }
                                    }
                                }
                            }
                            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.25 }
                        }
                    }
                }

                // ── Set Editor ─────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "set"
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                        RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                            Text { text: "MEMBER"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.fillWidth: true }
                        }
                        DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
                    }

                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: {
                            var raw = selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""
                            return parseListEntries(raw)
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: ListView.view.width; height: 34
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s8
                                FlatIcon { icon: Icons.dot; size: 6; color: Theme.fgDim }
                                Text { text: modelData.value || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; elide: Text.ElideRight }
                                Rectangle {
                                    width: 22; height: 22; radius: Theme.r4; color: sCopyMa.containsMouse ? Theme.bgHover : "transparent"
                                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 10; color: Theme.fgMuted }
                                    MouseArea { id: sCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { _clip.text = modelData.value || ""; _clip.selectAll(); _clip.copy(); root.toast("Copied", "success") }
                                    }
                                }
                            }
                            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.25 }
                        }
                    }
                }

                // ── ZSet Editor ────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && getRedisType(selectedKeyIdx) === "zset"
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                        RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                            Text { text: "RANK"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 48 }
                            Text { text: "SCORE"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 80 }
                            Text { text: "MEMBER"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.fgDim; Layout.fillWidth: true }
                        }
                        DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
                    }

                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: {
                            var raw = selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""
                            return parseZSetEntries(raw)
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }
                        delegate: Rectangle {
                            required property var modelData; required property int index
                            width: ListView.view.width; height: 34
                            color: index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s8
                                Text { text: (index + 1).toString(); font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 48 }
                                Text { text: modelData.score !== undefined ? modelData.score : ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.info; Layout.preferredWidth: 80 }
                                Text { text: modelData.member || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; elide: Text.ElideRight }
                                Rectangle {
                                    width: 22; height: 22; radius: Theme.r4; color: zCopyMa.containsMouse ? Theme.bgHover : "transparent"
                                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 10; color: Theme.fgMuted }
                                    MouseArea { id: zCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { _clip.text = modelData.member || ""; _clip.selectAll(); _clip.copy(); root.toast("Copied", "success") }
                                    }
                                }
                            }
                            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.25 }
                        }
                    }
                }

                // ── Stream / Unknown fallback ───────────────────────
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: selectedKeyIdx >= 0 && !["string","hash","list","set","zset"].includes(getRedisType(selectedKeyIdx))

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s8
                        FlatIcon { Layout.alignment: Qt.AlignHCenter; icon: Icons.lightning; size: 32; color: Theme.fgMuted; opacity: 0.5 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: (selectedKeyIdx >= 0 ? getRedisType(selectedKeyIdx).toUpperCase() : "") + " type"
                            font.family: Theme.sans; font.pixelSize: Theme.t14; font.weight: Font.DemiBold; color: Theme.fg
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: selectedKeyIdx >= 0 ? getKeyPreview(selectedKeyIdx) : ""
                            font.family: Theme.mono; font.pixelSize: Theme.t12; color: Theme.fgMuted
                            wrapMode: Text.Wrap; Layout.maximumWidth: 280
                        }
                        FlatButton {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Copy Raw Value"; variant: "outline"; size: "sm"
                            onClicked: { _clip.text = selectedKeyIdx >= 0 ? getKeyValue(selectedKeyIdx) : ""; _clip.selectAll(); _clip.copy(); root.toast("Copied", "success") }
                        }
                    }
                }
            }
        }
    }

    // ── Helper Functions ──────────────────────────────────────
    function getKeyName(row) {
        if (!resultModel || totalColumns < 1) return ""
        return String(resultModel.data(resultModel.index(row, 0), 0) || "")
    }

    function getKeyValue(row) {
        if (!resultModel || totalColumns < 2) return ""
        return String(resultModel.data(resultModel.index(row, 1), 0) || "")
    }

    function getRedisType(row) {
        if (!resultModel || totalColumns < 3) return "string"
        var t = String(resultModel.data(resultModel.index(row, 2), 0) || "string")
        return t.toLowerCase()
    }

    function getTTL(row) {
        if (!resultModel || totalColumns < 4) return ""
        var ttl = resultModel.data(resultModel.index(row, 3), 0)
        if (ttl === undefined || ttl === null || ttl === "-1" || ttl === -1) return ""
        var n = parseInt(ttl)
        if (isNaN(n) || n < 0) return ""
        if (n < 60) return n + "s"
        if (n < 3600) return Math.floor(n / 60) + "m"
        if (n < 86400) return Math.floor(n / 3600) + "h"
        return Math.floor(n / 86400) + "d"
    }

    function getKeyPreview(row) {
        var val = getKeyValue(row)
        if (val.length > 60) return val.substring(0, 60) + "…"
        return val
    }

    function getTypeIcon(type) {
        if (type === "string") return Icons.formatText
        if (type === "list")   return Icons.list
        if (type === "set")    return Icons.grid
        if (type === "zset")   return Icons.chart
        if (type === "hash")   return Icons.code
        if (type === "stream") return Icons.lightning
        return Icons.key
    }

    function getTypeColor(type, alpha) {
        if (type === "string") return Qt.rgba(0.22, 0.56, 0.93, alpha)
        if (type === "list")   return Qt.rgba(0.93, 0.55, 0.22, alpha)
        if (type === "set")    return Qt.rgba(0.55, 0.22, 0.93, alpha)
        if (type === "zset")   return Qt.rgba(0.22, 0.78, 0.56, alpha)
        if (type === "hash")   return Qt.rgba(0.93, 0.22, 0.44, alpha)
        if (type === "stream") return Qt.rgba(0.22, 0.78, 0.93, alpha)
        return Qt.rgba(0.55, 0.55, 0.55, alpha)
    }

    // Parse hash entries from "field1:val1\nfield2:val2" or JSON {"k":"v"}
    function parseHashEntries(raw) {
        if (!raw) return []
        // Try JSON first
        try {
            var obj = JSON.parse(raw)
            if (typeof obj === "object" && !Array.isArray(obj)) {
                var res = []
                for (var k in obj) res.push({ field: k, value: String(obj[k]) })
                return res
            }
        } catch(e) {}
        // Fallback: line-by-line "field: value" or "field value"
        var lines = raw.split("\n"), result = []
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split(":")
            if (parts.length >= 2) result.push({ field: parts[0].trim(), value: parts.slice(1).join(":").trim() })
            else if (lines[i].trim()) result.push({ field: "(" + i + ")", value: lines[i].trim() })
        }
        return result
    }

    // Parse list entries from JSON array or newline-separated
    function parseListEntries(raw) {
        if (!raw) return []
        try {
            var arr = JSON.parse(raw)
            if (Array.isArray(arr)) return arr.map(function(v, i) { return { idx: i, value: String(v) } })
        } catch(e) {}
        return raw.split("\n").filter(function(l) { return l.trim() !== "" })
                  .map(function(l, i) { return { idx: i, value: l.trim() } })
    }

    // Parse ZSet: JSON [{score, member}] or "score member\nscore member"
    function parseZSetEntries(raw) {
        if (!raw) return []
        try {
            var arr = JSON.parse(raw)
            if (Array.isArray(arr)) return arr.map(function(v) {
                if (typeof v === "object") return { score: v.score, member: v.member }
                return { score: "", member: String(v) }
            })
        } catch(e) {}
        return raw.split("\n").filter(function(l) { return l.trim() !== "" })
                  .map(function(l) {
                      var parts = l.trim().split(" ")
                      if (parts.length >= 2) return { score: parts[0], member: parts.slice(1).join(" ") }
                      return { score: "", member: l.trim() }
                  })
    }
}
