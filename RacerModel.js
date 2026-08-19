// RacerModel.js — Highly Optimized OutRun 3D Road Engine with Dynamic Procedural Maps
// Ported from jakesgordon/javascript-racer

var SPRITES = {
  PALM_TREE:              { x:    5, y:    5, w:  215, h:  540 },
  BILLBOARD08:            { x:  230, y:    5, w:  385, h:  265 },
  TREE1:                  { x:  625, y:    5, w:  360, h:  360 },
  DEAD_TREE1:             { x:    5, y:  555, w:  135, h:  332 },
  BILLBOARD09:            { x:  150, y:  555, w:  328, h:  282 },
  BOULDER3:               { x:  230, y:  280, w:  320, h:  220 },
  COLUMN:                 { x:  995, y:    5, w:  200, h:  315 },
  BILLBOARD01:            { x:  625, y:  375, w:  300, h:  170 },
  BILLBOARD06:            { x:  488, y:  555, w:  298, h:  190 },
  BILLBOARD05:            { x:    5, y:  897, w:  298, h:  190 },
  BILLBOARD07:            { x:  313, y:  897, w:  298, h:  190 },
  BOULDER2:               { x:  621, y:  897, w:  298, h:  140 },
  TREE2:                  { x: 1205, y:    5, w:  282, h:  295 },
  BILLBOARD04:            { x: 1205, y:  310, w:  268, h:  170 },
  DEAD_TREE2:             { x: 1205, y:  490, w:  150, h:  260 },
  BOULDER1:               { x: 1205, y:  760, w:  168, h:  248 },
  BUSH1:                  { x:    5, y: 1097, w:  240, h:  155 },
  CACTUS:                 { x:  929, y:  897, w:  235, h:  118 },
  BUSH2:                  { x:  255, y: 1097, w:  232, h:  152 },
  BILLBOARD03:            { x:    5, y: 1262, w:  230, h:  220 },
  BILLBOARD02:            { x:  245, y: 1262, w:  215, h:  220 },
  STUMP:                  { x:  995, y:  330, w:  195, h:  140 },
  SEMI:                   { x: 1365, y:  490, w:  122, h:  144 },
  TRUCK:                  { x: 1365, y:  644, w:  100, h:   78 },
  CAR03:                  { x: 1383, y:  760, w:   88, h:   55 },
  CAR02:                  { x: 1383, y:  825, w:   80, h:   59 },
  CAR04:                  { x: 1383, y:  894, w:   80, h:   57 },
  CAR01:                  { x: 1205, y: 1018, w:   80, h:   56 },
  PLAYER_UPHILL_LEFT:     { x: 1383, y:  961, w:   80, h:   45 },
  PLAYER_UPHILL_STRAIGHT: { x: 1295, y: 1018, w:   80, h:   45 },
  PLAYER_UPHILL_RIGHT:    { x: 1385, y: 1018, w:   80, h:   45 },
  PLAYER_LEFT:            { x:  995, y:  480, w:   80, h:   41 },
  PLAYER_STRAIGHT:        { x: 1085, y:  480, w:   80, h:   41 },
  PLAYER_RIGHT:           { x:  995, y:  531, w:   80, h:   41 },
  SCALE:                  0.00390625 // 1/256
};

var BACKGROUND = {
  HILLS: { x:    5, y:    5, w: 1280, h:  480 },
  SKY:   { x:    5, y:  495, w: 1280, h:  480 },
  TREES: { x:    5, y:  985, w: 1280, h:  480 }
};

var COLORS = {
  SKY:    '#72D7EE',
  TREE:   '#005108',
  FOG:    '#005108',
  LIGHT:  { road: '#6B6B6B', grass: '#10AA10', rumble: '#555555', lane: '#CCCCCC' },
  DARK:   { road: '#696969', grass: '#009A00', rumble: '#BBBBBB' },
  START:  { road: '#ffffff', grass: '#ffffff', rumble: '#ffffff' },
  FINISH: { road: '#000000', grass: '#000000', rumble: '#000000' }
};

var ROAD = {
  LENGTH: { NONE: 0, SHORT: 25, MEDIUM: 50, LONG: 100 },
  HILL:   { NONE: 0, LOW: 20, MEDIUM: 40, HIGH: 60 },
  CURVE:  { NONE: 0, EASY: 2, MEDIUM: 4, HARD: 6 }
};

function limit(value, min, max) { return Math.max(min, Math.min(value, max)); }
function accelerate(v, accel, dt) { return v + (accel * dt); }
function easeInOut(a, b, percent) { return a + (b - a) * ((-Math.cos(percent * Math.PI) / 2) + 0.5); }
function easeIn(a, b, percent) { return a + (b - a) * Math.pow(percent, 2); }
function easeOut(a, b, percent) { return a + (b - a) * (1 - Math.pow(1 - percent, 2)); }
function interpolate(a, b, percent) { return a + (b - a) * percent; }
function exponentialFog(distance, density) { return 1 / (Math.pow(Math.E, (distance * distance * density))); }

function increase(start, increment, max) {
  var result = start + increment;
  while (result >= max) result -= max;
  while (result < 0) result += max;
  return result;
}

function percentRemaining(n, total) { return (n % total) / total; }

function overlap(x1, w1, x2, w2, percent) {
  var half = (percent || 1) / 2;
  var min1 = x1 - (w1 * half);
  var max1 = x1 + (w1 * half);
  var min2 = x2 - (w2 * half);
  var max2 = x2 + (w2 * half);
  return !((max1 < min2) || (min1 > max2));
}

function project(p, cameraX, cameraY, cameraZ, cameraDepth, width, height, roadWidth) {
  p.camera.x = (p.world.x || 0) - cameraX;
  p.camera.y = (p.world.y || 0) - cameraY;
  p.camera.z = (p.world.z || 0) - cameraZ;
  p.screen.scale = cameraDepth / p.camera.z;
  p.screen.x = Math.round((width / 2) + (p.screen.scale * p.camera.x * width / 2));
  p.screen.y = Math.round((height / 2) - (p.screen.scale * p.camera.y * height / 2));
  p.screen.w = Math.round((p.screen.scale * roadWidth * width / 2));
}

function addSegment(state, curve, y) {
  var n = state.segments.length;
  state.segments.push({
    index: n,
    p1: { world: { y: lastY(state), z: n * state.segmentLength }, camera: {}, screen: {} },
    p2: { world: { y: y, z: (n + 1) * state.segmentLength }, camera: {}, screen: {} },
    curve: curve,
    sprites: [],
    cars: [],
    color: Math.floor(n / state.rumbleLength) % 2 ? COLORS.DARK : COLORS.LIGHT
  });
}

function addSprite(state, n, sprite, offset) {
  if (state.segments[n]) {
    state.segments[n].sprites.push({ source: sprite, offset: offset });
  }
}

function lastY(state) {
  return (state.segments.length === 0) ? 0 : state.segments[state.segments.length - 1].p2.world.y;
}

function addRoad(state, enter, hold, leave, curve, y) {
  var startY = lastY(state);
  var endY = startY + (y * state.segmentLength);
  var total = enter + hold + leave;
  for (var n = 0; n < enter; n++)
    addSegment(state, easeIn(0, curve, n / enter), easeInOut(startY, endY, n / total));
  for (var n = 0; n < hold; n++)
    addSegment(state, curve, easeInOut(startY, endY, (enter + n) / total));
  for (var n = 0; n < leave; n++)
    addSegment(state, easeInOut(curve, 0, n / leave), easeInOut(startY, endY, (enter + hold + n) / total));
}

function addStraight(state, num) {
  num = num || ROAD.LENGTH.MEDIUM;
  addRoad(state, num, num, num, 0, 0);
}

function addHill(state, num, height) {
  num = num || ROAD.LENGTH.MEDIUM;
  height = height || ROAD.HILL.MEDIUM;
  addRoad(state, num, num, num, 0, height);
}

function addCurve(state, num, curve, height) {
  num = num || ROAD.LENGTH.MEDIUM;
  curve = curve || ROAD.CURVE.MEDIUM;
  height = height || ROAD.HILL.NONE;
  addRoad(state, num, num, num, curve, height);
}

function addLowRollingHills(state, num, height) {
  num = num || ROAD.LENGTH.SHORT;
  height = height || ROAD.HILL.LOW;
  addRoad(state, num, num, num, 0, height / 2);
  addRoad(state, num, num, num, 0, -height);
  addRoad(state, num, num, num, ROAD.CURVE.EASY, height);
  addRoad(state, num, num, num, 0, 0);
  addRoad(state, num, num, num, -ROAD.CURVE.EASY, height / 2);
  addRoad(state, num, num, num, 0, 0);
}

function addSCurves(state) {
  addRoad(state, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, -ROAD.CURVE.EASY, ROAD.HILL.NONE);
  addRoad(state, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.CURVE.MEDIUM, ROAD.HILL.MEDIUM);
  addRoad(state, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.CURVE.EASY, -ROAD.HILL.LOW);
  addRoad(state, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, -ROAD.CURVE.EASY, ROAD.HILL.MEDIUM);
  addRoad(state, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, ROAD.LENGTH.MEDIUM, -ROAD.CURVE.MEDIUM, -ROAD.HILL.MEDIUM);
}

function addBumps(state) {
  addRoad(state, 10, 10, 10, 0, 5);
  addRoad(state, 10, 10, 10, 0, -2);
  addRoad(state, 10, 10, 10, 0, -5);
  addRoad(state, 10, 10, 10, 0, 8);
  addRoad(state, 10, 10, 10, 0, 5);
  addRoad(state, 10, 10, 10, 0, -7);
  addRoad(state, 10, 10, 10, 0, 5);
  addRoad(state, 10, 10, 10, 0, -2);
}

function addDownhillToEnd(state, num) {
  num = num || 200;
  addRoad(state, num, num, num, -ROAD.CURVE.EASY, -lastY(state) / state.segmentLength);
}

// Procedural Dynamic Map Generator
function buildProceduralRoad(state) {
  state.segments = [];

  // Start grid
  addStraight(state, ROAD.LENGTH.SHORT);

  // Generate 8 randomized terrain sections
  var sectionTypes = ['hills', 'scurves', 'curves', 'bumps', 'straight', 'rolling'];
  for (var s = 0; s < 10; s++) {
    var type = sectionTypes[Math.floor(Math.random() * sectionTypes.length)];
    var curveIntensity = (Math.random() > 0.5 ? 1 : -1) * (Math.random() * 4 + 2);
    var hillHeight = Math.floor(Math.random() * 40 + 10);

    if (type === 'hills') {
      addHill(state, ROAD.LENGTH.MEDIUM, hillHeight);
      addHill(state, ROAD.LENGTH.MEDIUM, -hillHeight);
    } else if (type === 'scurves') {
      addSCurves(state);
    } else if (type === 'curves') {
      addCurve(state, ROAD.LENGTH.LONG, curveIntensity, hillHeight / 2);
      addCurve(state, ROAD.LENGTH.MEDIUM, -curveIntensity, -hillHeight / 2);
    } else if (type === 'bumps') {
      addBumps(state);
    } else if (type === 'rolling') {
      addLowRollingHills(state, ROAD.LENGTH.SHORT, hillHeight);
    } else {
      addStraight(state, ROAD.LENGTH.MEDIUM);
    }
  }

  addDownhillToEnd(state);

  // Populate Roadside Scenery Across 100% of Track Length (No barren zones!)
  var billboards = [SPRITES.BILLBOARD01, SPRITES.BILLBOARD02, SPRITES.BILLBOARD03, SPRITES.BILLBOARD04, SPRITES.BILLBOARD05, SPRITES.BILLBOARD06, SPRITES.BILLBOARD07, SPRITES.BILLBOARD08, SPRITES.BILLBOARD09];
  var nature = [SPRITES.PALM_TREE, SPRITES.TREE1, SPRITES.TREE2, SPRITES.BUSH1, SPRITES.BUSH2, SPRITES.CACTUS, SPRITES.BOULDER1, SPRITES.BOULDER2];

  for (var n = 10; n < state.segments.length - 20; n += 4) {
    // Occasional billboard
    if (n % 40 === 0) {
      var bb = billboards[Math.floor(Math.random() * billboards.length)];
      addSprite(state, n, bb, Math.random() > 0.5 ? 1.25 : -1.25);
    }

    // Dense trees, palms, cacti, boulders along both edges
    var vegLeft = nature[Math.floor(Math.random() * nature.length)];
    var vegRight = nature[Math.floor(Math.random() * nature.length)];
    addSprite(state, n, vegLeft, -1.25 - Math.random() * 0.4);
    addSprite(state, n, vegRight, 1.25 + Math.random() * 0.4);
  }

  // Start & Finish Stripes
  if (state.segments[findSegment(state, state.playerZ).index + 2])
    state.segments[findSegment(state, state.playerZ).index + 2].color = COLORS.START;
  if (state.segments[findSegment(state, state.playerZ).index + 3])
    state.segments[findSegment(state, state.playerZ).index + 3].color = COLORS.START;

  for (var r = 0; r < state.rumbleLength; r++) {
    if (state.segments[state.segments.length - 1 - r])
      state.segments[state.segments.length - 1 - r].color = COLORS.FINISH;
  }

  state.trackLength = state.segments.length * state.segmentLength;
}

function resetCars(state) {
  state.cars = [];
  var carSprites = [SPRITES.CAR01, SPRITES.CAR02, SPRITES.CAR03, SPRITES.CAR04, SPRITES.SEMI, SPRITES.TRUCK];
  var count = Math.min(60, Math.floor(state.segments.length / 25));

  for (var i = 0; i < count; i++) {
    var offset = Math.random() * 1.6 - 0.8;
    var z = Math.floor(Math.random() * (state.segments.length - 30) + 15) * state.segmentLength;
    var sprite = carSprites[Math.floor(Math.random() * carSprites.length)];
    var speed = state.maxSpeed / 4 + Math.random() * (state.maxSpeed / 2.2);
    var car = { offset: offset, z: z, sprite: sprite, speed: speed, percent: 0 };
    var seg = findSegment(state, z);
    seg.cars.push(car);
    state.cars.push(car);
  }
}

function findSegment(state, z) {
  return state.segments[Math.floor(z / state.segmentLength) % state.segments.length];
}

function initGameState() {
  var state = {
    fps: 60,
    step: 1 / 60,
    roadWidth: 2000,
    segmentLength: 200,
    rumbleLength: 3,
    trackLength: 0,
    lanes: 3,
    fieldOfView: 100,
    cameraHeight: 1000,
    cameraDepth: null,
    drawDistance: 220,
    playerX: 0,
    playerZ: null,
    fogDensity: 5,
    centrifugal: 0.35,
    position: 0,
    speed: 0,
    maxSpeed: 200 / (1 / 60), // 12000
    accel: 12000 / 4.5,
    breaking: -12000,
    decel: -12000 / 5,
    offRoadDecel: -12000 / 2,
    offRoadLimit: 12000 / 4,
    skyOffset: 0,
    hillOffset: 0,
    treeOffset: 0,
    skySpeed: 0.001,
    hillSpeed: 0.002,
    treeSpeed: 0.003,
    segments: [],
    cars: [],
    keyLeft: false,
    keyRight: false,
    keyFaster: false,
    keySlower: false,
    currentLapTime: 0,
    lastLapTime: null,
    fastestLapTime: null,
    paused: false,
    gameOver: false,
    started: true
  };

  state.cameraDepth = 1 / Math.tan((state.fieldOfView / 2) * Math.PI / 180);
  state.playerZ = (state.cameraHeight * state.cameraDepth);

  buildProceduralRoad(state);
  resetCars(state);

  return state;
}

function tick(state, dt) {
  if (state.paused) return;

  var playerSegment = findSegment(state, state.position + state.playerZ);
  var playerW = SPRITES.PLAYER_STRAIGHT.w * SPRITES.SCALE;
  var speedPercent = state.speed / state.maxSpeed;
  var dx = dt * 2.2 * speedPercent;
  var startPosition = state.position;

  // 1. Update Opponent Cars
  for (var n = 0; n < state.cars.length; n++) {
    var car = state.cars[n];
    var oldSegment = findSegment(state, car.z);
    car.z = increase(car.z, dt * car.speed, state.trackLength);
    car.percent = percentRemaining(car.z, state.segmentLength);
    var newSegment = findSegment(state, car.z);
    if (oldSegment !== newSegment) {
      var idx = oldSegment.cars.indexOf(car);
      if (idx !== -1) oldSegment.cars.splice(idx, 1);
      newSegment.cars.push(car);
    }
  }

  // 2. Player Movement & Physics
  state.position = increase(state.position, dt * state.speed, state.trackLength);

  if (state.keyLeft) state.playerX -= dx;
  else if (state.keyRight) state.playerX += dx;

  state.playerX -= (dx * speedPercent * playerSegment.curve * state.centrifugal);

  if (state.keyFaster) state.speed = accelerate(state.speed, state.accel, dt);
  else if (state.keySlower) state.speed = accelerate(state.speed, state.breaking, dt);
  else state.speed = accelerate(state.speed, state.decel, dt);

  // Off-road collision & decel
  if ((state.playerX < -1) || (state.playerX > 1)) {
    if (state.speed > state.offRoadLimit) {
      state.speed = accelerate(state.speed, state.offRoadDecel, dt);
    }
  }

  // Collision with traffic cars
  for (var c = 0; c < playerSegment.cars.length; c++) {
    var otherCar = playerSegment.cars[c];
    var otherCarW = otherCar.sprite.w * SPRITES.SCALE;
    if (state.speed > otherCar.speed) {
      if (overlap(state.playerX, playerW, otherCar.offset, otherCarW, 0.8)) {
        state.speed = otherCar.speed * (otherCar.speed / state.speed);
        state.position = increase(otherCar.z, -state.playerZ, state.trackLength);
        break;
      }
    }
  }

  state.playerX = limit(state.playerX, -2.5, 2.5);
  state.speed = limit(state.speed, 0, state.maxSpeed);

  // Parallax background offset
  state.skyOffset = increase(state.skyOffset, state.skySpeed * playerSegment.curve * (state.position - startPosition) / state.segmentLength, 1);
  state.hillOffset = increase(state.hillOffset, state.hillSpeed * playerSegment.curve * (state.position - startPosition) / state.segmentLength, 1);
  state.treeOffset = increase(state.treeOffset, state.treeSpeed * playerSegment.curve * (state.position - startPosition) / state.segmentLength, 1);

  // Lap timing & Next procedural map on lap complete!
  if (state.position < startPosition) {
    state.lastLapTime = state.currentLapTime;
    if (!state.fastestLapTime || state.lastLapTime < state.fastestLapTime) {
      state.fastestLapTime = state.lastLapTime;
    }
    state.currentLapTime = 0;
    // Generate a fresh new random track layout for the next lap!
    buildProceduralRoad(state);
    resetCars(state);
  } else {
    state.currentLapTime += dt;
  }
}
