# Omarchy In-Bar Gaming Architecture & Vision Specification

> **Project Codename**: `omarchy-arcade-popup`  
> **Target Runtime**: Omarchy Quattro / Quickshell (Qt 6 QML + Pure JavaScript)  
> **Design Reference**: `omarchy-screen-time` (`BarWidget.qml`, `Panel.qml`, `Model.js`) & Native Omarchy UI System

---

## 1. Executive Vision & Philosophy

Modern desktop bars are typically static displays of battery percentages and clocks. This plugin transforms the Omarchy top bar into an **instant, zero-latency gaming console popup**.

With a single click on the bar's gaming icon, a sleek, theme-integrated popup window opens directly beneath the bar widget. The game is pre-booted, responsive to keyboard/gamepad inputs, maintains zero idle RAM footprint, and seamlessly pauses when closed or unfocused.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Omarchy Top Bar:  [ 🍙 ] ... [ 🎮 Play ] [ 1h 59m ] [ ☁ ] [ 100% ]          │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      ▼
             ┌────────────────────────────────────────────────┐
             │ 🕹️ OMARCHY ARCADE            HI: 04290  [ 🔊 ] │
             ├────────────────────────────────────────────────┤
             │                                                │
             │     ☁                  ☁                       │
             │                                                │
             │           🦖                                   │
             │     ───────────────── 🌵 ────── 🌵 ─────────   │
             │                                                │
             ├────────────────────────────────────────────────┤
             │ [ ▶ PLAY (SPACE) ]  [ 🎮 RETRO VAULT ]  [ ⚙ ]  │
             │ Controls: SPACE/↑ to Jump • ↓ to Duck • ESC    │
             └────────────────────────────────────────────────┘
```

---

## 2. Technical Architecture & Component Hierarchy

To guarantee high performance, modularity, and strict adherence to Omarchy standards, we follow the exact structural blueprint of `omarchy-screen-time`:

```
omarchy-game-popup/
├── manifest.json         # Schema v1 manifest declaring "bar-widget"
├── BarWidget.qml         # Bar icon button, click handlers, IPC binding
├── Panel.qml             # Popup window using KeyboardPanel & PanelKeyCatcher
├── GameCanvas.qml        # 60 FPS QML Canvas 2D viewport
├── GameEngine.js         # Pure JS state machine, physics, obstacle collision
├── Sprites.js            # Sprite sheet definitions & animation frames
├── store.sh              # Local high-score and state persistence helper
├── test/
│   └── game.test.mjs     # 100% pure JS unit test suite executed via Node.js
├── assets/               # Pixel-art spritesheets & sound effects
├── README.md             # Standard community marketplace documentation
└── LICENSE               # MIT License
```

---

## 3. Two-Stage Roadmap

### Phase 1: Zero-Dependency Embedded Engine (Prototyping)
- **Engine**: Pure JavaScript & QML 2D Canvas rendering based on the world-renowned Chrome Dino / Retro Runner architecture.
- **Physics & Mechanics**:
  - Velocity, gravity, jump impulse, variable jump height.
  - Multi-tiered obstacle spawning (cacti, pterodactyls/drones, night-mode transitions).
  - Acceleration curves (speed gradually increases with distance).
  - Pixel-perfect AABB collision detection.
- **Omarchy Theme Reactive**:
  - Automatically samples `bar.foreground`, `bar.background`, and `Color.accent` so the game looks native to whatever Omarchy palette is active (Catppuccin, Tokyo Night, Gruvbox, etc.).

### Phase 2: Curated RetroArch / Libretro & Homebrew Vault
- **Concept**: An expandable "Retro Vault" drawer inside the popup panel.
- **Features**:
  - Detection of installed libretro cores (`play_libretro.so` for PS2, `mgba` for GBA, `snes9x` for SNES).
  - 1-click launch for pre-configured classic homebrew ROMs and open-source games.
  - Seamless Hyprland floating window orchestration.

---

## 4. Specific UX & Interaction Requirements

1. **Top Bar Widget (`BarWidget.qml`)**:
   - Distinct, crisp glyph (`🎮` or themed gaming controller icon).
   - Shows a subtle indicator bar or live mini-badge when a game session is active/paused.
   - Middle-click or right-click to quick-reset or open settings.

2. **Popup Panel (`Panel.qml`)**:
   - Anchored directly to the bar button via `KeyboardPanel`.
   - Bounded by the signature Omarchy accent border (1px solid accent).
   - Captures keyboard inputs cleanly with `PanelKeyCatcher` without leaking keystrokes to background windows.
   - Escape key cleanly pauses the game and closes the popup.

3. **Performance Budget**:
   - **RAM**: < 15 MB in memory.
   - **CPU**: 0.0% CPU when panel is closed (Timer suspended).
   - **Render Target**: Rock-solid 60 FPS during gameplay.

---

## 5. Next Execution Steps

1. Implement `manifest.json` conforming to `omarchy plugin validate`.
2. Port the iconic Chrome Dino runner into decoupled `GameEngine.js` with pure mathematical state updates.
3. Build `test/game.test.mjs` to verify jump physics, obstacle generation, score accumulation, and collision.
4. Construct `BarWidget.qml`, `Panel.qml`, and `GameCanvas.qml` to bring the arcade popup alive inside Quickshell.
