---
name: pyside6-qml-views
description: Use this skill when creating QML view files, designing QML component hierarchies, building layouts, styling QML controls, creating reusable QML components, implementing QML navigation / page switching, or working with QML resources. Covers QML file structure, component patterns, Material/Controls styling, resource management, and common QML idioms for desktop applications.
---

# PySide6 QML Views

All UI in this architecture is defined declaratively in `.qml` files. QML views bind to Python bridge properties and call bridge slots — they contain **no business logic**.

## QML File Organization

```
resources/
├── qml/
│   ├── main.qml                  # Root window / StackLayout host
│   ├── components/
│   │   ├── ActionButton.qml      # Reusable styled button
│   │   ├── StatusBadge.qml       # Status indicator
│   │   ├── SearchBar.qml         # Search input with debounce
│   │   ├── LoadingOverlay.qml    # Busy spinner overlay
│   │   └── ErrorBanner.qml       # Error message bar
│   ├── pages/
│   │   ├── JobListPage.qml       # Job listing with cards
│   │   ├── JobDetailPage.qml     # Single job detail view
│   │   ├── SettingsPage.qml      # App settings form
│   │   └── DashboardPage.qml     # Overview / landing page
│   ├── dialogs/
│   │   ├── CreateJobDialog.qml   # Modal dialog for new job
│   │   └── ConfirmDialog.qml     # Generic confirmation popup
│   └── styles/
│       ├── Theme.qml             # Colour palette, spacing, fonts
│       └── qmldir                # Module metadata for imports
├── icons/
│   ├── *.svg                     # Vector icons
│   └── *.png                     # Raster icons
└── qml.qrc                       # Qt resource file (optional)
```

## Root Window (main.qml)

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "My Application"

    // Page navigation
    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: 0

        JobListPage {}
        JobDetailPage {}
        SettingsPage {}
    }

    // Global toolbar
    header: ToolBar {
        RowLayout {
            anchors.fill: parent

            Label {
                text: "My App"
                font.bold: true
                Layout.leftMargin: 12
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                text: "Jobs"
                onClicked: pageStack.currentIndex = 0
            }
            ToolButton {
                text: "Settings"
                onClicked: pageStack.currentIndex = 2
            }
        }
    }

    // Global error banner
    ErrorBanner {
        id: errorBanner
        anchors { top: parent.top; left: parent.left; right: parent.right }
        visible: jobBridge.errorMessage !== ""
        message: jobBridge.errorMessage
    }

    // Loading overlay
    LoadingOverlay {
        anchors.fill: parent
        visible: jobBridge.isBusy
    }
}
```

## Page Pattern

Every page is a self-contained QML file that binds to bridge properties:

```qml
// pages/JobListPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: jobListPage

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                onSearchTriggered: jobBridge.searchJobs(query)
            }
            ActionButton {
                text: "New Job"
                icon.name: "add"
                onClicked: createJobDialog.open()
            }
        }
    }

    ListView {
        id: jobsListView
        anchors.fill: parent
        model: jobListModel
        spacing: 4
        clip: true

        delegate: ItemDelegate {
            width: jobsListView.width
            height: 64

            contentItem: RowLayout {
                spacing: 12
                Label {
                    text: model.jobNumber
                    font.bold: true
                    Layout.preferredWidth: 100
                }
                Label {
                    text: model.jobName
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                StatusBadge {
                    status: model.status
                }
            }

            onClicked: {
                jobBridge.activateJob(model.jobNumber)
                pageStack.currentIndex = 1  // navigate to detail
            }
        }

        // Empty state
        Label {
            anchors.centerIn: parent
            visible: jobsListView.count === 0
            text: "No jobs found"
            opacity: 0.5
        }
    }

    CreateJobDialog {
        id: createJobDialog
    }
}
```

## Reusable Component Pattern

### Component File Structure

```qml
// components/ActionButton.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control

    // Custom properties
    property color accentColor: "#1976D2"
    property bool loading: false

    enabled: !loading
    opacity: enabled ? 1.0 : 0.5

    contentItem: Row {
        spacing: 8
        BusyIndicator {
            running: control.loading
            visible: control.loading
            width: 16; height: 16
        }
        Label {
            text: control.text
            color: "white"
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: 4
        color: control.down ? Qt.darker(accentColor, 1.2)
             : control.hovered ? Qt.lighter(accentColor, 1.1)
             : accentColor
    }
}
```

### Component with Custom Signals

```qml
// components/SearchBar.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    id: searchField

    signal searchTriggered(string query)

    placeholderText: "Search..."
    selectByMouse: true

    // Debounced search
    Timer {
        id: debounceTimer
        interval: 300
        onTriggered: searchField.searchTriggered(searchField.text)
    }

    onTextChanged: debounceTimer.restart()
    onAccepted: {
        debounceTimer.stop()
        searchTriggered(text)
    }
}
```

## Dialog Pattern

```qml
// dialogs/CreateJobDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: dialog
    title: "Create New Job"
    modal: true
    anchors.centerIn: Overlay.overlay
    width: 400
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        if (jobNumberInput.text.trim() !== "") {
            jobBridge.createJob(jobNumberInput.text.trim())
        }
    }
    onRejected: dialog.close()

    // Reset on open
    onOpened: {
        jobNumberInput.text = ""
        jobNumberInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label { text: "Job Number" }
        TextField {
            id: jobNumberInput
            Layout.fillWidth: true
            placeholderText: "e.g. 1234567"
            validator: RegularExpressionValidator {
                regularExpression: /^\d{5,8}[A-Z]?$/
            }
        }

        Label {
            text: "Enter a valid job number (5-8 digits, optional letter suffix)"
            font.pixelSize: 11
            opacity: 0.6
        }
    }
}
```

## Theme / Styling

### Theme Singleton

```qml
// styles/Theme.qml
pragma Singleton
import QtQuick 2.15

QtObject {
    // Colours
    readonly property color primary: "#1976D2"
    readonly property color primaryDark: "#1565C0"
    readonly property color accent: "#FF9800"
    readonly property color background: "#FAFAFA"
    readonly property color surface: "#FFFFFF"
    readonly property color error: "#D32F2F"
    readonly property color textPrimary: "#212121"
    readonly property color textSecondary: "#757575"

    // Spacing
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24

    // Typography
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeTitle: 24

    // Elevation / Radii
    readonly property int borderRadius: 4
    readonly property int cardRadius: 8
}
```

### qmldir (module registration)

```
// styles/qmldir
module Styles
singleton Theme 1.0 Theme.qml
```

### Usage

```qml
import "styles" as Styles

Rectangle {
    color: Styles.Theme.surface
    radius: Styles.Theme.cardRadius

    Label {
        color: Styles.Theme.textPrimary
        font.pixelSize: Styles.Theme.fontSizeMedium
    }
}
```

## Loading States

```qml
// components/LoadingOverlay.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: overlay
    color: "#80000000"  // semi-transparent black
    visible: false
    z: 999

    BusyIndicator {
        anchors.centerIn: parent
        running: overlay.visible
        width: 48; height: 48
    }

    MouseArea {
        anchors.fill: parent
        // Block clicks through overlay
    }
}
```

## Status Indicator

```qml
// components/StatusBadge.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: badge
    property string status: ""

    width: statusLabel.implicitWidth + 16
    height: 24
    radius: 12
    color: {
        switch (status.toLowerCase()) {
            case "active":   return "#4CAF50";
            case "complete": return "#2196F3";
            case "on_hold":  return "#FF9800";
            case "archived": return "#9E9E9E";
            default:         return "#BDBDBD";
        }
    }

    Label {
        id: statusLabel
        anchors.centerIn: parent
        text: badge.status
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }
}
```

## QML Best Practices

| Rule | Rationale |
|------|-----------|
| Keep components under 150 lines | Maintainability; extract sub-components |
| One root item per file | QML convention |
| Use `id` only when referenced | Avoid unnecessary identity |
| Prefer property bindings over imperative JS | Declarative updates, fewer bugs |
| Use `Loader` for heavy / conditional content | Lazy instantiation saves memory |
| Never embed SQL, HTTP, or file I/O in QML JS | All side-effects go through bridge slots |
| Qualify property access (`root.width` vs `width`) | Avoid shadowing in nested items |
| Use anchors or layouts, not manual x/y | Responsive and maintainable |

## Resource Loading

### Icons from filesystem

```qml
Image {
    source: "file:///" + Qt.resolvedUrl("../../icons/logo.svg")
}
```

### Icons via Qt Resource System

```qml
Image {
    source: "qrc:/icons/logo.svg"
}
```

### Qt Resource File (qml.qrc)

```xml
<RCC>
    <qresource prefix="/">
        <file>qml/main.qml</file>
        <file>qml/components/ActionButton.qml</file>
        <file>icons/logo.svg</file>
    </qresource>
</RCC>
```

## References

- [QML Coding Conventions](https://doc.qt.io/qt-6/qml-codingconventions.html)
- [Qt Quick Controls](https://doc.qt.io/qt-6/qtquickcontrols-index.html)
- [Qt Quick Layouts](https://doc.qt.io/qt-6/qtquicklayouts-index.html)
