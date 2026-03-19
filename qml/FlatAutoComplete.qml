import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

// FlatAutoComplete.qml
// A floating popup menu for IntelliSense-like auto-completion

Popup {
    id: root
    padding: 0
    margins: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Properties
    property var suggestions: []
    property int currentIndex: 0
    
    signal suggestionAccepted(string text)
    
    background: Rectangle {
        color: Theme.bgElevated
        radius: Theme.r8
        border.width: 1
        border.color: Theme.border
        
        // Shadow effect
        layer.enabled: true
    }
    
    width: 280
    height: Math.min(suggestions.length * 32 + 8, 200)
    visible: suggestions.length > 0
    
    // Watch index reset
    onSuggestionsChanged: currentIndex = 0
    onClosed: suggestions = []
    
    // Navigation
    function moveUp() {
        if (suggestions.length === 0) return false;
        if (currentIndex > 0) {
            currentIndex--;
        } else {
            currentIndex = suggestions.length - 1;
        }
        list.positionViewAtIndex(currentIndex, ListView.Contain);
        return true;
    }
    
    function moveDown() {
        if (suggestions.length === 0) return false;
        if (currentIndex < suggestions.length - 1) {
            currentIndex++;
        } else {
            currentIndex = 0;
        }
        list.positionViewAtIndex(currentIndex, ListView.Contain);
        return true;
    }
    
    function acceptCurrent() {
        if (suggestions.length > 0 && currentIndex >= 0 && currentIndex < suggestions.length) {
            suggestionAccepted(suggestions[currentIndex].text);
            close();
            return true;
        }
        return false;
    }
    
    contentItem: ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 4
        clip: true
        model: suggestions
        currentIndex: root.currentIndex
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            contentItem: Rectangle { color: Theme.borderLight; radius: 2; opacity: 0.6 }
        }
        
        delegate: Rectangle {
            width: list.width
            height: 32
            radius: Theme.r4
            color: root.currentIndex === index || ma.containsMouse ? Theme.bgHover : "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.s12
                anchors.rightMargin: Theme.s8
                spacing: Theme.s8
                
                // Icon based on type
                FlatIcon {
                    icon: {
                        if (modelData.type === "keyword") return Icons.code;
                        if (modelData.type === "table") return Icons.grid;
                        if (modelData.type === "column") return Icons.list;
                        return Icons.hash;
                    }
                    size: 14
                    color: {
                        if (modelData.type === "keyword") return Theme.accent;
                        if (modelData.type === "table") return Theme.info;
                        if (modelData.type === "column") return Theme.warning;
                        return Theme.fgMuted;
                    }
                }
                
                // Text
                Text {
                    text: modelData.text || ""
                    Layout.fillWidth: true
                    font.family: Theme.mono
                    font.pixelSize: Theme.t12
                    font.weight: modelData.type === "keyword" ? Font.Bold : Font.Normal
                    color: Theme.fg
                    elide: Text.ElideRight
                }
                
                // Type label
                Text {
                    text: modelData.type || ""
                    font.family: Theme.sans
                    font.pixelSize: 9
                    color: Theme.fgMuted
                    opacity: 0.6
                }
            }
            
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.currentIndex = index
                onClicked: {
                    root.currentIndex = index
                    root.acceptCurrent()
                }
            }
        }
    }
}
