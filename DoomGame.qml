import QtQuick
import "DoomModel.js" as Model

Item {
  id: root

  property var gameState: Model.initGameState()

  function restart() {
    gameState = Model.initGameState()
    canvas.requestPaint()
  }

  function handleKeyPress(event) {
    if (event.key === Qt.Key_W || event.key === Qt.Key_Up) {
      gameState.keys.forward = true
      return true
    }
    if (event.key === Qt.Key_S || event.key === Qt.Key_Down) {
      gameState.keys.backward = true
      return true
    }
    if (event.key === Qt.Key_A || event.key === Qt.Key_Left) {
      gameState.keys.turnLeft = true
      return true
    }
    if (event.key === Qt.Key_D || event.key === Qt.Key_Right) {
      gameState.keys.turnRight = true
      return true
    }
    if (event.key === Qt.Key_Q) {
      gameState.keys.strafeLeft = true
      return true
    }
    if (event.key === Qt.Key_E) {
      gameState.keys.strafeRight = true
      return true
    }
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Control || event.key === Qt.Key_Return) {
      Model.shoot(gameState)
      canvas.requestPaint()
      return true
    }
    if (event.key === Qt.Key_P) {
      gameState.paused = !gameState.paused
      canvas.requestPaint()
      return true
    }
    if (event.key === Qt.Key_R) {
      restart()
      return true
    }
    return false
  }

  function handleKeyRelease(event) {
    if (event.key === Qt.Key_W || event.key === Qt.Key_Up) {
      gameState.keys.forward = false
      return true
    }
    if (event.key === Qt.Key_S || event.key === Qt.Key_Down) {
      gameState.keys.backward = false
      return true
    }
    if (event.key === Qt.Key_A || event.key === Qt.Key_Left) {
      gameState.keys.turnLeft = false
      return true
    }
    if (event.key === Qt.Key_D || event.key === Qt.Key_Right) {
      gameState.keys.turnRight = false
      return true
    }
    if (event.key === Qt.Key_Q) {
      gameState.keys.strafeLeft = false
      return true
    }
    if (event.key === Qt.Key_E) {
      gameState.keys.strafeRight = false
      return true
    }
    return false
  }

  Timer {
    interval: 16 // 60 FPS
    running: root.visible && !gameState.paused
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
      var ctx = getContext("2d")
      var w = width
      var h = height
      var p = gameState.player

      var hudHeight = Math.max(34, Math.floor(h * 0.12))
      var viewH = h - hudHeight

      // 1. Sky & Floor (Dynamic Doom Lighting)
      ctx.fillStyle = "#1e1e24" // Dark ceiling/sky
      ctx.fillRect(0, 0, w, viewH / 2)
      ctx.fillStyle = "#2d2822" // Industrial brown floor
      ctx.fillRect(0, viewH / 2, w, viewH / 2)

      // 2. DDA 3D Wall Raycasting
      var zBuffer = []
      var numRays = Math.min(160, Math.floor(w / 2))
      var rayStep = w / numRays

      var wallColors = [
        ["#5a5a60", "#404048"], // Tech Gray (E1M1)
        ["#8b4513", "#69330e"], // Brown Stone
        ["#3b5323", "#283818"], // Toxic Green Base
        ["#7f2020", "#591414"], // Hell Red
        ["#224466", "#152c44"]  // Blue Computer Station
      ]

      for (var x = 0; x < numRays; x++) {
        var cameraX = (2 * x / numRays) - 1
        var rayDirX = p.dirX + p.planeX * cameraX
        var rayDirY = p.dirY + p.planeY * cameraX

        var mapX = Math.floor(p.x)
        var mapY = Math.floor(p.y)

        var deltaDistX = Math.abs(1 / (rayDirX === 0 ? 0.00001 : rayDirX))
        var deltaDistY = Math.abs(1 / (rayDirY === 0 ? 0.00001 : rayDirY))
        var perpWallDist

        var stepX, stepY
        var hit = 0
        var side = 0

        if (rayDirX < 0) {
          stepX = -1
          var sideDistX = (p.x - mapX) * deltaDistX
        } else {
          stepX = 1
          var sideDistX = (mapX + 1.0 - p.x) * deltaDistX
        }

        if (rayDirY < 0) {
          stepY = -1
          var sideDistY = (p.y - mapY) * deltaDistY
        } else {
          stepY = 1
          var sideDistY = (mapY + 1.0 - p.y) * deltaDistY
        }

        while (hit === 0) {
          if (sideDistX < sideDistY) {
            sideDistX += deltaDistX
            mapX += stepX
            side = 0
          } else {
            sideDistY += deltaDistY
            mapY += stepY
            side = 1
          }
          if (mapX < 0 || mapX >= Model.MAP_WIDTH || mapY < 0 || mapY >= Model.MAP_HEIGHT) {
            hit = 1
            break
          }
          if (Model.MAP[mapY][mapX] > 0) hit = 1
        }

        if (side === 0) perpWallDist = (mapX - p.x + (1 - stepX) / 2) / rayDirX
        else perpWallDist = (mapY - p.y + (1 - stepY) / 2) / rayDirY

        zBuffer[x] = perpWallDist

        var lineHeight = Math.floor(viewH / Math.max(0.1, perpWallDist))
        var drawStart = Math.floor(-lineHeight / 2 + viewH / 2)
        if (drawStart < 0) drawStart = 0
        var drawEnd = Math.floor(lineHeight / 2 + viewH / 2)
        if (drawEnd >= viewH) drawEnd = viewH - 1

        var wallType = (mapX >= 0 && mapX < Model.MAP_WIDTH && mapY >= 0 && mapY < Model.MAP_HEIGHT) ? Model.MAP[mapY][mapX] : 1
        var colors = wallColors[(wallType - 1) % wallColors.length]
        var baseColor = side === 1 ? colors[1] : colors[0]

        // Depth fog shading
        var shade = Math.max(0.2, 1 - perpWallDist / 12)
        ctx.fillStyle = baseColor
        ctx.globalAlpha = shade
        ctx.fillRect(Math.floor(x * rayStep), drawStart, Math.ceil(rayStep) + 1, drawEnd - drawStart)
        ctx.globalAlpha = 1
      }

      // 3. 3D Enemy Billboards
      for (var i = 0; i < gameState.enemies.length; i++) {
        var e = gameState.enemies[i]
        if (e.health <= 0) continue

        var spriteX = e.x - p.x
        var spriteY = e.y - p.y

        var invDet = 1.0 / (p.planeX * p.dirY - p.dirX * p.planeY)
        var transformX = invDet * (p.dirY * spriteX - p.dirX * spriteY)
        var transformY = invDet * (-p.planeY * spriteX + p.planeX * spriteY)

        if (transformY > 0.3) {
          var spriteScreenX = Math.floor((w / 2) * (1 + transformX / transformY))
          var spriteHeight = Math.abs(Math.floor(viewH / transformY)) * 0.85
          var drawStartY = Math.floor(-spriteHeight / 2 + viewH / 2)
          if (drawStartY < 0) drawStartY = 0
          var drawEndY = Math.floor(spriteHeight / 2 + viewH / 2)
          if (drawEndY >= viewH) drawEndY = viewH - 1

          var spriteWidth = Math.abs(Math.floor(viewH / transformY)) * 0.65
          var drawStartX = Math.floor(-spriteWidth / 2 + spriteScreenX)
          var drawEndX = Math.floor(spriteWidth / 2 + spriteScreenX)

          var rayIdx = Math.floor((spriteScreenX / w) * numRays)
          if (rayIdx >= 0 && rayIdx < numRays && transformY < zBuffer[rayIdx]) {
            // Draw Demon / Imp Body
            ctx.fillStyle = e.type === "demon" ? "#cc2222" : "#995522"
            var demonShade = Math.max(0.3, 1 - transformY / 10)
            ctx.globalAlpha = demonShade
            ctx.fillRect(drawStartX, drawStartY, spriteWidth, drawEndY - drawStartY)

            // Glowing Red Eyes
            ctx.fillStyle = "#ff0000"
            var eyeW = Math.max(2, spriteWidth * 0.15)
            var eyeH = Math.max(2, spriteHeight * 0.1)
            ctx.fillRect(drawStartX + spriteWidth * 0.25, drawStartY + spriteHeight * 0.2, eyeW, eyeH)
            ctx.fillRect(drawStartX + spriteWidth * 0.6, drawStartY + spriteHeight * 0.2, eyeW, eyeH)
            ctx.globalAlpha = 1
          }
        }
      }

      // 4. Center DOOM Shotgun & Muzzle Flash
      var gunW = Math.floor(w * 0.28)
      var gunH = Math.floor(viewH * 0.42)
      var gunX = Math.floor(w / 2 - gunW / 2)
      var recoil = p.firing ? 14 : 0
      var gunY = Math.floor(viewH - gunH + recoil)

      // Shotgun barrel & stock
      ctx.fillStyle = "#222224"
      ctx.fillRect(gunX + gunW * 0.35, gunY, gunW * 0.3, gunH * 0.6)
      ctx.fillStyle = "#444448"
      ctx.fillRect(gunX + gunW * 0.38, gunY, gunW * 0.1, gunH * 0.55)
      ctx.fillRect(gunX + gunW * 0.52, gunY, gunW * 0.1, gunH * 0.55)
      ctx.fillStyle = "#5c3a21" // Wood grip
      ctx.fillRect(gunX + gunW * 0.3, gunY + gunH * 0.5, gunW * 0.4, gunH * 0.5)

      // Muzzle Flash
      if (p.firing && p.muzzleFlash > 0) {
        ctx.fillStyle = "#ffea00"
        ctx.beginPath()
        ctx.arc(w / 2, gunY - 12, gunW * 0.35, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = "#ff4400"
        ctx.beginPath()
        ctx.arc(w / 2, gunY - 12, gunW * 0.2, 0, Math.PI * 2)
        ctx.fill()
      }

      // Crosshair
      ctx.strokeStyle = "rgba(255, 255, 255, 0.4)"
      ctx.lineWidth = 1.5
      ctx.beginPath()
      ctx.moveTo(w / 2 - 8, viewH / 2)
      ctx.lineTo(w / 2 + 8, viewH / 2)
      ctx.moveTo(w / 2, viewH / 2 - 8)
      ctx.lineTo(w / 2, viewH / 2 + 8)
      ctx.stroke()

      // 5. Classic DOOM Status Bar HUD
      ctx.fillStyle = "#2b2b2b"
      ctx.fillRect(0, viewH, w, hudHeight)
      ctx.fillStyle = "#151515"
      ctx.fillRect(0, viewH, w, 2)

      // Stat Columns (Ammo, Health, Mugshot Face, Armor)
      var colW = w / 4
      ctx.font = "bold " + Math.max(10, Math.floor(hudHeight * 0.4)) + "px monospace"
      ctx.textAlign = "center"

      // Ammo
      ctx.fillStyle = "#ffcc00"
      ctx.fillText(p.ammo, colW * 0.5, viewH + hudHeight * 0.55)
      ctx.fillStyle = "#888888"
      ctx.font = "8px monospace"
      ctx.fillText("AMMO", colW * 0.5, viewH + hudHeight * 0.85)

      // Health
      ctx.fillStyle = p.health > 25 ? "#ff3333" : "#ff0000"
      ctx.font = "bold " + Math.max(10, Math.floor(hudHeight * 0.4)) + "px monospace"
      ctx.fillText(p.health + "%", colW * 1.5, viewH + hudHeight * 0.55)
      ctx.fillStyle = "#888888"
      ctx.font = "8px monospace"
      ctx.fillText("HEALTH", colW * 1.5, viewH + hudHeight * 0.85)

      // Doomguy Face
      ctx.fillStyle = "#e0aa88"
      var faceSize = Math.floor(hudHeight * 0.65)
      ctx.fillRect(colW * 2 - faceSize / 2, viewH + (hudHeight - faceSize) / 2, faceSize, faceSize)
      ctx.fillStyle = "#331100" // Hair
      ctx.fillRect(colW * 2 - faceSize / 2, viewH + (hudHeight - faceSize) / 2, faceSize, faceSize * 0.25)
      ctx.fillStyle = "#000000" // Eyes
      ctx.fillRect(colW * 2 - faceSize * 0.3, viewH + hudHeight * 0.45, 2, 3)
      ctx.fillRect(colW * 2 + faceSize * 0.15, viewH + hudHeight * 0.45, 2, 3)

      // Armor
      ctx.fillStyle = "#00ffff"
      ctx.font = "bold " + Math.max(10, Math.floor(hudHeight * 0.4)) + "px monospace"
      ctx.fillText(p.armor + "%", colW * 3.5, viewH + hudHeight * 0.55)
      ctx.fillStyle = "#888888"
      ctx.font = "8px monospace"
      ctx.fillText("ARMOR", colW * 3.5, viewH + hudHeight * 0.85)

      // Game Over overlay
      if (gameState.gameOver) {
        ctx.fillStyle = "rgba(180, 0, 0, 0.7)"
        ctx.fillRect(0, 0, w, viewH)
        ctx.fillStyle = "#ffffff"
        ctx.font = "bold 20px monospace"
        ctx.fillText("YOU DIED", w / 2, viewH / 2)
        ctx.font = "12px monospace"
        ctx.fillText("Press R to Restart", w / 2, viewH / 2 + 30)
      }
    }
  }
}
