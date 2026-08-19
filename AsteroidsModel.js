// AsteroidsModel.js — Vector Asteroids Game Engine
// Ported from aman-atg/asteroids-game

var SHIP_SIZE = 24;
var SHIP_THRUST = 4.5;
var TURN_SPEED = 4.2; // radians/sec
var FRICTION = 0.985;
var LASER_MAX = 10;
var LASER_SPD = 420;
var LASER_DIST = 0.55;
var ROIDS_NUM = 4;
var ROIDS_SIZE = 70;
var ROIDS_SPD = 45;
var ROIDS_JAG = 0.35;
var ROIDS_VERT = 10;

function newAirship(w, h) {
  return {
    x: w / 2,
    y: h / 2,
    r: SHIP_SIZE / 2,
    a: (90 / 180) * Math.PI, // Facing upwards
    rot: 0,
    thrusting: false,
    thrust: { x: 0, y: 0 },
    canShoot: true,
    dead: false,
    explodeTime: 0,
    lasers: []
  };
}

function newAsteroid(x, y, r) {
  var a = Math.random() * Math.PI * 2;
  var spd = (Math.random() * 0.5 + 0.5) * ROIDS_SPD;
  var vert = Math.floor(Math.random() * (ROIDS_VERT / 2) + ROIDS_VERT / 2);
  var offs = [];
  for (var i = 0; i < vert; i++) {
    offs.push(Math.random() * ROIDS_JAG * 2 + 1 - ROIDS_JAG);
  }

  return {
    x: x,
    y: y,
    xv: Math.cos(a) * spd,
    yv: -Math.sin(a) * spd,
    r: r,
    a: Math.random() * Math.PI * 2,
    rot: (Math.random() - 0.5) * 1.5,
    vert: vert,
    offs: offs
  };
}

function initGameState(w, h) {
  var ship = newAirship(w, h);
  var roids = [];
  for (var i = 0; i < ROIDS_NUM; i++) {
    var x, y;
    do {
      x = Math.random() * w;
      y = Math.random() * h;
    } while (Math.hypot(x - ship.x, y - ship.y) < ROIDS_SIZE * 2 + ship.r);
    roids.push(newAsteroid(x, y, Math.ceil(ROIDS_SIZE / 2)));
  }

  return {
    width: w,
    height: h,
    ship: ship,
    roids: roids,
    score: 0,
    lives: 3,
    level: 1,
    gameOver: false,
    started: true,
    paused: false
  };
}

function createAsteroidBelt(state) {
  state.roids = [];
  var count = ROIDS_NUM + (state.level - 1) * 2;
  for (var i = 0; i < count; i++) {
    var x, y;
    do {
      x = Math.random() * state.width;
      y = Math.random() * state.height;
    } while (Math.hypot(x - state.ship.x, y - state.ship.y) < ROIDS_SIZE * 2 + state.ship.r);
    state.roids.push(newAsteroid(x, y, Math.ceil(ROIDS_SIZE / 2)));
  }
}

function shootLaser(state) {
  var s = state.ship;
  if (!s.dead && s.lasers.length < LASER_MAX) {
    s.lasers.push({
      x: s.x + (4 / 3) * s.r * Math.cos(s.a),
      y: s.y - (4 / 3) * s.r * Math.sin(s.a),
      xv: (LASER_SPD * Math.cos(s.a)),
      yv: -(LASER_SPD * Math.sin(s.a)),
      dist: 0
    });
  }
}

function tick(state, delta) {
  if (state.gameOver || state.paused) return;

  var s = state.ship;
  var w = state.width;
  var h = state.height;

  // 1. Ship rotation & thrust
  if (!s.dead) {
    s.a += s.rot * delta;

    if (s.thrusting) {
      s.thrust.x += SHIP_THRUST * Math.cos(s.a) * delta * 50;
      s.thrust.y -= SHIP_THRUST * Math.sin(s.a) * delta * 50;
    } else {
      s.thrust.x *= Math.pow(FRICTION, delta * 60);
      s.thrust.y *= Math.pow(FRICTION, delta * 60);
    }

    s.x += s.thrust.x * delta;
    s.y += s.thrust.y * delta;

    // Wrap screen edges
    if (s.x < 0 - s.r) s.x = w + s.r;
    else if (s.x > w + s.r) s.x = 0 - s.r;
    if (s.y < 0 - s.r) s.y = h + s.r;
    else if (s.y > h + s.r) s.y = 0 - s.r;
  }

  // 2. Lasers movement
  for (var i = s.lasers.length - 1; i >= 0; i--) {
    var l = s.lasers[i];
    l.x += l.xv * delta;
    l.y += l.yv * delta;
    l.dist += Math.hypot(l.xv * delta, l.yv * delta);

    if (l.dist > LASER_DIST * w) {
      s.lasers.splice(i, 1);
      continue;
    }

    // Wrap lasers
    if (l.x < 0) l.x = w;
    else if (l.x > w) l.x = 0;
    if (l.y < 0) l.y = h;
    else if (l.y > h) l.y = 0;
  }

  // 3. Asteroids movement
  for (var j = 0; j < state.roids.length; j++) {
    var r = state.roids[j];
    r.x += r.xv * delta;
    r.y += r.yv * delta;
    r.a += r.rot * delta;

    if (r.x < 0 - r.r) r.x = w + r.r;
    else if (r.x > w + r.r) r.x = 0 - r.r;
    if (r.y < 0 - r.r) r.y = h + r.r;
    else if (r.y > h + r.r) r.y = 0 - r.r;
  }

  // 4. Laser - Asteroid Collisions
  for (var k = state.roids.length - 1; k >= 0; k--) {
    var roid = state.roids[k];
    for (var m = s.lasers.length - 1; m >= 0; m--) {
      var lsr = s.lasers[m];
      if (Math.hypot(lsr.x - roid.x, lsr.y - roid.y) < roid.r) {
        // Destroy asteroid
        s.lasers.splice(m, 1);

        var R = Math.ceil(ROIDS_SIZE / 2);
        if (roid.r === R) {
          state.roids.push(newAsteroid(roid.x, roid.y, Math.ceil(R / 2)));
          state.roids.push(newAsteroid(roid.x, roid.y, Math.ceil(R / 2)));
          state.score += 20;
        } else if (roid.r === Math.ceil(R / 2)) {
          state.roids.push(newAsteroid(roid.x, roid.y, Math.ceil(R / 4)));
          state.roids.push(newAsteroid(roid.x, roid.y, Math.ceil(R / 4)));
          state.score += 50;
        } else {
          state.score += 100;
        }

        state.roids.splice(k, 1);
        break;
      }
    }
  }

  // Next Level if all cleared
  if (state.roids.length === 0) {
    state.level++;
    createAsteroidBelt(state);
  }

  // 5. Ship - Asteroid Collisions
  if (!s.dead) {
    for (var n = 0; n < state.roids.length; n++) {
      var rd = state.roids[n];
      if (Math.hypot(s.x - rd.x, s.y - rd.y) < s.r + rd.r) {
        s.dead = true;
        state.lives--;
        if (state.lives <= 0) {
          state.gameOver = true;
        } else {
          setTimeout(function() {
            state.ship = newAirship(w, h);
          }, 800);
        }
        break;
      }
    }
  }
}
