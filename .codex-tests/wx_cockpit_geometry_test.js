// Offline OBJ validation. Run from the aircraft directory; no simulator connection.
const fs = require('fs');
const cp = require('child_process');
const assert = require('assert');
function parse(text) {
  const lines = text.split(/\r?\n/);
  const vertices = [], indices = [], draws = [], vtLines = [], idxLines = [];
  let counts, depth = 0, keys = 0;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line || line.startsWith('#')) continue;
    const p = line.split(/\s+/);
    if (p[0] === 'POINT_COUNTS') counts = p.slice(1).map(Number);
    if (p[0] === 'VT') {
      const v = p.slice(1).map(Number);
      assert(v.length === 8 && v.every(Number.isFinite), `Bad VT at ${i + 1}`);
      vertices.push(v); vtLines.push(lines[i]);
    }
    if (p[0] === 'IDX' || p[0] === 'IDX10') {
      assert(p.length === (p[0] === 'IDX10' ? 11 : 2), `Bad IDX at ${i + 1}`);
      indices.push(...p.slice(1).map(Number)); idxLines.push(lines[i]);
    }
    if (p[0] === 'ANIM_begin') depth++;
    if (p[0] === 'ANIM_end') assert(--depth >= 0, `Unbalanced ANIM at ${i + 1}`);
    if (p[0] === 'ANIM_rotate_begin') keys++;
    if (p[0] === 'ANIM_rotate_end') assert(--keys >= 0, `Unbalanced rotation keys at ${i + 1}`);
    if (p[0] === 'TRIS') draws.push(p.slice(1).map(Number));
  }
  assert(counts && counts[0] === vertices.length && counts[3] === indices.length, 'POINT_COUNTS mismatch');
  assert(depth === 0 && keys === 0, 'Unclosed animation');
  assert(indices.every(i => Number.isInteger(i) && i >= 0 && i < vertices.length), 'Index outside vertex table');
  const coverage = Array(indices.length).fill(0);
  for (const [start, count] of draws) {
    assert(Number.isInteger(start) && Number.isInteger(count) && start >= 0 && count % 3 === 0 && start + count <= indices.length, 'Bad TRIS range');
    for (let j = start; j < start + count; j++) coverage[j]++;
  }
  return {vertices, indices, draws, counts, vtLines, idxLines, coverage};
}
for (const file of ['objects/gns430.obj', 'tu154_cockpit.obj']) {
  const beforeText = cp.execFileSync('git', ['show', `HEAD:${file}`], {encoding: 'utf8', maxBuffer: 16 * 1024 * 1024});
  const afterText = fs.readFileSync(file, 'utf8');
  const before = parse(beforeText), after = parse(afterText);
  assert.deepStrictEqual(after.vtLines.slice(0, before.vtLines.length), before.vtLines, `${file}: old vertex/UV data changed`);
  assert.deepStrictEqual(after.indices.slice(0, before.indices.length), before.indices, `${file}: old indices changed`);
  assert.deepStrictEqual(after.coverage.slice(0, before.coverage.length), before.coverage, `${file}: old triangles omitted or duplicated`);
  if (file.startsWith('objects/')) {
    assert.deepStrictEqual(after.counts, before.counts, 'Visible OBJ geometry counts changed');
    assert(afterText.includes('ANIM_rotate_key 3.000000'), 'MAP animation missing');
    assert(afterText.includes('tu154/custom/wx2000_windshear'), 'Windshear animation missing');
    const tiltBlock = text => text.match(/# WX2000 TILT[\s\S]*?ANIM_end/)[0];
    assert.strictEqual(tiltBlock(afterText), tiltBlock(beforeText), 'Working visible tilt animation changed');
  } else {
    const addedQuad = beforeText.includes('tu154/custom/wx2000_windshear') ? 0 : 1;
    assert(after.vertices.length === before.vertices.length + 4 * addedQuad, 'Expected only one new click quad');
    assert(after.indices.length === before.indices.length + 6 * addedQuad, 'Expected only two new click triangles');
    assert(after.coverage.slice(before.coverage.length).every(n => n === 1), 'New click quad coverage wrong');
    assert(afterText.includes('ATTR_manip_axis_knob rotate_medium 0.000000 3.000000 1.000000 1.000000 tu154/custom/kontur/weather_mode'), 'Mode selector must expose 4 detents');
    assert(afterText.includes('ATTR_manip_toggle left_right 1.000000 0.000000 tu154/custom/wx2000_windshear'), 'Windshear click binding missing');
    const tiltBlock = text => text.match(/# WX2000 TILT: half-degree[^\n]*\nANIM_begin[\s\S]*?ANIM_end/)[0];
    assert(tiltBlock(afterText) === tiltBlock(beforeText), 'Working tilt manipulator changed');
    const bounds = start => {
      const vertices = after.indices.slice(start, start + 6).map(i => after.vertices[i]);
      return [0, 1, 2].map(axis => [Math.min(...vertices.map(v => v[axis])), Math.max(...vertices.map(v => v[axis]))]);
    };
    const windshear = bounds(22863), selector = bounds(22017), tilt = bounds(22857), gain = bounds(22011);
    const overlaps = (a, b) => a[0][0] < b[0][1] && a[0][1] > b[0][0] && a[1][0] < b[1][1] && a[1][1] > b[1][0];
    assert(!overlaps(windshear, selector) && !overlaps(windshear, tilt) && !overlaps(windshear, gain), 'Windshear click area overlaps an adjacent WX control');
    // Mirrored endpoints measured from the existing movable stem, not the ring.
    assert(windshear[0][0] < 0.2124809 && windshear[0][1] > 0.229965, 'Click quad misses an AUTO/OFF endpoint');
  }
  console.log(`PASS ${file}: ${after.vertices.length} vertices, ${after.indices.length} indices, ${after.draws.length} draws; old geometry/UVs/coverage preserved`);
}
