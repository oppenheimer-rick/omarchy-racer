import QtQuick
import "AsteroidsModel.js" as Model

Item {
  id: root

  property var gameState: null

  function initGame() {
    gameState = Model.initGameState(width > 0 ? width : 380, height > 0 ? height : 320)
  }

  onWidthChanged: if (!gameState) initGame(); else { gameState.width = width }
  onHeightChanged: if (!gameState) initGame(); else { gameState.height = height }
  Component.onCompleted: initGame()

  function handleKeyPress(event) {
    if (!gameState) return false

    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
      gameState.ship.rot = Model.TURN_SPEED
      return true
    }
    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
      gameState.ship.rot = -Model.TURN_SPEED
      return true
    }
    if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
      gameState.ship.thrusting = true
      return true
    }
    if (event.key === Qt.Key_Space) {
      Model.shootLaser(gameState)
      return true
    }
    if (event.key === Qt.Key_P) {
      gameState.paused = !gameState.paused
      canvas.requestPaint()
      return true
    }
    if (event.key === Qt.Key_R) {
      initGame()
      canvas.requestPaint()
      return true
    }
    return false
  }

  function handleKeyRelease(event) {
    if (!gameState) return false

    if (event.key === Qt.Key_Left || event.key === Qt.Key_A || event.key === Qt.Key_Right || event.key === Qt.Key_D) {
      gameState.ship.rot = 0
      return true
    }
    if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
      gameState.ship.thrusting = false
      return true
    }
    return false
  }

  Timer {
    interval: 16 // 60 FPS
    running: root.visible && gameState && !gameState.gameOver && !gameState.paused
    repeat: true
    onTriggered: {
      Model.tick(gameState, 0.016)
      canvas.requestPaint()
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent

    onPaint: {
      if (!gameState) return
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      // Deep space background
      ctx.fillStyle = "#000000"
      ctx.fillRect(0, 0, width, height)

      var s = gameState.ship

      // 1. Draw Lasers
      ctx.fillStyle = "#ff3366"
      for (var m = 0; m < s.lasers.length; m++) {
        var lsr = s.lasers[m]
        ctx.beginPath()
        ctx.arc(lsr.x, lsr.y, 2.5, 0, Math.PI * 2)
        ctx.fill()
      }

      // 2. Draw Asteroids (Neon Vector Outline)
      ctx.strokeStyle = "#ffffff"
      ctx.lineWidth = 1.8
      for (var i = 0; i < gameState.roids.length; i++) {
        var a = gameState.roids[i]
        ctx.beginPath()
        for (var j = 0; j < a.vert; j++) {
          var ang = a.a + (j * Math.PI * 2) / a.vert
          var rad = a.r * a.offs[j]
          var vx = a.x + rad * Math.cos(ang)
          var vy = a.y - rad * Math.sin(ang)
          if (j === 0) ctx.moveTo(vx, vy)
          else ctx.lineTo(vx, vy)
        }
        ctx.closePath()
        ctx.stroke()
      }

      // 3. Draw Ship
      if (!s.dead) {
        // Thruster flame
        if (s.thrusting) {
          ctx.fillStyle = "#ff6600"
          ctx.strokeStyle = "#ffff00"
          ctx.lineWidth = 1.5
          ctx.beginPath()
          ctx.moveTo(
            s.x - s.r * (2 / 3 * Math.cos(s.a) + 0.5 * Math.sin(s.a)),
            s.y + s.r * (2 / 3 * Math.sin(s.a) - 0.5 * Math.cos(s.a))
          )
          ctx.lineTo(
            s.x - s.r * (5 / 3 * Math.cos(s.a)),
            s.y + s.r * (5 / 3 * Math.sin(s.a))
          )
          ctx.lineTo(
            s.x - s.r * (2 / 3 * Math.cos(s.a) - 0.5 * Math.sin(s.a)),
            s.y + s.r * (2 / 3 * Math.sin(s.a) + 0.5 * Math.cos(s.a))
          )
          ctx.closePath()
          ctx.fill()
          ctx.stroke()
        }

        // Triangular ship
        ctx.strokeStyle = "#ffffff"
        ctx.lineWidth = 1.8
        ctx.beginPath()
        // Nose
        ctx.moveTo(
          s.x + (4 / 3) * s.r * Math.cos(s.a),
          s.y - (4 / 3) * s.r * Math.sin(s.a)
        )
        // Rear left
        ctx.lineTo(
          s.x - s.r * (2 / 3 * Math.cos(s.a) + Math.sin(s.a)),
          s.y + s.r * (2 / 3 * Math.sin(s.a) - Math.cos(s.a))
        )
        // Rear right
        ctx.lineTo(
          s.x - s.r * (2 / 3 * Math.cos(s.a) - Math.sin(s.a)),
          s.y + s.r * (2 / 3 * Math.sin(s.a) + Math.cos(s.a))
        )
        ctx.closePath()
        ctx.stroke()
      }

      // 4. Authentic Vector HUD (Score & Lives)
      ctx.fillStyle = "#ffffff"
      ctx.font = "bold 13px monospace"
      ctx.textAlign = "right"
      ctx.fillText(String(gameState.score).padStart(5, '0'), width - 12, 22)

      // Lives indicators (small ships)
      for (var l = 0; l < gameState.lives; l++) {
        var lx = 16 + l * 14
        var ly = 16
        ctx.strokeStyle = "#ffffff"
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.moveTo(lx, ly - 7)
        ctx.lineTo(lx - 5, ly + 5)
        ctx.lineTo(lx + 5, ly + 5)
        ctx.closePath()
        ctx.stroke()
      }

      // Game Over Overlay
      if (gameState.gameOver) {
        ctx.fillStyle = "rgba(0, 0, 0, 0.7)"
        ctx.fillRect(0, 0, width, height)
        ctx.fillStyle = "#ff4444"
        ctx.font = "bold 20px monospace"
        ctx.textAlign = "center"
        ctx.fillText("GAME OVER", width / 2, height / 2 - 10)
        ctx.fillStyle = "#ffffff"
        ctx.font = "12px monospace"
        ctx.fillText("Press R to Restart", width / 2, height / 2 + 15)
      }
    }
  }
}
