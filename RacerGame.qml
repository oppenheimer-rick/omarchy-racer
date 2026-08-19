import QtQuick
import "RacerModel.js" as Model

Item {
  id: root

  property var gameState: Model.initGameState()
  property string bgSource: Qt.resolvedUrl("Assets/Racer/background.png")
  property string spritesSource: Qt.resolvedUrl("Assets/Racer/sprites.png")
  property bool assetsLoaded: false

  function restart() {
    gameState = Model.initGameState()
    canvas.requestPaint()
  }

  function handleKeyPress(event) {
    if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
      gameState.keyFaster = true
      return true
    }
    if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
      gameState.keySlower = true
      return true
    }
    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
      gameState.keyLeft = true
      return true
    }
    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
      gameState.keyRight = true
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
    if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
      gameState.keyFaster = false
      return true
    }
    if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
      gameState.keySlower = false
      return true
    }
    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
      gameState.keyLeft = false
      return true
    }
    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
      gameState.keyRight = false
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

    Component.onCompleted: {
      loadImage(root.bgSource)
      loadImage(root.spritesSource)
    }

    onImageLoaded: {
      if (isImageLoaded(root.bgSource) && isImageLoaded(root.spritesSource)) {
        root.assetsLoaded = true
        requestPaint()
      }
    }

    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height

      if (!root.assetsLoaded) {
        if (isImageLoaded(root.bgSource) && isImageLoaded(root.spritesSource)) {
          root.assetsLoaded = true
        }
      }

      ctx.clearRect(0, 0, w, h)

      var baseSegment = Model.findSegment(gameState, gameState.position)
      var basePercent = Model.percentRemaining(gameState.position, gameState.segmentLength)
      var playerSegment = Model.findSegment(gameState, gameState.position + gameState.playerZ)
      var playerPercent = Model.percentRemaining(gameState.position + gameState.playerZ, gameState.segmentLength)
      var playerY = Model.interpolate(playerSegment.p1.world.y, playerSegment.p2.world.y, playerPercent)

      var cameraX = (gameState.playerX * gameState.roadWidth)
      var cameraY = gameState.cameraHeight + playerY
      var cameraZ = gameState.position - (basePercent * gameState.segmentLength)

      // 1. Full-Height Solid Ground & Sky Base
      ctx.fillStyle = "#72D7EE"
      ctx.fillRect(0, 0, w, h * 0.55)
      ctx.fillStyle = "#10AA10"
      ctx.fillRect(0, h * 0.45, w, h * 0.55)

      // 2. Draw Parallax Background (Seamless 3-Layer Panoramic Scroll)
      if (root.assetsLoaded) {
        renderBackground(ctx, root.bgSource, w, h, Model.BACKGROUND.SKY, gameState.skyOffset, 0)
        renderBackground(ctx, root.bgSource, w, h, Model.BACKGROUND.HILLS, gameState.hillOffset, 0)
        renderBackground(ctx, root.bgSource, w, h, Model.BACKGROUND.TREES, gameState.treeOffset, 0)
      }

      // 3. Draw 3D Road Segments (Back-to-Front Projection)
      var maxy = h
      var x = 0
      var dx = -(baseSegment.curve * basePercent)

      for (var n = 0; n < gameState.drawDistance; n++) {
        var segment = gameState.segments[(baseSegment.index + n) % gameState.segments.length]
        var looped = segment.index < baseSegment.index
        segment.clip = maxy
        segment.fog = Model.exponentialFog(n / gameState.drawDistance, gameState.fogDensity)

        Model.project(segment.p1, cameraX - x, cameraY, cameraZ - (looped ? gameState.trackLength : 0), gameState.cameraDepth, w, h, gameState.roadWidth)
        Model.project(segment.p2, cameraX - x - dx, cameraY, cameraZ - (looped ? gameState.trackLength : 0), gameState.cameraDepth, w, h, gameState.roadWidth)

        x += dx
        dx += segment.curve

        if ((segment.p1.camera.z <= gameState.cameraDepth) || (segment.p2.screen.y >= segment.p1.screen.y) || (segment.p2.screen.y >= maxy))
          continue

        // Grass Poly
        ctx.fillStyle = segment.color.grass
        ctx.fillRect(0, segment.p2.screen.y, w, segment.p1.screen.y - segment.p2.screen.y + 1)

        // Rumble Poly
        var r1 = segment.p1.screen.w / Math.max(6, 2 * gameState.lanes)
        var r2 = segment.p2.screen.w / Math.max(6, 2 * gameState.lanes)
        ctx.fillStyle = segment.color.rumble
        drawPoly(ctx, segment.p1.screen.x - segment.p1.screen.w - r1, segment.p1.screen.y, segment.p1.screen.x - segment.p1.screen.w, segment.p1.screen.y, segment.p2.screen.x - segment.p2.screen.w, segment.p2.screen.y, segment.p2.screen.x - segment.p2.screen.w - r2, segment.p2.screen.y)
        drawPoly(ctx, segment.p1.screen.x + segment.p1.screen.w + r1, segment.p1.screen.y, segment.p1.screen.x + segment.p1.screen.w, segment.p1.screen.y, segment.p2.screen.x + segment.p2.screen.w, segment.p2.screen.y, segment.p2.screen.x + segment.p2.screen.w + r2, segment.p2.screen.y)

        // Road Poly
        ctx.fillStyle = segment.color.road
        drawPoly(ctx, segment.p1.screen.x - segment.p1.screen.w, segment.p1.screen.y, segment.p1.screen.x + segment.p1.screen.w, segment.p1.screen.y, segment.p2.screen.x + segment.p2.screen.w, segment.p2.screen.y, segment.p2.screen.x - segment.p2.screen.w, segment.p2.screen.y)

        // Lane markings
        if (segment.color.lane) {
          var l1 = segment.p1.screen.w / 32
          var l2 = segment.p2.screen.w / 32
          for (var lane = 1; lane < gameState.lanes; lane++) {
            var laneW1 = (segment.p1.screen.w * 2 / gameState.lanes) * lane
            var laneW2 = (segment.p2.screen.w * 2 / gameState.lanes) * lane
            ctx.fillStyle = segment.color.lane
            drawPoly(ctx, segment.p1.screen.x - segment.p1.screen.w + laneW1 - l1/2, segment.p1.screen.y, segment.p1.screen.x - segment.p1.screen.w + laneW1 + l1/2, segment.p1.screen.y, segment.p2.screen.x - segment.p2.screen.w + laneW2 + l2/2, segment.p2.screen.y, segment.p2.screen.x - segment.p2.screen.w + laneW2 - l2/2, segment.p2.screen.y)
          }
        }

        // Atmospheric Fog
        if (segment.fog < 1) {
          ctx.globalAlpha = (1 - segment.fog) * 0.65
          ctx.fillStyle = Model.COLORS.FOG
          ctx.fillRect(0, segment.p2.screen.y, w, segment.p1.screen.y - segment.p2.screen.y + 1)
          ctx.globalAlpha = 1
        }

        maxy = segment.p1.screen.y
      }

      // 4. Draw Roadside Billboards, Trees, Traffic, and Player (Back-to-Front)
      if (root.assetsLoaded) {
        for (var sn = gameState.drawDistance - 1; sn > 0; sn--) {
          var seg = gameState.segments[(baseSegment.index + sn) % gameState.segments.length]

          // Traffic Cars
          for (var ci = 0; ci < seg.cars.length; ci++) {
            var car = seg.cars[ci]
            var carScale = Model.interpolate(seg.p1.screen.scale, seg.p2.screen.scale, car.percent)
            var carX = Model.interpolate(seg.p1.screen.x, seg.p2.screen.x, car.percent) + (carScale * car.offset * gameState.roadWidth * w / 2)
            var carY = Model.interpolate(seg.p1.screen.y, seg.p2.screen.y, car.percent)
            renderSprite(ctx, root.spritesSource, w, h, gameState.roadWidth, car.sprite, carScale, carX, carY, -0.5, -1, seg.clip)
          }

          // Roadside Billboards & Palms
          for (var si = 0; si < seg.sprites.length; si++) {
            var sp = seg.sprites[si]
            var spScale = seg.p1.screen.scale
            var spX = seg.p1.screen.x + (spScale * sp.offset * gameState.roadWidth * w / 2)
            var spY = seg.p1.screen.y
            renderSprite(ctx, root.spritesSource, w, h, gameState.roadWidth, sp.source, spScale, spX, spY, (sp.offset < 0 ? -1 : 0), -1, seg.clip)
          }

          // Player Ferrari
          if (seg === playerSegment) {
            var steer = gameState.keyLeft ? -1 : (gameState.keyRight ? 1 : 0)
            var updown = playerSegment.p2.world.y - playerSegment.p1.world.y
            var playerSprite = Model.SPRITES.PLAYER_STRAIGHT
            if (steer < 0) playerSprite = (updown > 0) ? Model.SPRITES.PLAYER_UPHILL_LEFT : Model.SPRITES.PLAYER_LEFT
            else if (steer > 0) playerSprite = (updown > 0) ? Model.SPRITES.PLAYER_UPHILL_RIGHT : Model.SPRITES.PLAYER_RIGHT
            else playerSprite = (updown > 0) ? Model.SPRITES.PLAYER_UPHILL_STRAIGHT : Model.SPRITES.PLAYER_STRAIGHT

            var pScale = gameState.cameraDepth / gameState.playerZ
            var pDestX = w / 2
            var speedRatio = gameState.speed / gameState.maxSpeed
            var bounce = (1.5 * Math.random() * speedRatio) * (Math.random() > 0.5 ? 1 : -1)
            var pDestY = (h / 2) - (pScale * Model.interpolate(playerSegment.p1.camera.y, playerSegment.p2.camera.y, playerPercent) * h / 2) + bounce

            renderSprite(ctx, root.spritesSource, w, h, gameState.roadWidth, playerSprite, pScale, pDestX, pDestY, -0.5, -1, null)
          }
        }
      }

      // 5. Retro Digital HUD
      var mph = Math.round((gameState.speed / gameState.maxSpeed) * 180)
      ctx.fillStyle = "rgba(0, 0, 0, 0.55)"
      ctx.fillRect(8, 8, 105, 24)
      ctx.fillRect(w - 105, 8, 97, 24)

      ctx.fillStyle = "#ffff00"
      ctx.font = "bold 12px monospace"
      ctx.textAlign = "left"
      ctx.fillText(mph + " MPH", 14, 24)

      var timeStr = (gameState.currentLapTime).toFixed(1) + "s"
      ctx.fillStyle = "#00ffff"
      ctx.textAlign = "right"
      ctx.fillText(timeStr, w - 14, 24)
    }

    function renderBackground(ctx, bgImage, width, height, layer, rotation, offset) {
      rotation = rotation || 0
      offset = offset || 0

      var imageW = layer.w / 2
      var imageH = layer.h

      var sourceX = layer.x + Math.floor(layer.w * rotation)
      var sourceY = layer.y
      var sourceW = Math.min(imageW, layer.x + layer.w - sourceX)
      var sourceH = imageH

      var destX = 0
      var destY = offset
      var destW = Math.floor(width * (sourceW / imageW))
      var destH = Math.floor(height * 0.5)

      ctx.drawImage(bgImage, sourceX, sourceY, sourceW, sourceH, destX, destY, destW, destH)
      if (sourceW < imageW)
        ctx.drawImage(bgImage, layer.x, sourceY, imageW - sourceW, sourceH, destW - 1, destY, width - destW, destH)
    }

    function renderSprite(ctx, spriteImage, width, height, roadWidth, sprite, scale, destX, destY, offsetX, offsetY, clipY) {
      var destW = (sprite.w * scale * width / 2) * (Model.SPRITES.SCALE * roadWidth)
      var destH = (sprite.h * scale * width / 2) * (Model.SPRITES.SCALE * roadWidth)

      destX = destX + (destW * (offsetX || 0))
      destY = destY + (destH * (offsetY || 0))

      var clipH = clipY ? Math.max(0, destY + destH - clipY) : 0
      if (clipH < destH) {
        ctx.drawImage(spriteImage, sprite.x, sprite.y, sprite.w, sprite.h - (sprite.h * clipH / destH), destX, destY, destW, destH - clipH)
      }
    }

    function drawPoly(ctx, x1, y1, x2, y2, x3, y3, x4, y4) {
      ctx.beginPath()
      ctx.moveTo(x1, y1)
      ctx.lineTo(x2, y2)
      ctx.lineTo(x3, y3)
      ctx.lineTo(x4, y4)
      ctx.closePath()
      ctx.fill()
    }
  }
}
