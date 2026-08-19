import QtQuick
import "Model.js" as Model

Item {
  id: root

  property var gameState: Model.initGameState()
  readonly property string assetBase: Qt.resolvedUrl("Assets/")

  readonly property real groundY: height - 20

  property int points: 0
  property int highScore: 0
  property bool started: false
  property bool gameOver: false
  property bool paused: false

  property real dinoX: 25
  property real dinoY: groundY - 47
  property real dinoW: 44
  property real dinoH: 47
  property string dinoSource: assetBase + "Dino/DinoStart.png"

  property real trackX1: 0
  property real trackX2: width

  property var obstaclesModel: []
  property var cloudsModel: [
    { x: 180, y: 22 },
    { x: 320, y: 40 }
  ]

  function updateVisuals() {
    root.points = gameState.points || 0
    root.highScore = gameState.highScore || 0
    root.started = gameState.started || false
    root.gameOver = gameState.gameOver || false
    root.paused = gameState.paused || false

    var d = gameState.dino
    root.dinoX = d.x
    root.dinoW = d.duck ? 59 : 44
    root.dinoH = d.duck ? 30 : 47
    root.dinoY = root.groundY - root.dinoH + d.y

    if (d.dead) {
      root.dinoSource = assetBase + "Dino/DinoDead.png"
    } else if (d.jump) {
      root.dinoSource = assetBase + "Dino/DinoJump.png"
    } else if (d.duck) {
      root.dinoSource = assetBase + "Dino/" + (d.stepIndex < 5 ? "DinoDuck1.png" : "DinoDuck2.png")
    } else if (gameState.started) {
      root.dinoSource = assetBase + "Dino/" + (d.stepIndex < 5 ? "DinoRun1.png" : "DinoRun2.png")
    } else {
      root.dinoSource = assetBase + "Dino/DinoStart.png"
    }

    root.trackX1 = -gameState.trackOffset
    root.trackX2 = root.width - gameState.trackOffset
    root.obstaclesModel = gameState.obstacles.slice()
    root.cloudsModel = gameState.clouds.slice()
  }

  function restart() {
    Model.restart(gameState)
    updateVisuals()
  }

  function handleKeyPress(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Up || event.key === Qt.Key_W) {
      Model.jump(gameState)
      updateVisuals()
      return true
    }

    if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
      Model.duck(gameState, true)
      updateVisuals()
      return true
    }

    if (event.key === Qt.Key_P) {
      gameState.paused = !gameState.paused
      updateVisuals()
      return true
    }

    if (event.key === Qt.Key_R) {
      restart()
      return true
    }

    return false
  }

  function handleKeyRelease(event) {
    if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
      Model.duck(gameState, false)
      updateVisuals()
      return true
    }
    return false
  }

  Component.onCompleted: updateVisuals()

  Timer {
    interval: 16 // 60 FPS ultra-smooth refresh
    running: root.visible && root.started && !root.gameOver && !root.paused
    repeat: true
    onTriggered: {
      Model.tick(gameState, root.width > 0 ? root.width : 380, root.groundY)
      root.updateVisuals()
    }
  }

  // Background
  Rectangle {
    anchors.fill: parent
    color: "#f7f7f7"
  }

  // 1. Clouds
  Repeater {
    model: root.cloudsModel
    Image {
      required property var modelData
      x: modelData.x
      y: modelData.y
      width: 46
      height: 14
      source: root.assetBase + "Other/Cloud.png"
      fillMode: Image.Stretch
    }
  }

  // 2. Track Ground
  Image {
    x: root.trackX1
    y: root.groundY
    width: root.width
    height: 14
    source: root.assetBase + "Other/Track.png"
    fillMode: Image.TileHorizontally
  }

  Image {
    x: root.trackX2
    y: root.groundY
    width: root.width
    height: 14
    source: root.assetBase + "Other/Track.png"
    fillMode: Image.TileHorizontally
  }

  // 3. Obstacles
  Repeater {
    model: root.obstaclesModel
    Image {
      required property var modelData
      x: modelData.x
      y: root.groundY - (modelData.kind === "bird" ? modelData.altitude : modelData.height)
      width: modelData.width
      height: modelData.height
      source: {
        if (modelData.kind === "small_cactus") {
          return root.assetBase + "Cactus/SmallCactus" + (modelData.type + 1) + ".png"
        } else if (modelData.kind === "large_cactus") {
          return root.assetBase + "Cactus/LargeCactus" + (modelData.type + 1) + ".png"
        } else if (modelData.kind === "bird") {
          var f = modelData.animIndex < 5 ? "Bird1.png" : "Bird2.png"
          return root.assetBase + "Bird/" + f
        }
        return ""
      }
      fillMode: Image.Stretch
    }
  }

  // 4. Dinosaur
  Image {
    x: root.dinoX
    y: root.dinoY
    width: root.dinoW
    height: root.dinoH
    source: root.dinoSource
    fillMode: Image.Stretch
  }

  // 5. Score
  Text {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 12
    anchors.rightMargin: 16
    text: "HI " + String(root.highScore).padStart(5, '0') + "  " + String(root.points).padStart(5, '0')
    color: "#535353"
    font.bold: true
    font.pixelSize: 13
    font.family: "Monospace"
  }

  // 6. Start Prompt
  Text {
    anchors.centerIn: parent
    visible: !root.started
    text: "PRESS SPACE TO JUMP"
    color: "#535353"
    font.bold: true
    font.pixelSize: 14
    font.family: "Monospace"
  }

  // 7. Game Over Overlay
  Column {
    anchors.centerIn: parent
    visible: root.gameOver
    spacing: 12

    Image {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 191
      height: 16
      source: root.assetBase + "Other/GameOver.png"
      fillMode: Image.PreserveAspectFit
    }

    Image {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 36
      height: 32
      source: root.assetBase + "Other/Reset.png"
      fillMode: Image.PreserveAspectFit

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.restart()
      }
    }
  }

  // Click anywhere to jump / start
  MouseArea {
    anchors.fill: parent
    onClicked: {
      if (root.gameOver || !root.started) {
        root.restart()
      } else {
        Model.jump(root.gameState)
        root.updateVisuals()
      }
    }
  }
}
