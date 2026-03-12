cmake_minimum_required(VERSION 3.16)
project(TableMax VERSION 0.2.0 LANGUAGES C CXX)

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  PLUGINS — each with its own dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── SQLite (bundled sqlite3.c — zero deps) ───
add_library(sqlite SHARED
    plugins/sqlite/sqlite_plugin.cpp
    plugins/sqlite/sqlite3.c
)
target_include_directories(sqlite PRIVATE core/include plugins/sqlite)
if(WIN32)
    set_target_properties(sqlite PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

# ─── PostgreSQL (libpq) ───
set(PG_ROOT "C:/Program Files/PostgreSQL/18")
if(EXISTS "${PG_ROOT}/include/libpq-fe.h")
    add_library(postgres SHARED plugins/postgres/postgres_plugin.cpp)
    target_include_directories(postgres PRIVATE core/include "${PG_ROOT}/include")
    target_link_libraries(postgres PRIVATE "${PG_ROOT}/lib/libpq.lib")
    if(WIN32)
        set_target_properties(postgres PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
    endif()
    message(STATUS "PostgreSQL plugin: ENABLED (${PG_ROOT})")
else()
    message(WARNING "PostgreSQL plugin: DISABLED (libpq not found at ${PG_ROOT})")
endif()

# ─── MySQL (MySQL Connector/C) ───
# Check common locations
set(MYSQL_SEARCH_PATHS
    "C:/Program Files/MySQL/MySQL Connector C 8.0"
    "C:/Program Files/MySQL/MySQL Server 8.0"
    "C:/mysql"
    "C:/laragon/bin/mysql/mysql-8.0.30-winx64"
)
set(MYSQL_FOUND FALSE)
foreach(MYSQL_PATH ${MYSQL_SEARCH_PATHS})
    if(EXISTS "${MYSQL_PATH}/include/mysql.h")
        # Check for lib
        if(EXISTS "${MYSQL_PATH}/lib/libmysql.lib" OR EXISTS "${MYSQL_PATH}/lib/mysqlclient.lib" OR EXISTS "${MYSQL_PATH}/lib/libmysql.dll")
            set(MYSQL_ROOT "${MYSQL_PATH}")
            set(MYSQL_FOUND TRUE)
            break()
        endif()
    endif()
endforeach()

if(MYSQL_FOUND)
    add_library(mysql SHARED plugins/mysql/mysql_plugin.cpp)
    target_include_directories(mysql PRIVATE core/include "${MYSQL_ROOT}/include")
    if(EXISTS "${MYSQL_ROOT}/lib/libmysql.lib")
        target_link_libraries(mysql PRIVATE "${MYSQL_ROOT}/lib/libmysql.lib")
    elseif(EXISTS "${MYSQL_ROOT}/lib/mysqlclient.lib")
        target_link_libraries(mysql PRIVATE "${MYSQL_ROOT}/lib/mysqlclient.lib")
    endif()
    if(WIN32)
        set_target_properties(mysql PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
    endif()
    message(STATUS "MySQL plugin: ENABLED (${MYSQL_ROOT})")

    # MariaDB (reuses MySQL connector)
    add_library(mariadb SHARED plugins/mariadb/mariadb_plugin.cpp)
    target_include_directories(mariadb PRIVATE core/include "${MYSQL_ROOT}/include")
    if(EXISTS "${MYSQL_ROOT}/lib/libmysql.lib")
        target_link_libraries(mariadb PRIVATE "${MYSQL_ROOT}/lib/libmysql.lib")
    elseif(EXISTS "${MYSQL_ROOT}/lib/mysqlclient.lib")
        target_link_libraries(mariadb PRIVATE "${MYSQL_ROOT}/lib/mysqlclient.lib")
    endif()
    if(WIN32)
        set_target_properties(mariadb PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
    endif()
    message(STATUS "MariaDB plugin: ENABLED (reusing MySQL)")
else()
    message(WARNING "MySQL/MariaDB plugins: DISABLED (MySQL Connector/C not found)")
    message(WARNING "  Install MySQL Connector/C or set MYSQL_ROOT")
endif()

# ─── Redis (raw TCP — zero deps, needs ws2_32 on Windows) ───
add_library(redis SHARED plugins/redis/redis_plugin.cpp)
target_include_directories(redis PRIVATE core/include)
if(WIN32)
    target_link_libraries(redis PRIVATE ws2_32)
    set_target_properties(redis PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

# ─── MSSQL (Windows ODBC — zero deps) ───
if(WIN32)
    add_library(mssql SHARED plugins/mssql/mssql_plugin.cpp)
    target_include_directories(mssql PRIVATE core/include)
    target_link_libraries(mssql PRIVATE odbc32 odbccp32)
    set_target_properties(mssql PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
    message(STATUS "MSSQL plugin: ENABLED (Windows ODBC)")
else()
    message(WARNING "MSSQL plugin: DISABLED (ODBC not available on this platform)")
endif()

# ─── MongoDB (mongoc v2 driver) ───
set(MONGOC_ROOT "C:/mongo-c-driver")
if(EXISTS "${MONGOC_ROOT}/include/mongoc-2.2.3/mongoc/mongoc.h")
    add_library(mongo SHARED plugins/mongodb/mongo_plugin.cpp)
    target_include_directories(mongo PRIVATE core/include
        "${MONGOC_ROOT}/include/mongoc-2.2.3"
        "${MONGOC_ROOT}/include/bson-2.2.3"
    )
    target_link_libraries(mongo PRIVATE
        "${MONGOC_ROOT}/lib/libmongoc2.dll.lib"
        "${MONGOC_ROOT}/lib/libbson2.dll.lib"
    )
    if(WIN32)
        set_target_properties(mongo PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
        # Copy mongoc DLLs to build dir
        add_custom_command(TARGET mongo POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${MONGOC_ROOT}/bin/libmongoc2.dll"
                "${MONGOC_ROOT}/bin/libbson2.dll"
                $<TARGET_FILE_DIR:mongo>
        )
    endif()
    message(STATUS "MongoDB plugin: ENABLED (${MONGOC_ROOT})")
else()
    message(WARNING "MongoDB plugin: DISABLED (mongoc not found at ${MONGOC_ROOT})")
endif()

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Qt UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
            src/SyntaxHighlighter.h
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
