# Omarchy Game Hub Context & Development Guide

## 1. Project Locations & Paths

| Role | Absolute Path | Description |
| :--- | :--- | :--- |
| **Source Workspace** | `/home/dex/bug_hunt/omarchy-screen-time/` | Active development directory & git repository |
| **Live Plugin Deployment** | `/home/dex/.config/omarchy/plugins/vt.screentime/` | Live location scanned and loaded by Omarchy Shell |
| **Shell Configuration** | `/home/dex/.config/omarchy/shell.json` | Stores bar layout (`layout.right`), enabled plugins, and custom parameters |
| **System Shell Runtime** | `/usr/share/omarchy/shell/` | Core Quickshell / Omarchy Quattro shell runtime & shared UI modules |

---

## 2. Quickshell QML Component Caching & Live Reload

> [!IMPORTANT]
> **QML Memory Cache Warning**:  
> Quickshell (`quickshell -n -p /usr/share/omarchy/shell`) compiles and caches QML components in RAM via `Qt.createComponent`.  
> When modifying `.qml` files directly, running `omarchy plugin disable/enable` is not always sufficient to bust the component cache.  
> To guarantee immediate pickup of `.qml` changes:
> ```bash
> pkill -9 quickshell
> ```
> *(Omarchy's background supervisor `omarchy-launch-shell` will automatically respawn the shell in <1 second with a clean cache).*

---

## 3. Key File Architecture & Icon Configuration

```
omarchy-screen-time/
├── manifest.json         # Plugin schema v1 declaring bar-widget kind
├── BarWidget.qml         # Top-bar presentation widget, icon, duration counter, & Panel Loader
├── Panel.qml             # Floating popup window using KeyboardPanel & PanelKeyCatcher
├── Model.js              # Pure JavaScript state, data aggregation, and calculations
├── store.sh              # SQLite3 data store helper for persistence
├── test/
│   └── model.test.mjs    # Node.js unit tests
├── CONTEXT.md            # This context file
├── SPEC.md               # Vision & architecture roadmap for game integration
└── README.md             # Plugin documentation
```

### Icon Locations
- **Bar Icon**: [`BarWidget.qml` Line 73](file:///home/dex/bug_hunt/omarchy-screen-time/BarWidget.qml#L73)
  ```qml
  readonly property string icon: "\uf11b"  // Nerd Font Game Controller glyph ()
  ```
- **Panel Header Icon**: [`Panel.qml` Line 69](file:///home/dex/bug_hunt/omarchy-screen-time/Panel.qml#L69)
  ```qml
  readonly property string icon: "\uf11b"
  ```

---

## 4. Bar & Popup Integration Mechanism

1. **Bar Slot**: `BarWidget.qml` is loaded by `Bar.qml` into the `layout.right` section.
2. **Anchor Linkage**: `BarWidget` instantiates `Panel.qml` inside a hidden `Loader` and passes its `WidgetButton` (`id: button`) as `anchorItem`.
3. **Keyboard Focus**: `KeyboardPanel` inside `Panel.qml` hooks into `PanelKeyCatcher` for capturing inputs (`SPACE`, `Arrows`, `WASD`, `ESC`) without leaking keystrokes to background desktop applications.
4. **IPC Control**:
   ```bash
   omarchy-shell shell toggle vt.screentime
   ```

---

## 5. Development & Sync Workflow

To sync changes made in `/home/dex/bug_hunt/omarchy-screen-time/` to the live plugin:
```bash
cp /home/dex/bug_hunt/omarchy-screen-time/*.qml ~/.config/omarchy/plugins/vt.screentime/
cp /home/dex/bug_hunt/omarchy-screen-time/*.js ~/.config/omarchy/plugins/vt.screentime/
pkill -9 quickshell
```
