import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Omarchy Retro Arcade Popup Window (OutRun 3D Racer, Chrome Dino, & DOOM).
Panel {
  id: root
  moduleName: "io.github.oppenheimer-rick.omarchy-racer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Active Game: "racer" (default), "dino", or "doom"
  property string currentGame: "racer"
  property string detectedWad: ""

  // Clean compact square card aspect ratio
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
    } else if (root.currentGame === "dino") {
      root.currentGame = "doom"
    } else {
      root.currentGame = "racer"
    }
  }

  // WAD auto-detection process
  Process {
    id: wadDetector
    command: ["bash", "-c",
      "for d in ~/Games/doom ~/doom ~/.local/share/doom /usr/share/doom; do " +
      "  for f in \"$d\"/DOOM*.WAD \"$d\"/doom*.wad; do " +
      "    [ -f \"$f\" ] && echo \"$f\" && exit 0; " +
      "  done; " +
      "done; exit 1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var path = String(text || "").trim()
        if (path.length > 0) root.detectedWad = path
      }
    }
  }

  Process {
    id: doomProcess
  }

  function launchDoom() {
    var cmd = ["bash", "-c",
      "CFG=\"$HOME/.config/doomretro/doomretro.cfg\"; " +
      "if [ ! -f \"$CFG\" ]; then " +
      "  mkdir -p \"$(dirname \"$CFG\")\"; " +
      "  cat > \"$CFG\" << 'EOF'\n" +
      "vid_fullscreen                   off\n" +
      "vid_widescreen                   on\n" +
      "vid_borderlesswindow             off\n" +
      "vid_screenresolution             desktop\n" +
      "vid_windowpos                    centered\n" +
      "vid_windowsize                   960x600\n" +
      "r_screensize                     8\n" +
      "EOF\n" +
      "else " +
      "  sed -i 's/^vid_fullscreen\\s\\+on$/vid_fullscreen                   off/' \"$CFG\" 2>/dev/null; " +
      "  sed -i 's/^vid_windowsize\\s\\+.*/vid_windowsize                   960x600/' \"$CFG\" 2>/dev/null; " +
      "fi; " +
      "for b in doomretro chocolate-doom gzdoom prboom-plus; do " +
      "  if command -v $b >/dev/null 2>&1; then " +
      "    if [ -n \"" + root.detectedWad + "\" ]; then exec $b -iwad \"" + root.detectedWad + "\"; " +
      "    else exec $b; fi; " +
      "  fi; " +
      "done; " +
      "notify-send 'DOOM Engine' 'Please install doomretro or chocolate-doom (e.g. sudo pacman -S doomretro)'; exit 1"]
    doomProcess.command = cmd
    doomProcess.running = true
  }

  Component.onCompleted: {
    wadDetector.running = true
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
        } else if (root.currentGame === "doom") {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            root.launchDoom()
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

        // DOOM Gateway Screen
        Item {
          id: doomView
          anchors.fill: parent
          visible: root.currentGame === "doom"

          Rectangle {
            anchors.fill: parent
            color: "#0a0000"

            Column {
              anchors.centerIn: parent
              spacing: 12

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "🔥 DOOM 🔥"
                font.family: Style.font.family
                font.pixelSize: 22
                font.bold: true
                color: "#ff3333"
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.detectedWad.length > 0 ? "WAD: " + root.detectedWad.split("/").pop() : "Scanning for DOOM.WAD..."
                font.family: Style.font.family
                font.pixelSize: 11
                color: "#ffaa44"
              }

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140
                height: 32
                radius: 6
                color: "#aa0000"
                border.color: "#ff4444"
                border.width: 1.5

                Text {
                  anchors.centerIn: parent
                  text: "RIP AND TEAR"
                  font.family: Style.font.family
                  font.pixelSize: 11
                  font.bold: true
                  color: "#ffffff"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.launchDoom()
                }
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press ENTER / SPACE to Launch"
                font.family: Style.font.family
                font.pixelSize: 10
                color: "#888888"
              }
            }
          }
        }
      }
    }
  }
}
