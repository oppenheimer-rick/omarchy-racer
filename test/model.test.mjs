import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs"
import vm from "node:vm"

const code = fs.readFileSync(new URL("../Model.js", import.meta.url), "utf8")
const sandbox = {}
vm.createContext(sandbox)
vm.runInContext(code, sandbox)

test("Chrome Dinosaur initialization", () => {
  const state = sandbox.initGameState()
  assert.equal(state.points, 0)
  assert.equal(state.gameOver, false)
  assert.equal(state.started, false)
  assert.equal(state.dino.x, 30)
  assert.equal(state.dino.y, 0)
})

test("Jump trajectory and return to ground", () => {
  const state = sandbox.initGameState()
  sandbox.jump(state)
  assert.equal(state.started, true)
  assert.equal(state.dino.jump, true)

  const groundY = 300
  for (let i = 0; i < 40; i++) {
    sandbox.tick(state, 400, groundY)
  }

  assert.equal(state.dino.jump, false)
  assert.equal(state.dino.y, 0)
})

test("Ducking state toggle", () => {
  const state = sandbox.initGameState()
  state.started = true
  sandbox.duck(state, true)
  assert.equal(state.dino.duck, true)
  assert.equal(state.dino.run, false)

  sandbox.duck(state, false)
  assert.equal(state.dino.duck, false)
  assert.equal(state.dino.run, true)
})

test("Obstacle spawn and collision", () => {
  const state = sandbox.initGameState()
  state.started = true
  sandbox.spawnObstacle(state, 400)
  assert.ok(state.obstacles.length >= 1)

  const groundY = 300
  // Place obstacle directly on dino
  state.obstacles[0].x = state.dino.x
  sandbox.tick(state, 400, groundY)
  assert.equal(state.gameOver, true)
  assert.equal(state.dino.dead, true)
})
