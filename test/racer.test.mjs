import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs"
import vm from "node:vm"

const code = fs.readFileSync(new URL("../RacerModel.js", import.meta.url), "utf8")
const sandbox = {}
vm.createContext(sandbox)
vm.runInContext(code, sandbox)

test("Racer initialization", () => {
  const state = sandbox.initGameState()
  assert.equal(state.speed, 0)
  assert.equal(state.playerX, 0)
  assert.ok(state.segments.length > 50)
  assert.ok(state.cars.length > 10)
})

test("Racer acceleration and movement", () => {
  const state = sandbox.initGameState()
  state.keyFaster = true
  state.keyLeft = true

  for (let i = 0; i < 30; i++) {
    sandbox.tick(state, 0.016)
  }

  assert.ok(state.speed > 0)
  assert.ok(state.playerX < 0)
  assert.ok(state.position > 0)
})
