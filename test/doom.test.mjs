import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const modelCode = fs.readFileSync(path.resolve('DoomModel.js'), 'utf8');

function loadModel() {
  const context = { Math, console };
  vm.createContext(context);
  vm.runInContext(modelCode, context);
  return context;
}

test('DOOM model initialization', () => {
  const model = loadModel();
  const state = model.initGameState();
  assert.equal(state.player.health, 100);
  assert.equal(state.player.armor, 50);
  assert.equal(state.player.ammo, 50);
  assert.equal(state.enemies.length, 4);
});

test('DOOM player movement and shooting', () => {
  const model = loadModel();
  const state = model.initGameState();
  
  state.keys.forward = true;
  model.tick(state, 0.1);
  assert.ok(state.player.x > 1.5);

  const initialAmmo = state.player.ammo;
  model.shoot(state);
  assert.equal(state.player.ammo, initialAmmo - 1);
  assert.equal(state.player.firing, true);
});
