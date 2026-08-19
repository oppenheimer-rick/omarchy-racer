# Omarchy Arcade

> 🏎️ **Zero-latency in-bar retro arcade hub (OutRun 3D Racer & Chrome Dino) for [Omarchy](https://omarchy.org).**

*<span style="color: #888888;">[📖 Read the Full Engineering & Architecture Documentation](DOCUMENTATION.md) →</span>*

---

<p align="center">
  <img src="docs/videos/showcase.gif" alt="Omarchy Arcade Gameplay Showcase" width="100%" />
</p>

---

## 📦 Install

```bash
omarchy plugin add https://github.com/oppenheimer-rick/omarchy-dino.git --enable
```

> *Omarchy clones the repository, validates its manifest and components locally, and enables the plugin instantly.*

---

## 🕹️ Included Games & Switching

You can switch between games instantly at any time without menus or extra screen clutter by pressing **`Tab`** or **`G`**:

1. **🏎️ OutRun 3D Road Racer** *(Default)*: Authentic pseudo-3D road racer with curves, hills, parallax sky/mountains, traffic AI, and roadside billboards.
2. **🦖 Chrome Dinosaur Runner**: The classic jump-and-duck endless runner with authentic physics and speed acceleration.

---

## 🎮 Controls

### 🔄 Global Switcher
| Key | Action |
| :--- | :--- |
| **`TAB` / `G`** | **Switch between OutRun Racer & Dino Runner** |
| **`ESC`** | Close popup window |

### 🏎️ OutRun 3D Racer *(Default)*
| Key / Input | Action |
| :--- | :--- |
| **`↑` / `W`** | Accelerate |
| **`↓` / `S`** | Brake / Slow down |
| **`←` `→` / `A` `D`** | Steer Left / Right |
| **`P`** | Pause / Resume |
| **`R`** | Restart Race |

### 🦖 Chrome Dinosaur Runner
| Key / Input | Action |
| :--- | :--- |
| **`SPACE` / `↑` / `W` / Click** | Jump / Start game |
| **`↓` / `S`** | Duck |
| **`P`** | Pause / Resume |
| **`R`** | Restart |

---

## ✨ Features

- **⚡ Zero-Latency Native Execution**: Powered directly by Quickshell's V8 engine and GPU-accelerated Qt Quick Canvas 2D.
- **🎯 Dynamic Square Viewport**: Clean 380×320 square card designed to fit naturally on any monitor resolution.
- **👾 Retro 8-Bit Pixel Bar Icon**: Uses JetBrainsMono Nerd Font Space Invader glyph (`\udb82\udfc9`) with optical centering.
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
