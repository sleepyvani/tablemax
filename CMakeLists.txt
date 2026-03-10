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
