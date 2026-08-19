# Omarchy Dino Runner

> 🦖 **Zero-latency in-bar retro runner game for [Omarchy](https://omarchy.org).**

Play the iconic Chrome Dinosaur runner directly inside your Omarchy status bar. Click the pixel dragon icon or press a shortcut to open an instant 60 FPS popup with zero CPU/RAM background overhead.

---

## 📦 Install

```bash
omarchy plugin add https://github.com/oppenheimer-rick/omarchy-dino.git --enable
```

> *Omarchy clones the repository, validates its manifest and components locally, and enables the plugin instantly.*

---

## 🎮 Controls

| Key / Input | Action |
| :--- | :--- |
| **`SPACE` / `↑` / `W` / Click** | Jump / Start game |
| **`↓` / `S`** | Duck |
| **`P`** | Pause / Resume |
| **`R`** | Restart |
| **`ESC`** | Close popup |

---

## ✨ Features

- **⚡ Zero-Latency Native Execution**: Powered directly by Quickshell's V8 engine and GPU-accelerated Qt Quick scene graph.
- **🎯 Dynamic Square Viewport**: Clean 380×320 square card designed to fit naturally on any monitor resolution.
- **🐉 Pixel Dragon Bar Icon**: Uses JetBrainsMono Nerd Font glyph (`\ueef8` / `fa-dragon`) with optical centering.
- **🛡️ 0% Idle Resource Usage**: Completely sleeps when closed, consuming zero CPU cycles and negligible memory.
- **🎛️ Configurable Bar Placement**: Easily switch between **Right** and **Center** status bar positioning.

---

## ⚙️ Configuration

In your `~/.config/omarchy/shell.json`, position the widget wherever you prefer:

```json
"right": [
  {
    "id": "io.github.oppenheimer-rick.omarchy-dino"
  }
]
```

---

## 🛡️ Security Notice

Third-party unsandboxed code. Automated checks are limited and are not a security audit or guarantee. Verify that the current commit matches the reviewed commit, inspect the source and capabilities, and report suspicious plugins ASAP.

### Listing Checks

| Check | Status |
| :--- | :--- |
| **Compatibility** | Passed |
| **Branch** | `main` |
| **Dependencies** | 0 external binaries (Pure QML + JS) |
| **License** | MIT |

---

## 📄 License

MIT License © 2026 oppenheimer-rick
