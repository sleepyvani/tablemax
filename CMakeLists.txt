cmake_minimum_required(VERSION 3.16)
project(TableMax VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ─── Core Engine ───
add_library(tablemax_core STATIC
    core/src/query_engine.cpp
    core/src/plugin_loader.cpp
    core/src/connection_manager.cpp
    core/src/logger.cpp
)
target_include_directories(tablemax_core PUBLIC core/include)

# ─── Plugins ───
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
            qml/TabBar_.qml
            qml/Sidebar.qml
            qml/ConnectionDialog.qml
            qml/QueryEditor.qml
            qml/DataGrid.qml
            qml/SchemaTree.qml
            qml/StatusBar.qml
            qml/WelcomeView.qml
            qml/FlatButton.qml
            qml/FlatInput.qml
            qml/FlatTextArea.qml
            qml/FlatSelect.qml
            qml/FlatCheckbox.qml
            qml/FlatSwitch.qml
            qml/FlatRadioButton.qml
            qml/FlatBadge.qml
            qml/FlatDialog.qml
            qml/FlatTooltip.qml
            qml/FlatTabs.qml
            qml/FlatSeparator.qml
            qml/FlatCard.qml
            qml/FlatScrollArea.qml
            qml/FlatProgress.qml
            qml/FlatSkeleton.qml
            qml/FlatSpinner.qml
            qml/FlatLabel.qml
            qml/FlatContextMenu.qml
            qml/FlatAlert.qml
            qml/FlatToast.qml
            qml/FlatPopover.qml
            qml/FlatSlider.qml
            qml/FlatAvatar.qml
            qml/FlatAccordion.qml
            qml/FlatSheet.qml
            qml/FlatTable.qml
            qml/FlatDropdownMenu.qml
            qml/FlatField.qml
            qml/FlatKbd.qml
            qml/FlatPagination.qml
            qml/FlatResizable.qml
            qml/FlatToggle.qml
            qml/FlatToggleGroup.qml
            qml/FlatEmpty.qml
            qml/FlatColorPicker.qml
        SOURCES
            src/ConnectionManager.h
            src/DatabaseService.h
            src/TabManager.h
            src/SchemaService.h
            src/ThemeProvider.h
            src/models/QueryResultModel.h
        RESOURCES
            icons/postgres.svg
            icons/mysql.svg
            icons/sqlite.svg
            icons/mongodb.svg
            icons/redis.svg
            icons/mssql.svg
            icons/mariadb.svg
    )

    target_link_libraries(tablemax PRIVATE
        tablemax_core
        Qt6::Quick
        Qt6::QuickControls2
    )
else()
    message(STATUS "Qt6 not found — building core engine only")
    add_executable(tablemax_test core/test/test_engine.cpp)
    target_link_libraries(tablemax_test PRIVATE tablemax_core)
endif()
