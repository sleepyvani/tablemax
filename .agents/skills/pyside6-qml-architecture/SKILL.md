---
name: pyside6-qml-architecture
description: Use this skill when creating a new PySide6 + QML desktop application with MVC architecture, setting up project structure, implementing the application bootstrap / DI container, or understanding how the MVC layers connect. Covers project scaffolding, entry points, singleton application class, service locator, signal registry, and lifecycle management.
---

# PySide6 QML MVC Architecture

Desktop GUI applications in this workspace use **Python + PySide6** with **QML** files for the view layer, following a strict Model-View-Controller (MVC) architecture. This skill documents the canonical project structure, bootstrap pattern, and layer responsibilities derived from the `ds_pas/` application.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│           View Layer (QML files)        │
│  Declarative UI, data binding, signals  │
└──────────────────┬──────────────────────┘
                   │ Properties, Signals, Slots
┌──────────────────▼──────────────────────┐
│         Python-QML Bridge               │
│  QObject subclasses exposed to QML      │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Controller Layer              │
│  Coordinate models & services           │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Model Layer                   │
│  Data structures, validation, signals   │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Services Layer                │
│  Database, files, network, broker       │
└─────────────────────────────────────────┘
```

## Project Structure

```
my_app/
├── app.py                    # Bootstrap & DI container (singleton)
├── __init__.py               # Package init
├── __main__.py               # Entry point: python -m my_app
├── controllers/
│   ├── __init__.py
│   ├── base.py               # BaseController with view registry
│   └── *_controller.py       # Domain controllers (job, settings, etc.)
├── models/
│   ├── __init__.py
│   ├── base.py               # BaseModel with property_changed signal
│   ├── state.py              # ApplicationState singleton
│   └── *.py                  # Domain models (job, piece, customer, etc.)
├── views/
│   ├── __init__.py
│   ├── bridge.py             # QObject bridge classes exposed to QML
│   ├── main_window.py        # Main window setup (QQmlApplicationEngine)
│   └── components/           # Reusable Python view helpers
├── services/
│   ├── __init__.py
│   ├── database/             # Repository pattern for data access
│   └── *.py                  # External interaction services
├── resources/
│   ├── qml/
│   │   ├── main.qml          # Root QML component
│   │   ├── components/       # Reusable QML components
│   │   ├── pages/            # Page-level QML views
│   │   └── styles/           # Theme and style definitions
│   ├── icons/                # SVG/PNG icons
│   └── qml.qrc              # Qt resource file (optional)
├── utils/
│   ├── __init__.py
│   ├── signals.py            # Central SignalRegistry
│   ├── types.py              # Type aliases, protocols, ServiceLocator
│   └── paths.py              # Path resolution helpers
└── tests/
    └── *.py
```

## Layer Responsibilities

| Component | Responsibility | MUST NOT |
|-----------|----------------|----------|
| **Model** | Data structures, validation, serialization, `property_changed` signals | Touch UI, call services, reference QML |
| **View (QML)** | Declarative UI layout, data binding to bridge properties, user input capture | Contain business logic, call services directly |
| **Bridge** | QObject subclasses that expose model data and controller actions to QML | Contain business logic, directly manipulate QML |
| **Controller** | Coordinate models & services, handle actions, emit signals | Manipulate UI directly, import QML types |
| **Service** | Database queries, file I/O, network calls, IPC | Reference models, views, or controllers |

## Application Bootstrap (DI Container)

The application class is a singleton that wires all layers together:

```python
"""app.py — Bootstrap & DI container."""
import sys
import logging
from typing import Any
from pathlib import Path

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, QUrl

from my_app.utils.signals import SignalRegistry, get_signal_registry
from my_app.utils.types import ServiceLocator

logger = logging.getLogger(__name__)


class MyApplication:
    """Singleton application with DI container."""
    
    _instance: "MyApplication | None" = None

    def __new__(cls, dev_mode: bool = False) -> "MyApplication":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self, dev_mode: bool = False) -> None:
        if self._initialized:
            return
        self._initialized = True
        self._dev_mode = dev_mode
        self._qt_app: QApplication | None = None
        self._engine: QQmlApplicationEngine | None = None
        self._services: dict[str, Any] = {}
        self._controllers: dict[str, Any] = {}
        self._signals = get_signal_registry()
        self._service_locator = ServiceLocator()

    def _register_services(self) -> None:
        """Create and register all service instances."""
        # self._services["db"] = DatabaseService(...)
        pass

    def _register_controllers(self) -> None:
        """Create controllers with injected dependencies."""
        # self._controllers["job"] = JobController(
        #     signals=self._signals,
        #     repository=self._services["db"],
        # )
        pass

    def _register_qml_types(self) -> None:
        """Register Python bridge objects as QML context properties."""
        ctx = self._engine.rootContext()
        # ctx.setContextProperty("jobBridge", self._bridges["job"])
        pass

    def run(self) -> int:
        self._qt_app = QApplication(sys.argv)
        self._register_services()
        self._register_controllers()

        self._engine = QQmlApplicationEngine()
        self._register_qml_types()

        qml_path = Path(__file__).parent / "resources" / "qml" / "main.qml"
        self._engine.load(QUrl.fromLocalFile(str(qml_path)))

        if not self._engine.rootObjects():
            return -1

        return self._qt_app.exec()
```

## Entry Point

```python
"""__main__.py"""
import sys
from my_app.app import MyApplication

def main():
    app = MyApplication(dev_mode="--dev" in sys.argv)
    sys.exit(app.run())

if __name__ == "__main__":
    main()
```

## ServiceLocator Pattern

```python
"""utils/types.py — Type aliases, protocols, and DI container."""
from typing import Any, Protocol, TypeVar, runtime_checkable

T = TypeVar("T")

@runtime_checkable
class IController(Protocol):
    def initialize(self) -> None: ...
    def cleanup(self) -> None: ...

@runtime_checkable
class IService(Protocol):
    def initialize(self) -> None: ...
    def shutdown(self) -> None: ...

class ServiceLocator:
    """Lightweight DI container for service instances."""
    _instance: "ServiceLocator | None" = None

    def __new__(cls) -> "ServiceLocator":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._services = {}
        return cls._instance

    def register(self, name: str, service: Any) -> None:
        self._services[name] = service

    def get(self, name: str) -> Any:
        if name not in self._services:
            raise KeyError(f"Service '{name}' not registered")
        return self._services[name]

    def has(self, name: str) -> bool:
        return name in self._services
```

## Signal Flow

```
User Action (QML)
       ↓
  QML emits signal / calls slot on Bridge
       ↓
  Bridge delegates to Controller
       ↓
  Controller calls Service
       ↓
  Service returns result
       ↓
  Controller updates Model
       ↓
  Model emits property_changed
       ↓
  Bridge property notifies QML (via NOTIFY)
       ↓
  QML binding automatically updates UI
```

## Key Design Rules

1. **QML files are declarative only** — no JavaScript business logic, no direct service calls
2. **Python bridge objects** are the sole interface between QML and the Python backend
3. **Controllers never import QML types** — they operate through bridge signals/properties
4. **Models are pure data** — no UI imports, no service calls
5. **Services are stateless workers** — no model references, no UI knowledge
6. **All cross-layer communication** flows through the `SignalRegistry` or Qt property bindings
7. **Singletons** (`Application`, `SignalRegistry`, `ServiceLocator`, `ApplicationState`) use the `__new__` pattern for thread-safe reuse

## File Size Guidelines

- Keep files focused on a single responsibility
- Split files exceeding ~300-400 lines into submodules
- Extract reusable QML components into `resources/qml/components/`
- Group related controllers/services by domain (e.g., `controllers/job_controller.py`)

## References

- [PySide6 QML Integration](https://doc.qt.io/qtforpython-6/tutorials/qmlintegration/qmlintegration.html)
- [Qt QML Documentation](https://doc.qt.io/qt-6/qtqml-index.html)
- [PySide6 Documentation](https://doc.qt.io/qtforpython-6/)
