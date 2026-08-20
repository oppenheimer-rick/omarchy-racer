// DoomModel.js — 3D Raycasting Engine inspired by DOOM (E1M1)
// Pure JavaScript DDA Raycaster & Entity State Machine

var MAP = [
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  [1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
  [1,0,2,2,0,0,1,0,3,3,3,0,0,0,0,1],
  [1,0,2,2,0,0,0,0,3,0,3,0,0,4,0,1],
  [1,0,0,0,0,0,1,0,3,3,3,0,0,4,0,1],
  [1,0,0,0,0,0,1,0,0,0,0,0,0,4,0,1],
  [1,1,0,1,1,1,1,0,0,0,0,0,0,0,0,1],
  [1,0,0,0,0,0,0,0,2,2,0,0,0,0,0,1],
  [1,0,3,0,0,3,0,0,2,2,0,0,5,5,0,1],
  [1,0,3,0,0,3,0,0,0,0,0,0,5,5,0,1],
  [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
  [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
];

var MAP_WIDTH = 16;
var MAP_HEIGHT = 12;

function initGameState() {
  return {
    player: {
      x: 1.5,
      y: 1.5,
      dirX: 1,
      dirY: 0,
      planeX: 0,
      planeY: 0.66,
      moveSpeed: 3.5,
      rotSpeed: 2.8,
      health: 100,
      armor: 50,
      ammo: 50,
      kills: 0,
      weapon: "shotgun", // "shotgun" or "chaingun"
      firing: false,
      fireTimer: 0,
      muzzleFlash: 0
    },
    enemies: [
      { id: 1, x: 8.5, y: 3.5, type: "imp", health: 30, state: "idle", alert: false, dir: 1 },
      { id: 2, x: 13.5, y: 4.5, type: "demon", health: 60, state: "idle", alert: false, dir: -1 },
      { id: 3, x: 10.5, y: 8.5, type: "imp", health: 30, state: "idle", alert: false, dir: 1 },
      { id: 4, x: 4.5, y: 8.5, type: "imp", health: 30, state: "idle", alert: false, dir: -1 }
    ],
    items: [
      { id: 1, x: 13.5, y: 9.5, type: "medkit", collected: false },
      { id: 2, x: 3.5, y: 4.5, type: "armor", collected: false },
      { id: 3, x: 13.5, y: 2.5, type: "ammo", collected: false }
    ],
    keys: {
      forward: false,
      backward: false,
      turnLeft: false,
      turnRight: false,
      strafeLeft: false,
      strafeRight: false,
      fire: false
    },
    time: 0,
    paused: false,
    gameOver: false,
    message: "E1M1: HANGAR"
  };
}

function tick(state, dt) {
  if (state.paused || state.gameOver) return;

  var p = state.player;
  state.time += dt;

  // 1. Weapon Firing State
  if (p.firing) {
    p.fireTimer -= dt;
    if (p.fireTimer <= 0) {
      p.firing = false;
      p.muzzleFlash = 0;
    }
  }

  // 2. Player Rotation
  var rot = 0;
  if (state.keys.turnLeft) rot -= p.rotSpeed * dt;
  if (state.keys.turnRight) rot += p.rotSpeed * dt;

  if (rot !== 0) {
    var oldDirX = p.dirX;
    p.dirX = p.dirX * Math.cos(rot) - p.dirY * Math.sin(rot);
    p.dirY = oldDirX * Math.sin(rot) + p.dirY * Math.cos(rot);
    var oldPlaneX = p.planeX;
    p.planeX = p.planeX * Math.cos(rot) - p.planeY * Math.sin(rot);
    p.planeY = oldPlaneX * Math.sin(rot) + p.planeY * Math.cos(rot);
  }

  // 3. Player Movement & Collision
  var moveStep = p.moveSpeed * dt;
  var newX = p.x;
  var newY = p.y;

  if (state.keys.forward) {
    newX += p.dirX * moveStep;
    newY += p.dirY * moveStep;
  }
  if (state.keys.backward) {
    newX -= p.dirX * moveStep;
    newY -= p.dirY * moveStep;
  }
  if (state.keys.strafeLeft) {
    newX -= p.planeX * moveStep;
    newY -= p.planeY * moveStep;
  }
  if (state.keys.strafeRight) {
    newX += p.planeX * moveStep;
    newY += p.planeY * moveStep;
  }

  // Wall collisions with radius padding
  var pad = 0.2;
  if (MAP[Math.floor(p.y)][Math.floor(newX + (newX > p.x ? pad : -pad))] === 0) {
    p.x = newX;
  }
  if (MAP[Math.floor(newY + (newY > p.y ? pad : -pad))][Math.floor(p.x)] === 0) {
    p.y = newY;
  }

  // 4. Enemy AI & Movement
  for (var i = 0; i < state.enemies.length; i++) {
    var e = state.enemies[i];
    if (e.health <= 0) continue;

    var dist = Math.sqrt((p.x - e.x) * (p.x - e.x) + (p.y - e.y) * (p.y - e.y));
    if (dist < 8) e.alert = true;

    if (e.alert && dist > 1.2) {
      var dx = (p.x - e.x) / dist;
      var dy = (p.y - e.y) / dist;
      var step = 1.2 * dt;
      if (MAP[Math.floor(e.y)][Math.floor(e.x + dx * step)] === 0) e.x += dx * step;
      if (MAP[Math.floor(e.y + dy * step)][Math.floor(e.x)] === 0) e.y += dy * step;
    } else if (e.alert && dist <= 1.2) {
      // Enemy attacks player!
      if (Math.random() < 0.05) {
        var dmg = Math.floor(Math.random() * 8 + 4);
        if (p.armor > 0) {
          p.armor = Math.max(0, p.armor - Math.floor(dmg * 0.6));
          p.health = Math.max(0, p.health - Math.floor(dmg * 0.4));
        } else {
          p.health = Math.max(0, p.health - dmg);
        }
        if (p.health <= 0) state.gameOver = true;
      }
    }
  }

  // 5. Item Pickups
  for (var k = 0; k < state.items.length; k++) {
    var it = state.items[k];
    if (it.collected) continue;
    var d = Math.sqrt((p.x - it.x) * (p.x - it.x) + (p.y - it.y) * (p.y - it.y));
    if (d < 0.6) {
      it.collected = true;
      if (it.type === "medkit") p.health = Math.min(100, p.health + 25);
      if (it.type === "armor") p.armor = Math.min(100, p.armor + 50);
      if (it.type === "ammo") p.ammo = Math.min(100, p.ammo + 20);
    }
  }
}

function shoot(state) {
  var p = state.player;
  if (p.firing || p.ammo <= 0 || state.gameOver) return;

  p.firing = true;
  p.fireTimer = 0.4;
  p.muzzleFlash = 1;
  p.ammo -= 1;

  // Hitscan check closest enemy in crosshair
  var bestEnemy = null;
  var bestDist = 12;

  for (var i = 0; i < state.enemies.length; i++) {
    var e = state.enemies[i];
    if (e.health <= 0) continue;

    var ex = e.x - p.x;
    var ey = e.y - p.y;
    var dot = ex * p.dirX + ey * p.dirY;
    if (dot > 0) {
      var dist = Math.sqrt(ex * ex + ey * ey);
      var angle = Math.atan2(ey, ex) - Math.atan2(p.dirY, p.dirX);
      while (angle < -Math.PI) angle += Math.PI * 2;
      while (angle > Math.PI) angle -= Math.PI * 2;

      if (Math.abs(angle) < 0.25 && dist < bestDist) {
        bestDist = dist;
        bestEnemy = e;
      }
    }
  }

  if (bestEnemy) {
    bestEnemy.health -= Math.floor(Math.random() * 25 + 20);
    bestEnemy.alert = true;
    if (bestEnemy.health <= 0) {
      p.kills += 1;
    }
  }
}
