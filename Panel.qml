import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Omarchy Retro Arcade Popup Window (OutRun 3D Racer & Chrome Dino).
Panel {
  id: root
  moduleName: "io.github.oppenheimer-rick.omarchy-racer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Active Game: "racer" (default) or "dino"
  property string currentGame: "racer"

  // Aspect ratio configuration: clean 380x320 square card
  readonly property int targetWidth: Style.space(380)
  readonly property int targetHeight: Style.space(320)

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

  function switchGame() {
    if (root.currentGame === "racer") {
      root.currentGame = "dino"
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

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Keys.onPressed: function(event) {
        // Quick switch shortcut: Tab or G toggles between OutRun Racer and Dino Runner
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
        }
      }

      // Edge-to-edge game canvas (zero extra text or headers)
      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 6
        color: root.currentGame === "racer" ? "#000000" : "#f7f7f7"
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
      }
    }
  }
}
