import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Omarchy Retro Arcade Popup Window (OutRun 3D Racer, Chrome Dino, & 3D DOOM).
Panel {
  id: root
  moduleName: "io.github.oppenheimer-rick.omarchy-racer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Active Game: "racer" (default), "dino", or "doom"
  property string currentGame: "racer"
  property bool isFullscreen: false

  // Dynamic Viewport Size: Compact 380x320 popup or F11 Fullscreen
  readonly property int targetWidth: isFullscreen ? (root.bar && root.bar.screen ? root.bar.screen.width : 1280) : Style.space(380)
  readonly property int targetHeight: isFullscreen ? (root.bar && root.bar.screen ? (root.bar.screen.height - 40) : 800) : Style.space(320)

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function toggleFullscreen() {
    root.isFullscreen = !root.isFullscreen
  }

  function switchGame() {
    if (root.currentGame === "racer") {
      root.currentGame = "dino"
    } else if (root.currentGame === "dino") {
      root.currentGame = "doom"
    } else {
      root.currentGame = "racer"
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    padding: 0
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.targetWidth)
    contentHeight: panel.fittedContentHeight(root.targetHeight)

    Behavior on contentWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on contentHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Keys.onPressed: function(event) {
        // Fullscreen Toggle: F11
        if (event.key === Qt.Key_F11) {
          root.toggleFullscreen()
          event.accepted = true
          return
        }

        // Quick switch shortcut: Tab or G cycles between Racer, Dino, and DOOM
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_G) {
          root.switchGame()
          event.accepted = true
          return
        }

        if (root.currentGame === "racer" && racerLoader.item) {
          if (racerLoader.item.handleKeyPress(event)) {
            event.accepted = true
            return
          }
        } else if (root.currentGame === "dino" && dinoLoader.item) {
          if (dinoLoader.item.handleKeyPress(event)) {
            event.accepted = true
            return
          }
        } else if (root.currentGame === "doom" && doomLoader.item) {
          if (doomLoader.item.handleKeyPress(event)) {
            event.accepted = true
            return
          }
        }
      }

      Keys.onReleased: function(event) {
        if (root.currentGame === "racer" && racerLoader.item) {
          if (racerLoader.item.handleKeyRelease(event)) {
            event.accepted = true
          }
        } else if (root.currentGame === "dino" && dinoLoader.item) {
          if (dinoLoader.item.handleKeyRelease(event)) {
            event.accepted = true
          }
        } else if (root.currentGame === "doom" && doomLoader.item) {
          if (doomLoader.item.handleKeyRelease(event)) {
            event.accepted = true
          }
        }
      }

      // Edge-to-edge game canvas (zero extra text or headers)
      Rectangle {
        anchors.fill: parent
        radius: root.isFullscreen ? 0 : (Style.cornerRadius > 0 ? Style.cornerRadius : 6)
        color: root.currentGame === "dino" ? "#f7f7f7" : "#000000"
        clip: true

        Loader {
          id: racerLoader
          anchors.fill: parent
          active: root.currentGame === "racer"
          visible: active
          sourceComponent: RacerGame {}
        }

        Loader {
          id: dinoLoader
          anchors.fill: parent
          active: root.currentGame === "dino"
          visible: active
          sourceComponent: DinoGame {}
        }

        Loader {
          id: doomLoader
          anchors.fill: parent
          active: root.currentGame === "doom"
          visible: active
          sourceComponent: DoomGame {}
        }
      }
    }
  }
}
