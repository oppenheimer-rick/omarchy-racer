import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Omarchy Retro Arcade Popup Window (OutRun 3D Racer, Chrome Dino, & DOOM Launcher).
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
  property string detectedWad: ""
  readonly property bool isDoomRunning: doomProcess.running

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

  // Auto-create doomretro.cfg with windowed 960x600 defaults
  Process {
    id: configSetup
    command: ["bash", "-c",
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
      "fi; echo ready"]
  }

  // Auto-detect WAD files across standard Linux paths
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

  // Security Audited DOOM Process Execution
  Process {
    id: doomProcess
  }

  function launchDoom() {
    if (doomProcess.running) {
      doomProcess.signal(9)
      return
    }

    var binary = "doomretro"
    var cmd = [binary]
    if (root.detectedWad && root.detectedWad.length > 0) {
      cmd.push("-iwad", root.detectedWad)
    }

    doomProcess.command = cmd
    doomProcess.running = true
  }

  Component.onCompleted: {
    configSetup.running = true
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

    Behavior on contentWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on contentHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F11) {
          root.toggleFullscreen()
          event.accepted = true
          return
        }

        // Quick switch shortcut: Tab or G cycles between games
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

        // Custom DOOM Artwork Launch Portal
        Item {
          id: doomView
          anchors.fill: parent
          visible: root.currentGame === "doom"

          Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("Assets/Doom/doom1.jpg")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }

          // Atmospheric Dark Vignette Gradient
          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop { position: 0.0; color: "#40000000" }
              GradientStop { position: 0.55; color: "#66000000" }
              GradientStop { position: 1.0; color: "#d9000000" }
            }
          }

          // Single Epic DOOM Launch Button
          MouseArea {
            id: btnMouse
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220
            height: 48
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.launchDoom()

            Rectangle {
              id: doomBtn
              anchors.fill: parent
              radius: 8
              color: root.isDoomRunning ? "#550000" : (btnMouse.containsMouse ? "#cc1111" : "#990000")
              border.color: root.isDoomRunning ? "#ff5555" : (btnMouse.containsMouse ? "#ffcc00" : "#ff3333")
              border.width: 2

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.isDoomRunning ? "🔥" : "💀"
                  font.pixelSize: 18
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.isDoomRunning ? "KILL DOOM" : "RIP AND TEAR"
                  font.family: Style.font.family
                  font.pixelSize: 15
                  font.bold: true
                  color: "#ffffff"
                }
              }
            }
          }
        }
      }
    }
  }
}
