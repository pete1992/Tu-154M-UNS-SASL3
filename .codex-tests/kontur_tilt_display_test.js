// Static ACF display-wiring/geometry checks, not an X-Plane rendering test.
// Run from the aircraft directory: node .codex-tests/kontur_tilt_display_test.js
const fs = require('fs');
const cp = require('child_process');
const assert = require('assert');
const acf = fs.readFileSync('tu154.acf', 'utf8');
const previous = cp.execFileSync('git', ['show', 'HEAD:tu154.acf'], {
  encoding: 'utf8', maxBuffer: 16 * 1024 * 1024
});
const pattern = /^        gen_(?:rotary|LED) WX_TILT_VALUE(?:_MASK)?_[LR]\r?\n(?:          [^\n]*\r?\n)+\r?\n/gm;
const additions = acf.match(pattern) || [];
assert.strictEqual(additions.length, 4, 'Exactly two masks and two numeric displays');
assert.strictEqual(acf.replace(pattern, ''), previous.replace(pattern, ''),
  'No changes to existing panel elements, visibility, aircraft or radar settings');

const groups = [];
const contexts = {};
for (const line of acf.split(/\r?\n/)) {
  const text = line.trim();
  if (text.startsWith('GROUP ')) groups.push({name: text.slice(6), filters: []});
  else if (text === 'END_GROUP') assert(groups.pop(), 'Unbalanced END_GROUP');
  else if (/^SHOW_/.test(text)) {
    // Only direct group filters (two spaces deeper than GROUP) belong here.
    const indent = line.length - line.trimStart().length;
    if (groups.length && indent === groups.length * 2) groups.at(-1).filters.push(text);
  } else if (/^gen_(rotary|LED) WX_TILT_VALUE/.test(text)) {
    contexts[text.split(' ')[1]] = groups.map(g => ({...g, filters: [...g.filters]}));
  }
}
assert.strictEqual(groups.length, 0, 'All groups closed');
function field(block, key) {
  const match = block.match(new RegExp('^          ' + key + '(?: ([^\\r\\n]*))?$', 'm'));
  assert(match, 'Missing field ' + key);
  return match[1] || '';
}
function pngSize(path) {
  const bytes = fs.readFileSync(path);
  return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
}
assert.deepStrictEqual(pngSize('cockpit_3d/generic/KONTUR/bg_black2-1.png'), [228, 232]);
assert.deepStrictEqual(pngSize('cockpit_3d/generic/TYPE/dig_type_2-4.png'), [224, 144]);
for (const [side, offset, rheostat, mode] of [['L', 0, 14, 'left'], ['R', 499, 15, 'right']]) {
  const mask = additions.find(b => b.includes(`WX_TILT_VALUE_MASK_${side}\n`));
  const number = additions.find(b => b.includes(`WX_TILT_VALUE_${side}\n`));
  assert(mask && number);
  assert.strictEqual(field(mask, 'DATAREF'), '', 'Mask has no writable control');
  assert.strictEqual(field(mask, 'ROTARY_TYPE'), 'NO_CLICK');
  assert.strictEqual(field(mask, 'LIGHT_MODE'), 'GLASS_AUTO', 'Mask must remain opaque');
  assert.strictEqual(field(number, 'DATAREF'), 'tu154/custom/wx2000_tilt');
  assert.strictEqual(field(number, 'DIGITS'), '4');
  assert.strictEqual(field(number, 'DECIMALS'), '1');
  assert.strictEqual(field(number, 'PERIOD_WIDTH'), '3');
  for (const block of [mask, number]) {
    assert.strictEqual(field(block, 'LIGHT_RHEOSTAT'), String(rheostat));
    assert.strictEqual(field(block, 'BUS_SRC'), '1');
  }
  const filters = contexts[`WX_TILT_VALUE_${side}`].flatMap(g => g.filters);
  assert(filters.includes(`SHOW_GREATER 1.000000 tu154/custom/kontur/${mode}_wx`), 'WX visibility retained');
  assert(filters.includes('SHOW_EQUAL 1.000000 tu154/custom/kontur/weather_ready'), 'Readiness retained');
  assert.deepStrictEqual(contexts[`WX_TILT_VALUE_${side}`], contexts[`WX_TILT_VALUE_MASK_${side}`]);
  const [x, y] = field(mask, 'POS').split(' ').map(Number);
  assert.strictEqual(x, 1475.5 + offset);
  const corners = field(mask, 'CORNERS').trim().split(/\s+/).map(Number);
  const left = x - 114 + corners[0], right = x + 114 + corners[6];
  const bottom = y - 116 + corners[1], top = y + 116 + corners[3];
  const originX = 1359 + offset;
  // Measured source-image ink: x106..132,y21..31. Keep label x73..95
  // and frame x135..136,y18..19/33..34 unobscured (small corner skew included).
  assert(left > originX + 96 && left <= originX + 106);
  assert(right >= originX + 133 && right <= originX + 135);
  assert(bottom > -96.2 && bottom < -95.0 && top > -84.0 && top < -82.1);
  const keys = [...number.matchAll(/KEY_FRAME (-?[\d.]+) (-?[\d.]+)/g)].map(m => m.slice(1).map(Number));
  assert.deepStrictEqual(keys, [[-15, -15], [15, 15]], 'Identity mapping preserves sign and degrees');
  for (let halfDegrees = -30; halfDegrees <= 30; halfDegrees++) {
    const value = halfDegrees / 2;
    const mapped = keys[0][1] + (value - keys[0][0]) * (keys[1][1] - keys[0][1]) / (keys[1][0] - keys[0][0]);
    assert.strictEqual(mapped, value);
    assert.strictEqual(Number(mapped.toFixed(1)), value, 'Half-degree steps remain visible');
  }
}
console.log('PASS Kontur TILT: two read-only displays; 61 positions per side; masks, visibility, lighting and existing ACF preserved');
