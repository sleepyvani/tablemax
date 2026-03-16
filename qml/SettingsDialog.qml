// SettingsDialog.qml — Tabbed settings dialog
// Ported from TablePro SettingsView.swift (General/Editor/DataGrid/AI)

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

FlatDialog {
    id: root
    dialogTitle: "Settings"
    dialogDescription: "Configure your workspace"
    width: 640; height: 520

    property var appSettings: null
    property string activeTab: "general"

    contentItem: Rectangle {
        color: Theme.bg

        RowLayout {
            anchors.fill: parent; spacing: 0

            // ── Left sidebar ──
            Rectangle {
                Layout.preferredWidth: 160; Layout.fillHeight: true; color: Theme.bgSidebar

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.s8
                    anchors.bottomMargin: Theme.s8
                    spacing: Theme.s2

                    // Tab buttons - explicit instead of Repeater to avoid AOT issues
                    SettingTabBtn { tabId: "general"; label: "General"; icon: Icons.settings }
                    SettingTabBtn { tabId: "editor"; label: "Editor"; icon: Icons.code }
                    SettingTabBtn { tabId: "datagrid"; label: "Data Grid"; icon: Icons.grid }
                    SettingTabBtn { tabId: "appearance"; label: "Appearance"; icon: Icons.eye }
                    SettingTabBtn { tabId: "ai"; label: "AI"; icon: Icons.lightning }

                    Item { Layout.fillHeight: true }

                    // Reset
                    FlatButton {
                        Layout.fillWidth: true; Layout.leftMargin: Theme.s8; Layout.rightMargin: Theme.s8
                        text: "Reset All"; variant: "ghost"; size: "sm"
                        onClicked: if (appSettings) appSettings.resetAll()
                    }
                }
                DashedLine { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }
            }

            // ── Content area ──
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: settingsContent.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: settingsContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.s24
                    spacing: Theme.s20

                    Item { height: 16 } // Top padding

                    // ─────── General ───────
                    ColumnLayout {
                        visible: activeTab === "general"; spacing: Theme.s16; Layout.fillWidth: true
                        Text { text: "General"; font.pixelSize: Theme.t16; font.weight: Font.Bold; color: Theme.fg; font.family: Theme.sans }

                        SettingRow { label: "Auto-connect on startup"; description: "Reconnect to last database automatically"
                            FlatSwitch { checked: appSettings ? appSettings.autoConnect : true; onCheckedChanged: if (appSettings) appSettings.autoConnect = checked }
                        }
                        SettingRow { label: "Confirm on close"; description: "Show confirmation dialog before closing"
                            FlatSwitch { checked: appSettings ? appSettings.confirmOnClose : true; onCheckedChanged: if (appSettings) appSettings.confirmOnClose = checked }
                        }
                        SettingRow { label: "Restore tabs"; description: "Reopen tabs from last session"
                            FlatSwitch { checked: appSettings ? appSettings.restoreTabs : true; onCheckedChanged: if (appSettings) appSettings.restoreTabs = checked }
                        }
                    }

                    // ─────── Editor ───────
                    ColumnLayout {
                        visible: activeTab === "editor"; spacing: Theme.s16; Layout.fillWidth: true
                        Text { text: "Editor"; font.pixelSize: Theme.t16; font.weight: Font.Bold; color: Theme.fg; font.family: Theme.sans }

                        SettingRow { label: "Font family"; description: "Monospace font for SQL editor"
                            FlatInput { text: appSettings ? appSettings.editorFont : "Cascadia Code"; width: 160; onTextChanged: if (appSettings) appSettings.editorFont = text }
                        }
                        SettingRow { label: "Font size"; description: "Editor text size in pixels"
                            FlatInput { text: appSettings ? String(appSettings.editorFontSize) : "13"; width: 60; onTextChanged: if (appSettings) appSettings.editorFontSize = parseInt(text) || 13 }
                        }
                        SettingRow { label: "Line numbers"
                            FlatSwitch { checked: appSettings ? appSettings.editorLineNumbers : true; onCheckedChanged: if (appSettings) appSettings.editorLineNumbers = checked }
                        }
                        SettingRow { label: "Word wrap"
                            FlatSwitch { checked: appSettings ? appSettings.editorWordWrap : false; onCheckedChanged: if (appSettings) appSettings.editorWordWrap = checked }
                        }
                        SettingRow { label: "Autocomplete"; description: "Show SQL completion suggestions"
                            FlatSwitch { checked: appSettings ? appSettings.editorAutocomplete : true; onCheckedChanged: if (appSettings) appSettings.editorAutocomplete = checked }
                        }
                        SettingRow { label: "Vim mode"; description: "Enable Vim keybindings in editor"
                            FlatSwitch { checked: appSettings ? appSettings.editorVimMode : false; onCheckedChanged: if (appSettings) appSettings.editorVimMode = checked }
                        }
                    }

                    // ─────── Data Grid ───────
                    ColumnLayout {
                        visible: activeTab === "datagrid"; spacing: Theme.s16; Layout.fillWidth: true
                        Text { text: "Data Grid"; font.pixelSize: Theme.t16; font.weight: Font.Bold; color: Theme.fg; font.family: Theme.sans }

                        SettingRow { label: "Row height"; description: "Height of each row in pixels"
                            FlatInput { text: appSettings ? String(appSettings.rowHeight) : "28"; width: 60; onTextChanged: if (appSettings) appSettings.rowHeight = parseInt(text) || 28 }
                        }
                        SettingRow { label: "Alternate rows"; description: "Zebra stripe alternating rows"
                            FlatSwitch { checked: appSettings ? appSettings.alternateRows : true; onCheckedChanged: if (appSettings) appSettings.alternateRows = checked }
                        }
                        SettingRow { label: "Default page size"; description: "Rows loaded per page"
                            FlatSelect {
                                width: 100
                                model: [25, 50, 100, 250, 500, 1000]
                                currentIndex: model.indexOf(appSettings ? appSettings.pageSize : 100)
                                onCurrentIndexChanged: if (appSettings && currentIndex >= 0) appSettings.pageSize = model[currentIndex]
                            }
                        }
                        SettingRow { label: "NULL display"; description: "Text shown for NULL values"
                            FlatInput { text: appSettings ? appSettings.nullDisplay : "NULL"; width: 80; onTextChanged: if (appSettings) appSettings.nullDisplay = text }
                        }
                        SettingRow { label: "Date format"
                            FlatInput { text: appSettings ? appSettings.dateFormat : "yyyy-MM-dd HH:mm:ss"; width: 180; onTextChanged: if (appSettings) appSettings.dateFormat = text }
                        }
                    }

                    // ─────── Appearance ───────
                    ColumnLayout {
                        visible: activeTab === "appearance"; spacing: Theme.s16; Layout.fillWidth: true
                        Text { text: "Appearance"; font.pixelSize: Theme.t16; font.weight: Font.Bold; color: Theme.fg; font.family: Theme.sans }
                        Text { text: "Theme settings are managed from the system theme.\nTableMax follows your Windows dark/light mode automatically."; font.pixelSize: Theme.t12; color: Theme.fgMuted; font.family: Theme.sans; lineHeight: 1.5 }
                    }

                    // ─────── AI ───────
                    ColumnLayout {
                        visible: activeTab === "ai"; spacing: Theme.s16; Layout.fillWidth: true
                        Text { text: "AI Assistant"; font.pixelSize: Theme.t16; font.weight: Font.Bold; color: Theme.fg; font.family: Theme.sans }

                        SettingRow { label: "Provider"
                            FlatSelect {
                                width: 160; model: ["openai", "anthropic", "gemini", "ollama"]
                                currentIndex: model.indexOf(appSettings ? appSettings.aiProvider : "openai")
                                onCurrentIndexChanged: if (appSettings && currentIndex >= 0) appSettings.aiProvider = model[currentIndex]
                            }
                        }
                        SettingRow { label: "API Key"; description: "Your provider API key"
                            FlatInput {
                                text: appSettings ? appSettings.aiApiKey : ""; width: 260
                                echoMode: TextInput.Password
                                onTextChanged: if (appSettings) appSettings.aiApiKey = text
                            }
                        }
                        SettingRow { label: "Model"
                            FlatInput { text: appSettings ? appSettings.aiModel : "gpt-4o-mini"; width: 180; onTextChanged: if (appSettings) appSettings.aiModel = text }
                        }
                        SettingRow { label: "Inline suggestions"; description: "Ghost text AI completions in editor"
                            FlatSwitch { checked: appSettings ? appSettings.aiInlineSuggestions : false; onCheckedChanged: if (appSettings) appSettings.aiInlineSuggestions = checked }
                        }
                    }

                    Item { height: 16 } // Bottom padding
                }
            }
        }
    }

    // ── Setting row component ──
    component SettingRow : RowLayout {
        property string label: ""
        property string description: ""
        Layout.fillWidth: true; spacing: Theme.s12

        ColumnLayout {
            Layout.fillWidth: true; spacing: Theme.s2
            Text { text: label; font.pixelSize: Theme.t13; color: Theme.fg; font.family: Theme.sans }
            Text {
                text: description; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.sans
                visible: description !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap
            }
        }
    }

    // ── Tab button component ──
    component SettingTabBtn : Rectangle {
        property string tabId: ""
        property string label: ""
        property string icon: ""

        Layout.fillWidth: true; Layout.preferredHeight: 32; Layout.leftMargin: 8; Layout.rightMargin: 8; radius: Theme.r6
        color: root.activeTab === tabId ? Theme.bgHover : stbMa.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.s8
            spacing: Theme.s8
            FlatIcon { icon: parent.parent.icon; size: 14; color: root.activeTab === parent.parent.tabId ? Theme.accent : Theme.fgMuted }
            Text { text: parent.parent.label; font.pixelSize: Theme.t12; font.family: Theme.sans; color: root.activeTab === parent.parent.tabId ? Theme.fg : Theme.fgMuted; Layout.fillWidth: true }
        }
        MouseArea { id: stbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.activeTab = tabId }
    }
}
