import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Omarchy Dino Popup Window.
Panel {
  id: root
  moduleName: "io.github.oppenheimer-rick.omarchy-dino"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Aspect ratio configuration: "square" (380x320) or "banner" (520x160)
  property string aspectRatio: "square"

  readonly property int targetWidth: aspectRatio === "square" ? Style.space(380) : Style.space(520)
  readonly property int targetHeight: aspectRatio === "square" ? Style.space(320) : Style.space(160)

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

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
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
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Keys.onPressed: function(event) {
        if (dinoGame.handleKeyPress(event)) {
          event.accepted = true
        }
      }

      Keys.onReleased: function(event) {
        if (dinoGame.handleKeyRelease(event)) {
          event.accepted = true
        }
      }

      // Edge-to-edge game canvas
      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 6
        color: "#f7f7f7"
        clip: true

        DinoGame {
          id: dinoGame
          anchors.fill: parent
        }
      }
    }
  }
}
