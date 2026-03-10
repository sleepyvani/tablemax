cmake_minimum_required(VERSION 3.16)
project(TableMax VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ─── Core Engine (no Qt needed) ───
add_library(tablemax_core STATIC
    core/src/query_engine.cpp
    core/src/plugin_loader.cpp
    core/src/connection_manager.cpp
    core/src/logger.cpp
)
target_include_directories(tablemax_core PUBLIC core/include)

# ─── Plugins (shared libraries) ───
macro(add_db_plugin name folder)
    add_library(${name} SHARED plugins/${folder}/${name}_plugin.cpp)
    target_include_directories(${name} PRIVATE core/include)
endmacro()

add_db_plugin(postgres postgres)
add_db_plugin(mysql mysql)
add_db_plugin(sqlite sqlite)
add_db_plugin(mongo mongodb)
add_db_plugin(redis redis)
add_db_plugin(mssql mssql)
add_db_plugin(mariadb mariadb)

# ─── Qt UI ───
find_package(Qt6 QUIET COMPONENTS Quick QuickControls2)

if(Qt6_FOUND)
    message(STATUS "Qt6 found — building full app")
    qt_standard_project_setup()

    qt_add_executable(tablemax src/main.cpp)

    # ── Type names for app components (in subdirectory) ──
    set_source_files_properties(qml/components/Sidebar.qml PROPERTIES QT_QML_SOURCE_TYPENAME Sidebar)
    set_source_files_properties(qml/components/ConnectionDialog.qml PROPERTIES QT_QML_SOURCE_TYPENAME ConnectionDialog)
    set_source_files_properties(qml/components/QueryEditor.qml PROPERTIES QT_QML_SOURCE_TYPENAME QueryEditor)
    set_source_files_properties(qml/components/DataGrid.qml PROPERTIES QT_QML_SOURCE_TYPENAME DataGrid)
    set_source_files_properties(qml/components/SchemaTree.qml PROPERTIES QT_QML_SOURCE_TYPENAME SchemaTree)
    set_source_files_properties(qml/components/StatusBar.qml PROPERTIES QT_QML_SOURCE_TYPENAME StatusBar)
    set_source_files_properties(qml/components/WelcomeView.qml PROPERTIES QT_QML_SOURCE_TYPENAME WelcomeView)

    qt_add_qml_module(tablemax
        URI TableMax
        VERSION 1.0
        QML_FILES
            qml/Main.qml
            qml/components/Sidebar.qml
            qml/components/ConnectionDialog.qml
            qml/components/QueryEditor.qml
            qml/components/DataGrid.qml
            qml/components/SchemaTree.qml
            qml/components/StatusBar.qml
            qml/components/WelcomeView.qml
        SOURCES
            src/ConnectionManager.h
            src/DatabaseService.h
            src/TabManager.h
            src/SchemaService.h
            src/models/QueryResultModel.h
    )

    # ── Type names for controls (in subdirectory) ──
    set_source_files_properties(qml/controls/Theme.qml PROPERTIES
        QT_QML_SOURCE_TYPENAME Theme
        QT_QML_SINGLETON_TYPE TRUE)
    set_source_files_properties(qml/controls/FlatButton.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatButton)
    set_source_files_properties(qml/controls/FlatInput.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatInput)
    set_source_files_properties(qml/controls/FlatTextArea.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatTextArea)
    set_source_files_properties(qml/controls/FlatSelect.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSelect)
    set_source_files_properties(qml/controls/FlatCheckbox.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatCheckbox)
    set_source_files_properties(qml/controls/FlatSwitch.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSwitch)
    set_source_files_properties(qml/controls/FlatRadioButton.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatRadioButton)
    set_source_files_properties(qml/controls/FlatBadge.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatBadge)
    set_source_files_properties(qml/controls/FlatDialog.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatDialog)
    set_source_files_properties(qml/controls/FlatTooltip.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatTooltip)
    set_source_files_properties(qml/controls/FlatTabs.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatTabs)
    set_source_files_properties(qml/controls/FlatSeparator.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSeparator)
    set_source_files_properties(qml/controls/FlatCard.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatCard)
    set_source_files_properties(qml/controls/FlatScrollArea.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatScrollArea)
    set_source_files_properties(qml/controls/FlatProgress.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatProgress)
    set_source_files_properties(qml/controls/FlatSkeleton.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSkeleton)
    set_source_files_properties(qml/controls/FlatSpinner.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSpinner)
    set_source_files_properties(qml/controls/FlatLabel.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatLabel)
    set_source_files_properties(qml/controls/FlatContextMenu.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatContextMenu)
    set_source_files_properties(qml/controls/FlatAlert.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatAlert)
    set_source_files_properties(qml/controls/FlatToast.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatToast)
    set_source_files_properties(qml/controls/FlatPopover.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatPopover)
    set_source_files_properties(qml/controls/FlatSlider.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSlider)
    set_source_files_properties(qml/controls/FlatAvatar.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatAvatar)
    set_source_files_properties(qml/controls/FlatAccordion.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatAccordion)
    set_source_files_properties(qml/controls/FlatSheet.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatSheet)
    set_source_files_properties(qml/controls/FlatTable.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatTable)
    set_source_files_properties(qml/controls/FlatDropdownMenu.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatDropdownMenu)
    set_source_files_properties(qml/controls/FlatField.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatField)
    set_source_files_properties(qml/controls/FlatKbd.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatKbd)
    set_source_files_properties(qml/controls/FlatPagination.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatPagination)
    set_source_files_properties(qml/controls/FlatResizable.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatResizable)
    set_source_files_properties(qml/controls/FlatToggle.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatToggle)
    set_source_files_properties(qml/controls/FlatToggleGroup.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatToggleGroup)
    set_source_files_properties(qml/controls/FlatEmpty.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatEmpty)
    set_source_files_properties(qml/controls/FlatColorPicker.qml PROPERTIES QT_QML_SOURCE_TYPENAME FlatColorPicker)

    qt_add_qml_module(tablemax_controls
        URI TableMax.Controls
        VERSION 1.0
        STATIC
        QML_FILES
            qml/controls/Theme.qml
            qml/controls/FlatButton.qml
            qml/controls/FlatInput.qml
            qml/controls/FlatTextArea.qml
            qml/controls/FlatSelect.qml
            qml/controls/FlatCheckbox.qml
            qml/controls/FlatSwitch.qml
            qml/controls/FlatRadioButton.qml
            qml/controls/FlatBadge.qml
            qml/controls/FlatDialog.qml
            qml/controls/FlatTooltip.qml
            qml/controls/FlatTabs.qml
            qml/controls/FlatSeparator.qml
            qml/controls/FlatCard.qml
            qml/controls/FlatScrollArea.qml
            qml/controls/FlatProgress.qml
            qml/controls/FlatSkeleton.qml
            qml/controls/FlatSpinner.qml
            qml/controls/FlatLabel.qml
            qml/controls/FlatContextMenu.qml
            qml/controls/FlatAlert.qml
            qml/controls/FlatToast.qml
            qml/controls/FlatPopover.qml
            qml/controls/FlatSlider.qml
            qml/controls/FlatAvatar.qml
            qml/controls/FlatAccordion.qml
            qml/controls/FlatSheet.qml
            qml/controls/FlatTable.qml
            qml/controls/FlatDropdownMenu.qml
            qml/controls/FlatField.qml
            qml/controls/FlatKbd.qml
            qml/controls/FlatPagination.qml
            qml/controls/FlatResizable.qml
            qml/controls/FlatToggle.qml
            qml/controls/FlatToggleGroup.qml
            qml/controls/FlatEmpty.qml
            qml/controls/FlatColorPicker.qml
    )

    target_link_libraries(tablemax PRIVATE
        tablemax_core
        tablemax_controlsplugin
        Qt6::Quick
        Qt6::QuickControls2
    )
else()
    message(STATUS "Qt6 not found — building core engine only")
    add_executable(tablemax_test core/test/test_engine.cpp)
    target_link_libraries(tablemax_test PRIVATE tablemax_core)
endif()
