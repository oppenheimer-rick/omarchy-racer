import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs"
import vm from "node:vm"

const code = fs.readFileSync(new URL("../AsteroidsModel.js", import.meta.url), "utf8")
const sandbox = {}
vm.createContext(sandbox)
vm.runInContext(code, sandbox)

test("Asteroids initialization", () => {
  const state = sandbox.initGameState(380, 320)
  assert.equal(state.score, 0)
  assert.equal(state.lives, 3)
  assert.equal(state.gameOver, false)
  assert.equal(state.roids.length, 4)
  assert.equal(state.ship.dead, false)
})

test("Ship rotation, thrust, and laser shooting", () => {
  const state = sandbox.initGameState(380, 320)
  state.ship.rot = 3.0
  state.ship.thrusting = true
  sandbox.shootLaser(state)

  assert.equal(state.ship.lasers.length, 1)

  for (let i = 0; i < 20; i++) {
    sandbox.tick(state, 0.016)
  }

  assert.ok(state.ship.lasers[0].dist > 0)
})
