// Model.js — Pure JavaScript Engine matching Chromium's authentic chrome://dino layout.
// Zero PyGame dependencies, zero lag, running directly in Quickshell at 60 FPS.

function initDino() {
  return {
    x: 30,
    y: 0,
    width: 44,
    height: 47,
    duck: false,
    run: true,
    jump: false,
    dead: false,
    stepIndex: 0,
    jumpVel: 0,
    gravity: 0.6,
    initialJumpVel: -10.5
  }
}

function initGameState() {
  return {
    dino: initDino(),
    obstacles: [],
    clouds: [
      { x: 260, y: 18 },
      { x: 440, y: 30 }
    ],
    gameSpeed: 6.0,
    trackOffset: 0,
    points: 0,
    highScore: 0,
    gameOver: false,
    started: false,
    paused: false
  }
}

function jump(state) {
  if (state.gameOver) {
    restart(state)
    return
  }
  if (!state.started) {
    state.started = true
  }
  if (!state.dino.jump) {
    state.dino.duck = false
    state.dino.run = false
    state.dino.jump = true
    state.dino.jumpVel = state.dino.initialJumpVel
  }
}

function duck(state, isDucking) {
  if (state.gameOver || !state.started) return
  if (state.dino.jump) return
  state.dino.duck = isDucking
  state.dino.run = !isDucking
}

function restart(state) {
  var hi = Math.max(state.highScore || 0, state.points || 0)
  var fresh = initGameState()
  fresh.highScore = hi
  fresh.started = true
  for (var k in fresh) state[k] = fresh[k]
}

function spawnObstacle(state, canvasWidth) {
  var r = Math.floor(Math.random() * 3)
  var spawnX = canvasWidth + 20

  if (r === 0) {
    // Small Cactus
    var type = Math.floor(Math.random() * 3)
    var widths = [17, 34, 51]
    state.obstacles.push({
      kind: "small_cactus",
      type: type,
      x: spawnX,
      width: widths[type] || 20,
      height: 35
    })
  } else if (r === 1) {
    // Large Cactus
    var type = Math.floor(Math.random() * 3)
    var widths = [25, 50, 75]
    state.obstacles.push({
      kind: "large_cactus",
      type: type,
      x: spawnX,
      width: widths[type] || 25,
      height: 50
    })
  } else {
    // Bird (Flying obstacle at 2 height levels: low or high)
    var heights = [28, 55]
    var altitude = heights[Math.floor(Math.random() * heights.length)]
    state.obstacles.push({
      kind: "bird",
      type: 0,
      x: spawnX,
      width: 46,
      height: 34,
      altitude: altitude,
      animIndex: 0
    })
  }
}

function checkCollision(dino, dinoY, obs, obsY) {
  var pad = 6
  var dw = (dino.duck ? 59 : 44) - pad * 2
  var dh = (dino.duck ? 30 : 47) - pad * 2
  var dx = dino.x + pad
  var dy = dinoY + pad

  var ox = obs.x + pad
  var oy = obsY + pad
  var ow = obs.width - pad * 2
  var oh = obs.height - pad * 2

  return (
    dx < ox + ow &&
    dx + dw > ox &&
    dy < oy + oh &&
    dy + dh > oy
  )
}

function tick(state, canvasWidth, groundY) {
  if (state.gameOver || state.paused || !state.started) return

  // Score accumulation & gradual speed acceleration
  state.points += 1
  if (state.points % 100 === 0 && state.gameSpeed < 13.0) {
    state.gameSpeed += 0.2
  }
  if (state.points > state.highScore) {
    state.highScore = state.points
  }

  // Dino Physics
  var dino = state.dino
  dino.stepIndex = (dino.stepIndex + 1) % 10

  if (dino.jump) {
    dino.y += dino.jumpVel
    dino.jumpVel += dino.gravity

    if (dino.y >= 0) {
      dino.y = 0
      dino.jump = false
      dino.jumpVel = 0
      dino.run = true
    }
  }

  // Track scrolling
  state.trackOffset = (state.trackOffset + state.gameSpeed) % canvasWidth

  // Cloud animation
  for (var c = 0; c < state.clouds.length; c++) {
    var cloud = state.clouds[c]
    cloud.x -= state.gameSpeed * 0.3
    if (cloud.x < -60) {
      cloud.x = canvasWidth + Math.floor(Math.random() * 200)
      cloud.y = 12 + Math.floor(Math.random() * 25)
    }
  }

  // Obstacle management
  if (state.obstacles.length === 0) {
    spawnObstacle(state, canvasWidth)
  }

  var dinoCurrentY = groundY - (dino.duck ? 30 : 47) + dino.y

  for (var i = state.obstacles.length - 1; i >= 0; i--) {
    var obs = state.obstacles[i]
    obs.x -= state.gameSpeed

    if (obs.kind === "bird") {
      obs.animIndex = (obs.animIndex + 1) % 10
    }

    var obsY = groundY - (obs.kind === "bird" ? obs.altitude : obs.height)

    if (checkCollision(dino, dinoCurrentY, obs, obsY)) {
      state.gameOver = true
      dino.dead = true
      return
    }

    if (obs.x < -100) {
      state.obstacles.splice(i, 1)
    }
  }
}
