# TableMax — Project Rules / Quy Tắc Dự Án
# Bilingual: English (EN) | Tiếng Việt (VN)

> This file defines ALL binding conventions for the TableMax codebase.
> Tệp này định nghĩa TẤT CẢ quy tắc ràng buộc cho mã nguồn TableMax.
> Every contributor (human or AI) MUST follow these rules.
> Mọi người đóng góp (người hoặc AI) PHẢI tuân theo các quy tắc này.

---

## 1. ARCHITECTURE / KIẾN TRÚC

### 1.1 Layer Separation / Phân Tách Tầng

```
┌─────────────────────────────────────────┐
│  QML UI (shadcn-style, GPU-rendered)    │  ← Frontend / Giao diện
├─────────────────────────────────────────┤
│  C++ Backend (Qt QObject services)      │  ← Backend / Dịch vụ
├─────────────────────────────────────────┤
│  C++ Core Engine (pure C++, no Qt)      │  ← Core / Lõi
├─────────────────────────────────────────┤
│  Database Plugins (shared libraries)    │  ← Drivers / Trình điều khiển
└─────────────────────────────────────────┘
```

**EN:** The application is a strict 4-layer architecture. Each layer may ONLY call the layer directly below it. QML never calls Core Engine directly — it goes through Backend services. Core Engine has ZERO Qt dependency.

**VN:** Ứng dụng có kiến trúc 4 tầng nghiêm ngặt. Mỗi tầng CHỈ được gọi tầng ngay bên dưới. QML không bao giờ gọi trực tiếp Core Engine — phải thông qua Backend services. Core Engine KHÔNG phụ thuộc Qt.

### 1.2 No IPC, No WebView / Không IPC, Không WebView

**EN:** This is a native Qt6 QML app. No Electron. No web bridge. No IPC protocols. Direct C++ calls from QML via Q_INVOKABLE.

**VN:** Đây là ứng dụng Qt6 QML thuần. Không Electron. Không web bridge. Không giao thức IPC. Gọi trực tiếp C++ từ QML qua Q_INVOKABLE.

### 1.3 Query Flow / Luồng Truy Vấn

```
QML (user types query)
  → DatabaseService::executeQuery(query, resultModel)
    → Engine::execute(connId, query)
      → IDbPlugin::execute(query)
        → Database Server
      ← IResultStream (columns + chunked rows)
    ← QVariantMap {success, rowCount, execTime, error}
  → QueryResultModel::setData(columns, rows)
    → QML TableView auto-updates (GPU rendered)
```

**EN:** Never load full result sets into memory. Use `IResultStream::next_chunk()` with chunk_size=500.

**VN:** Không bao giờ tải toàn bộ kết quả vào bộ nhớ. Dùng `IResultStream::next_chunk()` với chunk_size=500.

---

## 2. PROJECT STRUCTURE / CẤU TRÚC DỰ ÁN

```
tablemax/
├── CMakeLists.txt              # Root build file / Tệp build gốc
├── Architecture.md             # Design documentation / Tài liệu thiết kế
├── rules/                      # Project rules / Quy tắc dự án
├── core/                       # Pure C++ engine (NO Qt) / Engine C++ thuần
│   ├── include/
│   │   ├── engine.h            # Engine class / Lớp Engine
│   │   └── plugin_interface.h  # IDbPlugin + IResultStream interfaces
│   └── src/
│       ├── query_engine.cpp    # Engine::connect/execute/disconnect
│       ├── plugin_loader.cpp   # DLL scanning (LoadLibraryA / dlopen)
│       ├── connection_manager.cpp  # Engine::load_plugins bridge
│       └── logger.cpp          # Static Logger class
├── src/                        # Qt Backend services / Dịch vụ Qt Backend
│   ├── main.cpp                # Entry point / Điểm khởi đầu
│   ├── ConnectionManager.h     # Connection CRUD + persistence
│   ├── DatabaseService.h       # DB operations bridge to Engine
│   ├── TabManager.h            # Query tab state management
│   ├── SchemaService.h         # Schema tree data provider
│   ├── ThemeProvider.h         # Theme tokens (colors, spacing, fonts)
│   └── models/
│       └── QueryResultModel.h  # QAbstractTableModel for DataGrid
├── qml/                        # ALL QML files (flat directory) / Tất cả QML
│   ├── Main.qml                # Root ApplicationWindow
│   ├── Sidebar.qml             # Connection list + Schema tree
│   ├── ConnectionDialog.qml    # Add/edit connection dialog
│   ├── QueryEditor.qml         # SQL editor with line numbers
│   ├── DataGrid.qml            # Result table (TableView)
│   ├── SchemaTree.qml          # Database/Table/Column tree
│   ├── TabBar_.qml             # Query tab bar (underscore to avoid Qt conflict)
│   ├── StatusBar.qml           # Bottom status bar
│   ├── WelcomeView.qml         # Empty state welcome screen
│   └── Flat*.qml               # 31 shadcn-style reusable controls
├── plugins/                    # Database driver plugins / Plugin CSDL
│   ├── sqlite/                 # Bundled sqlite3.c (zero deps)
│   ├── postgres/               # libpq
│   ├── mysql/                  # MySQL Connector/C
│   ├── mariadb/                # Reuses MySQL Connector/C
│   ├── redis/                  # Raw TCP + RESP (zero deps)
│   ├── mssql/                  # Windows ODBC (zero deps on Windows)
│   └── mongodb/                # mongoc v2 C driver
├── icons/                      # SVG icons for DB types / Biểu tượng SVG
└── build/                      # Build output / Kết quả build
```

### 2.1 File Organization Rules / Quy Tắc Tổ Chức File

**EN:**
- ALL QML files are in `qml/` directory — flat, no subdirectories.
- ALL Qt service classes are **header-only** (`.h` only, no `.cpp`).
- ALL core engine code is in `core/` — pure C++17, no Qt includes.
- Each plugin is in its own `plugins/<name>/` directory with one `.cpp` file.
- SVG icons go in `icons/` and must be named `<dbtype>.svg` (lowercase).

**VN:**
- TẤT CẢ file QML nằm trong `qml/` — phẳng, không thư mục con.
- TẤT CẢ lớp Qt service chỉ có **header** (chỉ `.h`, không `.cpp`).
- TẤT CẢ code engine lõi nằm trong `core/` — C++17 thuần, không include Qt.
- Mỗi plugin nằm trong thư mục `plugins/<tên>/` riêng với một file `.cpp`.
- Icon SVG đặt trong `icons/` và phải đặt tên `<dbtype>.svg` (chữ thường).

---

## 3. C++ BACKEND / C++ PHÍA SAU

### 3.1 Namespace / Không Gian Tên

**EN:** All core engine code lives in `namespace tablemax { }`. Qt service classes are in global namespace but use `tablemax::Engine` internally.

**VN:** Tất cả code engine lõi nằm trong `namespace tablemax { }`. Các lớp Qt service ở namespace toàn cục nhưng dùng `tablemax::Engine` bên trong.

### 3.2 C++ Standard / Tiêu Chuẩn C++

- C++17 (`set(CMAKE_CXX_STANDARD 17)`)
- `using namespace std;` is used globally in all source files
- Member variables use trailing underscore: `connId_`, `error_`, `loading_`
- Private member prefix: `m_` for ThemeProvider only (Qt convention)
- Header guards: `#pragma once`

### 3.3 Qt Service Pattern / Mẫu Dịch Vụ Qt

**EN:** Every Qt backend service follows this exact pattern:

```cpp
class ServiceName : public QObject {
    Q_OBJECT
    Q_PROPERTY(Type propName READ propName NOTIFY propNameChanged)

public:
    explicit ServiceName(QObject* parent = nullptr) : QObject(parent) {}

    // Read accessors
    Type propName() const { return prop_; }

    // Q_INVOKABLE methods (callable from QML)
    Q_INVOKABLE ReturnType methodName(args...);

signals:
    void propNameChanged();

private:
    Type prop_;
    void setHelper(Type v) { if (prop_ != v) { prop_ = v; emit propNameChanged(); } }
};
```

**VN:** Mỗi dịch vụ Qt backend tuân theo mẫu chính xác này. Tất cả trạng thái được expose qua `Q_PROPERTY + NOTIFY`. Mọi hành động từ QML gọi qua `Q_INVOKABLE`.

### 3.4 Context Properties / Thuộc Tính Context

**EN:** All services are exposed to QML as context properties in `main.cpp`:

| Context Name | C++ Class | Purpose / Mục đích |
|---|---|---|
| `connectionManager` | `ConnectionManager` | Connection CRUD + persistence / CRUD kết nối + lưu trữ |
| `databaseService` | `DatabaseService` | DB operations (connect, execute, schema) / Thao tác CSDL |
| `tabManager` | `TabManager` | Query tab state / Trạng thái tab truy vấn |
| `schemaService` | `SchemaService` | Schema tree data / Dữ liệu cây schema |
| `resultModel` | `QueryResultModel` | Query results for DataGrid / Kết quả truy vấn |
| `Theme` | `ThemeProvider` | Design tokens / Token thiết kế |

**VN:** KHÔNG tạo context property mới mà không cập nhật bảng này. Tên context property là `camelCase`, ngoại trừ `Theme` (viết hoa vì nó là singleton toàn cục).

### 3.5 Data Persistence / Lưu Trữ Dữ Liệu

- Connections saved to `QSettings("VaniStudio", "TableMax")` as JSON in `connections/data`
- Theme preference saved as `theme/darkMode` boolean
- No SQLite, no local database for app state

---

## 4. PLUGIN SYSTEM / HỆ THỐNG PLUGIN

### 4.1 Plugin Interface / Giao Diện Plugin

**EN:** Every database plugin is a shared library (.dll/.so) that exports exactly 2 C functions:

```cpp
extern "C" {
    tablemax::IDbPlugin* create_plugin();
    void destroy_plugin(tablemax::IDbPlugin* p);
}
```

**VN:** Mỗi plugin CSDL là thư viện chia sẻ (.dll/.so) export chính xác 2 hàm C.

### 4.2 IDbPlugin Contract / Hợp Đồng IDbPlugin

Every plugin MUST implement ALL 11 virtual methods:

| Method | Purpose / Mục đích |
|---|---|
| `name()` | Human-readable name, e.g. "PostgreSQL" |
| `version()` | Always return `"0.2.0"` (current app version) |
| `db_type()` | Lowercase identifier: `"postgres"`, `"sqlite"`, `"mongodb"`, etc. |
| `connect(conn_str)` | Connect using connection string |
| `disconnect()` | Clean disconnect |
| `is_connected()` | Return connection status |
| `test_connection(ms)` | Ping test, write latency to `ms` |
| `execute(query)` | Execute query, return `IResultStream` |
| `list_databases()` | List all databases |
| `list_tables(database)` | List tables in database |
| `get_table_schema(table)` | Return columns with types |
| `last_error()` | Return last error string |

### 4.3 Plugin Boilerplate / Mẫu Plugin

Every plugin file follows this exact structure:

```cpp
#include "plugin_interface.h"
// Windows byte fix if needed (winsock/windows.h)
// Database-specific headers
#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

class XxxResultStream : public IResultStream { /* chunk-based result */ };
class XxxPlugin : public IDbPlugin { /* all 11 methods */ };

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::XxxPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
```

### 4.4 Windows Byte Fix / Sửa Lỗi Byte Windows

**EN:** When including Windows headers (winsock2.h, windows.h), ALWAYS use this pattern to avoid `std::byte` conflict:

```cpp
#ifdef _WIN32
    #ifndef NOMINMAX
    #define NOMINMAX
    #endif
    #define byte win_byte_override
    #include <windows.h>  // or <winsock2.h>
    #undef byte
#endif
```

**VN:** Khi include header Windows, LUÔN dùng mẫu trên để tránh xung đột `std::byte` với C++17.

### 4.5 Plugin db_type Values / Giá Trị db_type

These are the EXACT lowercase strings that plugins return from `db_type()` and that the QML/ConnectionManager use:

| db_type | Plugin | Icon file |
|---|---|---|
| `"postgres"` | libpostgres.dll | postgres.svg |
| `"mysql"` | libmysql.dll | mysql.svg |
| `"mariadb"` | libmariadb.dll | mariadb.svg |
| `"sqlite"` | libsqlite.dll | sqlite.svg |
| `"mongodb"` | libmongo.dll | mongodb.svg |
| `"redis"` | libredis.dll | redis.svg |
| `"mssql"` | libmssql.dll | mssql.svg |

**EN:** The db_type string is used for: plugin matching, icon lookup (`icons/<dbtype>.svg`), and UI display. It MUST be lowercase and match across all systems.

**VN:** Chuỗi db_type dùng cho: khớp plugin, tra cứu icon (`icons/<dbtype>.svg`), và hiển thị UI. PHẢI viết thường và khớp trên tất cả hệ thống.

---

## 5. QML FRONTEND / GIAO DIỆN QML

### 5.1 Imports / Khai Báo Import

**EN:** Every QML file MUST use these exact imports:

```qml
import QtQuick
import QtQuick.Controls.Basic      // NOT QtQuick.Controls
import QtQuick.Layouts
```

- Use `QtQuick.Controls.Basic` (not Material, Fusion, etc.) — we style everything custom.
- When creating Flat* controls that extend Qt types, alias the import: `import QtQuick.Controls.Basic as T`

**VN:** Dùng `QtQuick.Controls.Basic` — không dùng Material/Fusion vì chúng ta tự style. Khi tạo Flat* control kế thừa kiểu Qt, alias import: `as T`.

### 5.2 Component Naming / Đặt Tên Component

| Category | Pattern | Examples |
|---|---|---|
| App views | `PascalCase.qml` | `Sidebar.qml`, `DataGrid.qml`, `SchemaTree.qml` |
| Reusable controls | `Flat<Name>.qml` | `FlatButton.qml`, `FlatInput.qml`, `FlatSelect.qml` |
| Qt conflict avoidance | Append `_` | `TabBar_.qml` (avoids Qt's built-in TabBar) |

**VN:** Views dùng PascalCase. Controls có prefix `Flat`. Nếu trùng tên Qt built-in, thêm `_`.

### 5.3 Component Root ID / ID Gốc Component

- App views use descriptive IDs: `id: sidebar`, `id: dlg`, `id: sb`
- Flat* controls always use `id: root`
- Internal elements use underscore prefix: `_search`, `_themeMa`, `_rowMa`
- NEVER use `z: -10` on a MouseArea — it will block everything

### 5.4 Flat* Component API / API Component Flat*

**EN:** All Flat* components follow the shadcn/radix pattern:

```qml
T.Button {       // Extends a Qt Basic control
    id: root
    property string variant: "default"  // Variants match shadcn naming
    property string size: "default"     // Size variants

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.radius
        color: { /* variant-based color logic */ }
        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    contentItem: Text {
        color: { /* variant-based text color */ }
        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
```

**VN:** Tất cả Flat* component theo mẫu shadcn/radix: kế thừa Qt Basic control, có `variant` property, dùng `Theme.*` tokens, animation trên mọi `color` change.

### 5.5 Variant Naming / Đặt Tên Variant

Follows shadcn convention exactly:

| Variant | Usage / Sử dụng |
|---|---|
| `"default"` | Primary action / Hành động chính |
| `"secondary"` | Secondary action / Hành động phụ |
| `"outline"` | Bordered, transparent background / Có viền, nền trong suốt |
| `"ghost"` | No border, transparent until hover / Không viền, trong suốt đến khi hover |
| `"destructive"` | Delete/danger actions / Hành động xóa/nguy hiểm |
| `"link"` | Text-only, looks like a link / Chỉ text, trông giống link |

Toast variants: `"default"`, `"success"`, `"destructive"`, `"warning"`

### 5.6 Accessing Backend from QML / Truy cập Backend từ QML

```qml
// ✅ CORRECT: use context properties directly
connectionManager.activeIndex = index
databaseService.connect(dbType, connStr)
var res = databaseService.executeQuery(query, resultModel)
schemaService.refresh(databaseService)
tabManager.addTab("Query", "SELECT 1")
Theme.toggleTheme()
root.toast("message", "success")    // root = ApplicationWindow

// ❌ WRONG: never import C++ types, never create service instances in QML
// ❌ WRONG: never put database logic in QML
// ❌ WRONG: never hardcode colors
```

**VN:** QML gọi backend thông qua context properties đã expose trong main.cpp. KHÔNG import kiểu C++, KHÔNG tạo instance dịch vụ trong QML, KHÔNG đặt logic CSDL trong QML.

### 5.7 Focus Management / Quản Lý Focus

**EN:**
- Search inputs: set `focus: false` initially, use `forceActiveFocus()` on click
- Escape key clears search and returns focus to parent: `sidebar.forceActiveFocus()`
- NEVER put a background `MouseArea { anchors.fill: parent; z: -10 }` — it blocks ALL child clicks
- Delete/action buttons inside list items must use `z` ordering or be inside the delegate's `RowLayout`

**VN:**
- Input tìm kiếm: `focus: false` ban đầu, dùng `forceActiveFocus()` khi click
- Phím Escape xóa search và trả focus về parent
- KHÔNG BAO GIỜ đặt `MouseArea { z: -10 }` ở background — nó chặn TẤT CẢ click con
- Nút xóa/hành động trong item phải dùng z ordering hoặc nằm trong `RowLayout`

---

## 6. THEME SYSTEM / HỆ THỐNG THEME

### 6.1 ThemeProvider / Nhà Cung Cấp Theme

**EN:** `ThemeProvider` (exposed as `Theme`) is the SINGLE SOURCE OF TRUTH for all design tokens. It supports dark and light mode, toggled via `Theme.toggleTheme()`. Saved to QSettings.

**VN:** `ThemeProvider` (expose là `Theme`) là NGUỒN SỰ THẬT DUY NHẤT cho tất cả token thiết kế. Hỗ trợ chế độ tối/sáng, chuyển đổi qua `Theme.toggleTheme()`. Lưu vào QSettings.

### 6.2 Color Tokens / Token Màu

**Primary palette / Bảng màu chính:**

| Token | Dark | Light | Usage / Sử dụng |
|---|---|---|---|
| `Theme.bg` | `#09090b` | `#ffffff` | Main background / Nền chính |
| `Theme.bgSidebar` | `#0c0c0e` | `#fafafa` | Sidebar background / Nền sidebar |
| `Theme.bgElevated` | `#111113` | `#ffffff` | Elevated areas (toolbar, tab bar) |
| `Theme.bgSurface` | `#18181b` | `#f4f4f5` | Cards, inputs, surfaces |
| `Theme.bgHover` | `#1c1c1f` | `#f0f0f1` | Hover state / Trạng thái hover |
| `Theme.bgActive` | `#222225` | `#e4e4e7` | Active/pressed state |
| `Theme.fg` | `#fafafa` | `#09090b` | Primary text / Text chính |
| `Theme.fgMuted` | `#71717a` | `#71717a` | Secondary text / Text phụ |
| `Theme.fgDim` | `#52525b` | `#a1a1aa` | Tertiary/hint text |
| `Theme.border` | `#27272a` | `#e4e4e7` | Default borders / Viền mặc định |
| `Theme.borderLight` | `#3f3f46` | `#d4d4d8` | Light borders |
| `Theme.borderFocus` | `#6366f1` | `#6366f1` | Focus ring color |
| `Theme.accent` | `#6366f1` | `#6366f1` | Accent/brand color (indigo) |
| `Theme.accentHover` | `#818cf8` | `#4f46e5` | Accent hover |
| `Theme.success` | `#4ade80` | `#16a34a` | Success indicators |
| `Theme.warning` | `#fbbf24` | `#d97706` | Warning indicators |
| `Theme.error` | `#f87171` | `#dc2626` | Error indicators |
| `Theme.info` | `#60a5fa` | `#2563eb` | Info indicators |

**EN:** NEVER hardcode color values in QML. Always use `Theme.*` tokens. The only exception is `"transparent"` and `"#fff"/"#ffffff"` (for white text on accent backgrounds).

**VN:** KHÔNG BAO GIỜ hardcode giá trị màu trong QML. Luôn dùng token `Theme.*`. Ngoại lệ duy nhất: `"transparent"` và `"#fff"/"#ffffff"` (cho text trắng trên nền accent).

### 6.3 Backward Compatibility Aliases / Alias Tương Thích Ngược

The ThemeProvider exposes shadcn-compatible aliases for Flat* controls:

| Alias | Maps to | Used by |
|---|---|---|
| `Theme.background` | `Theme.bg` | FlatButton, FlatDialog |
| `Theme.foreground` | `Theme.fg` | FlatButton, FlatInput |
| `Theme.primary` | `Theme.accent` | FlatButton default variant |
| `Theme.primaryForeground` | `#ffffff` | FlatButton default text |
| `Theme.secondary` | `Theme.bgSurface` | FlatButton secondary variant |
| `Theme.muted` | `Theme.bgSurface` | FlatButton ghost variant |
| `Theme.mutedForeground` | `Theme.fgMuted` | Placeholder text |
| `Theme.card` | `Theme.bgElevated` | FlatCard |
| `Theme.popover` | `Theme.bgElevated` | FlatToast, FlatPopover |
| `Theme.destructive` | `Theme.error` | FlatButton destructive |
| `Theme.input` | `Theme.borderLight` | FlatInput borders |
| `Theme.ring` | `Theme.borderFocus` | Focus ring |

**EN:** New view code (Sidebar, SchemaTree, etc.) should use the PRIMARY tokens (`Theme.bg`, `Theme.fg`, `Theme.bgHover`). Flat* components may use EITHER primary or alias tokens. Do NOT mix within a single component.

**VN:** Code view mới dùng CÁC TOKEN CHÍNH. Flat* component có thể dùng CẢ HAI. KHÔNG trộn lẫn trong cùng một component.

### 6.4 Spacing Tokens / Token Khoảng Cách

| Token | Value | Usage |
|---|---|---|
| `Theme.s2` | 2px | Minimal spacing |
| `Theme.s4` | 4px | Tight spacing |
| `Theme.s6` | 6px | Small spacing |
| `Theme.s8` | 8px | Default compact spacing |
| `Theme.s12` | 12px | Standard spacing |
| `Theme.s16` | 16px | Comfortable spacing |
| `Theme.s20` | 20px | Large spacing |
| `Theme.s24` | 24px | Section spacing |

### 6.5 Radius Tokens / Token Bo Góc

| Token | Value | Usage |
|---|---|---|
| `Theme.r4` | 4px | Small elements (badges, small buttons) |
| `Theme.r6` | 6px | Default (buttons, inputs) |
| `Theme.r8` | 8px | Medium (cards, panels) |
| `Theme.r12` | 12px | Large (dialogs, modals) |
| `Theme.rFull` | 9999px | Pill shape (status indicators) |

### 6.6 Typography / Kiểu Chữ

| Token | Value | Usage |
|---|---|---|
| `Theme.sans` | "Segoe UI" | Body text, UI labels |
| `Theme.mono` | "Cascadia Code" | Code, query editor, data values |
| `Theme.t11` | 11px | Smallest text (line numbers) |
| `Theme.t12` | 12px | Small text (labels, badges) |
| `Theme.t13` | 13px | Default body text |
| `Theme.t14` | 14px | Medium text (headers) |
| `Theme.t16` | 16px | Large text (section titles) |
| `Theme.t20` | 20px | XL text |
| `Theme.t24` | 24px | XXL text |

### 6.7 Animation Timing / Thời Gian Animation

| Token | Value | Usage |
|---|---|---|
| `Theme.fast` | 80ms | Hover color changes, micro-interactions |
| `Theme.normal` | 140ms | Standard transitions |
| `Theme.slow` | 220ms | Layout animations, slide in/out |

**EN:** Every `color` change MUST have a `Behavior on color { ColorAnimation { duration: Theme.fast } }`. Layout animations use `Theme.slow` with `Easing.OutCubic`.

**VN:** Mỗi thay đổi `color` PHẢI có `Behavior on color { ColorAnimation }`. Animation layout dùng `Theme.slow` với `Easing.OutCubic`.

---

## 7. UI/UX DESIGN RULES / QUY TẮC THIẾT KẾ UI/UX

### 7.1 Design Language / Ngôn Ngữ Thiết Kế

**EN:** The app follows **Vercel/shadcn design language**: minimal, monochrome, subtle borders, muted colors, rare accent pops. Think Next.js dashboard, not Material Design.

**VN:** App theo **ngôn ngữ thiết kế Vercel/shadcn**: tối giản, đơn sắc, viền nhẹ, màu muted, hiếm khi dùng accent. Nghĩ đến Next.js dashboard, không phải Material Design.

### 7.2 UI Hierarchy Rules / Quy Tắc Phân Cấp UI

1. **Text color hierarchy / Phân cấp màu text:**
   - Primary content: `Theme.fg`
   - Secondary/labels: `Theme.fgMuted`
   - Hints/disabled: `Theme.fgDim`

2. **Background elevation / Độ cao nền:**
   - Base: `Theme.bg`
   - Sidebar: `Theme.bgSidebar`
   - Toolbar/elevated: `Theme.bgElevated`
   - Card/surface: `Theme.bgSurface`
   - Hover: `Theme.bgHover`
   - Active/pressed: `Theme.bgActive`

3. **Borders: / Viền:**
   - Always 1px, never 2px
   - Default: `Theme.border`
   - Focus: `Theme.borderFocus` (accent color)
   - Separators use `Theme.border` with opacity if needed

### 7.3 Interactive Element Patterns / Mẫu Phần Tử Tương Tác

```qml
// Standard clickable element pattern / Mẫu element click được
Rectangle {
    width: 28; height: 28; radius: 6
    color: _ma.containsMouse ? Theme.bgHover : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    Text { anchors.centerIn: parent; text: "×"; color: Theme.fgMuted }

    MouseArea {
        id: _ma; anchors.fill: parent
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: { /* action */ }
    }
}
```

### 7.4 Section Headers / Tiêu Đề Mục

```qml
Text {
    text: "SECTION NAME"
    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
    font.letterSpacing: 1.0; color: Theme.fgDim; opacity: 0.7
}
```

### 7.5 Status Indicators / Chỉ Báo Trạng Thái

- Connected: small green dot (`Theme.success`, 6-7px circle)
- Disconnected: `Theme.fgDim` with opacity
- Active item: left accent bar (3px wide, `Theme.accent`)
- Error: `Theme.error` dot

### 7.6 Layout Constants / Hằng Số Layout

| Element | Value |
|---|---|
| Sidebar width | 252px (collapsible to 0) |
| Tab bar height | 38px |
| Status bar height | 24px |
| Toolbar height | 38px |
| Connection item height | 38px |
| Schema tree item height | 26-28px |
| Minimum window | 960×640 |
| Default window | 1280×800 |

---

## 8. BUILD SYSTEM / HỆ THỐNG BUILD

### 8.1 CMake Rules / Quy Tắc CMake

- CMake minimum version: 3.16
- Generator: MinGW Makefiles (Windows), Ninja (Linux/macOS)
- Qt path: `CMAKE_PREFIX_PATH="C:/Qt/6.10.2/mingw_64"`
- Core engine: `tablemax_core` static library
- Each plugin: separate `SHARED` library
- Main app: `tablemax` executable via `qt_add_executable`

### 8.2 Plugin CMake Pattern / Mẫu CMake Plugin

```cmake
add_library(<name> SHARED plugins/<name>/<name>_plugin.cpp)
target_include_directories(<name> PRIVATE core/include)
target_link_libraries(<name> PRIVATE <driver_lib>)
if(WIN32)
    set_target_properties(<name> PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
```

### 8.3 Conditional Plugin Building / Build Plugin Có Điều Kiện

**EN:** If a database driver is not installed, the plugin is DISABLED with a warning, NOT an error. The build must always succeed for available plugins.

**VN:** Nếu driver CSDL chưa cài, plugin bị TẮT với cảnh báo, KHÔNG phải lỗi. Build phải luôn thành công cho các plugin có sẵn.

### 8.4 QML Module / Module QML

All QML files are registered via `qt_add_qml_module` with:
- URI: `TableMax`
- VERSION: `1.0`
- All `.qml` files listed under `QML_FILES`
- All `.h` service files listed under `SOURCES`
- All `.svg` icons listed under `RESOURCES`

---

## 9. KEYBOARD SHORTCUTS / PHÍM TẮT

| Shortcut | Action / Hành động |
|---|---|
| `Ctrl+N` | New tab / Tab mới |
| `Ctrl+W` | Close tab / Đóng tab |
| `Ctrl+B` | Toggle sidebar / Ẩn/hiện sidebar |
| `Ctrl+T` | Toggle theme / Chuyển theme |
| `Ctrl+Enter` | Execute query / Chạy truy vấn |
| `Escape` | Clear search / Xóa tìm kiếm |
| `/` | Focus search (planned) / Focus tìm kiếm (dự kiến) |

---

## 10. PERFORMANCE TARGETS / MỤC TIÊU HIỆU NĂNG

| Metric / Chỉ số | Target / Mục tiêu |
|---|---|
| Startup RAM | 15–30 MB |
| Startup time | < 500ms |
| App binary | < 30 MB |
| Scroll 10M rows | 60fps |
| Query execution | Native driver speed / Tốc độ driver gốc |

---

## 11. COMMON MISTAKES TO AVOID / LỖI THƯỜNG GẶP CẦN TRÁNH

| ❌ Don't / Không | ✅ Do / Nên |
|---|---|
| Hardcode colors (`"#ff0000"`) | Use `Theme.error` |
| Use `QtQuick.Controls` (Material) | Use `QtQuick.Controls.Basic` |
| Put DB logic in QML | Use Q_INVOKABLE C++ methods |
| Create full-page MouseArea with z:-10 | Handle focus in individual handlers |
| Use `console.log` for execution | Call `databaseService.executeQuery()` |
| Load all rows at once | Use `IResultStream::next_chunk(500)` |
| Put Qt includes in core/ files | Keep core/ pure C++ |
| Use `.cpp` for Qt services | Keep them header-only |
| Nest QML directories | Keep `qml/` flat |
| Forget `WINDOWS_EXPORT_ALL_SYMBOLS` | Set it ON for all plugin targets |
| Forget Windows `byte` fix | Add `#define byte win_byte_override` before Windows headers |

---

## 12. NAMING CONVENTIONS SUMMARY / TÓM TẮT QUY ƯỚC ĐẶT TÊN

| Item | Convention | Example |
|---|---|---|
| C++ classes | PascalCase | `DatabaseService`, `MongoPlugin` |
| C++ member vars | trailing `_` | `connId_`, `error_`, `client_` |
| C++ methods | camelCase (Qt) or snake_case (core) | `executeQuery()`, `db_type()` |
| QML files | PascalCase.qml | `Sidebar.qml`, `FlatButton.qml` |
| QML properties | camelCase | `showSidebar`, `dbTypeIdx` |
| QML internal IDs | underscore prefix | `_search`, `_rowMa`, `_ctx` |
| Context properties | camelCase | `databaseService`, `connectionManager` |
| db_type strings | lowercase | `"postgres"`, `"mongodb"` |
| SVG icon files | lowercase.svg | `postgres.svg`, `redis.svg` |
| Plugin DLLs | lib<name>.dll | `libsqlite.dll`, `libmongo.dll` |
| Namespace | tablemax | `namespace tablemax { }` |
