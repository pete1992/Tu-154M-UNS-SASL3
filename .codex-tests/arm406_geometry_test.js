// Run from the live aircraft root. Reads complete OBJs; no simulator connection.
const fs = require('fs');
const cp = require('child_process');
const assert = require('assert');
const root = 'tu154_cockpit.obj';
const panel = 'objects/cockpit_center_panel_RUS.obj';
const lamps = 'objects/cockpit_lamps_RUS.obj';
const source = 'plugins/sasl/data/modules/Custom Module/main_panel/arm406.lua';
function parse(text) {
    const vertices = [], indices = [], draws = [], commands = [];
    let counts, depth = 0;
    for (const raw of text.split(/\r?\n/)) {
        const p = raw.trim().split(/\s+/), op = p[0];
        if (!op || op === '#') continue;
        if (op === 'POINT_COUNTS') counts = p.slice(1).map(Number);
        else if (op === 'VT') {
            const v = p.slice(1).map(Number);
            assert(v.length === 8 && v.every(Number.isFinite)); vertices.push(v);
        } else if (op === 'IDX' || op === 'IDX10') {
            assert(p.length === (op === 'IDX' ? 2 : 11)); indices.push(...p.slice(1).map(Number));
        } else {
            commands.push(raw);
            if (op === 'ANIM_begin') depth++;
            if (op === 'ANIM_end') assert(--depth >= 0, 'Animation underflow');
            if (op === 'TRIS') draws.push(p.slice(1).map(Number));
        }
    }
    assert(depth === 0 && counts[0] === vertices.length && counts[3] === indices.length);
    assert(indices.every(i => Number.isInteger(i) && i >= 0 && i < vertices.length));
    const coverage = Array(indices.length).fill(0);
    for (const [start, count] of draws) {
        assert(start >= 0 && count % 3 === 0 && start + count <= indices.length);
        for (let i = start; i < start + count; i++) coverage[i]++;
    }
    return {vertices, indices, coverage, commands, counts};
}
const current = {};
for (const file of [root, panel, lamps]) {
    const base = parse(cp.execFileSync('git', ['show', `HEAD:${file}`], {encoding: 'utf8', maxBuffer: 12e6}));
    const obj = parse(fs.readFileSync(file, 'utf8')); current[file] = obj;
    assert.deepStrictEqual(obj.vertices.slice(0, base.vertices.length), base.vertices, `${file}: old geometry/UV changed`);
    assert.deepStrictEqual(obj.indices.slice(0, base.indices.length), base.indices, `${file}: old indices changed`);
    assert.deepStrictEqual(obj.coverage.slice(0, base.coverage.length), base.coverage, `${file}: old triangles duplicated/omitted`);
    const baseHasArm = base.commands.some(s => s.includes('tu154/custom/arm406/'));
    const quads = file === panel || baseHasArm ? 0 : 3;
    assert(obj.vertices.length === base.vertices.length + quads * 4);
    assert(obj.indices.length === base.indices.length + quads * 6);
    assert(obj.coverage.slice(base.coverage.length).every(n => n === 1));
    // Every new quad is planar, nondegenerate and wound toward the +Y cockpit side.
    const armStart = file === root ? 22869 : file === lamps ? 128082 : obj.indices.length;
    for (let i = armStart; i < obj.indices.length; i += 3) {
        const [a, b, c] = obj.indices.slice(i, i + 3).map(n => obj.vertices[n]);
        assert(a[1] === b[1] && b[1] === c[1]);
        assert((b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]) > 0);
    }
    for (const opcode of ['TEXTURE', 'TEXTURE_LIT', 'TEXTURE_NORMAL', 'GLOBAL_specular']) {
        assert.deepStrictEqual(obj.commands.filter(s => s.startsWith(opcode + ' ')), base.commands.filter(s => s.startsWith(opcode + ' ')));
    }
    if (file === root) {
        const oldManips = base.commands.filter(s => s.startsWith('ATTR_manip_') && !s.includes('ARM-406'));
        const newManips = obj.commands.filter(s => s.startsWith('ATTR_manip_') && !s.includes('ARM-406'));
        assert.deepStrictEqual(newManips, oldManips, 'An existing manipulator changed');
        const push = obj.commands.filter(s => s.startsWith('ATTR_manip_push') && s.includes('ARM-406'));
        assert(push.length === 3 && push.every(s => s.startsWith('ATTR_manip_push button 1.000000 0.000000')));
    }
    console.log(`PASS ${file}: counts, winding, animation balance, old mesh/UVs and triangle coverage`);
}
function bounds(obj, start, count = 6) {
    const points = obj.indices.slice(start, start + count).map(n => obj.vertices[n]);
    return [0, 1, 2].map(k => [Math.min(...points.map(p => p[k])), Math.max(...points.map(p => p[k]))]);
}
for (const [click, mesh, start, count] of [[22869, panel, 108, 6], [22875, lamps, 115968, 78], [22881, lamps, 116046, 78]]) {
    const a = bounds(current[root], click), b = bounds(current[mesh], start, count);
    assert.deepStrictEqual(a[0], b[0]); assert.deepStrictEqual(a[2], b[2]);
    assert(Math.abs(a[1][0] - b[1][1] - 0.0001) < 1e-7, 'Click plane must be 0.1 mm ahead of the original face');
}
const manual = bounds(current[root], 22869), test = bounds(current[root], 22875), mute = bounds(current[root], 22881);
assert(manual[0][1] < test[0][0] && test[0][1] < mute[0][0], 'PDU hitboxes overlap');

const lua = fs.readFileSync(source, 'utf8');
assert(!/has_crashed|g_nrml|set\([^,]*(?:com|freq)|tu154b2|sim\/custom\/arm406/.test(lua), 'Out-of-scope input/output');
const bindings = [...lua.matchAll(/\{ "[^"]+", "([^"]+)", (?:newInt|newFloat|globalPropertyi|globalPropertyf) \}/g)].map(m => m[1]);
for (const file of [root, panel, lamps]) {
    for (const ref of fs.readFileSync(file, 'utf8').matchAll(/tu154\/custom\/arm406\/\w+/g)) {
        assert(bindings.includes(ref[0]), `Uncreated cockpit DataRef ${ref[0]}`);
    }
}
const host = fs.readFileSync('plugins/sasl/data/modules/Custom Module/main_panel/main_panel.lua', 'utf8');
assert((host.match(/\barm406\s*\{/g) || []).length === 1, 'SASL component must be registered once');
// Validate every top-level panel child resolves in the existing search directory.
for (const match of host.matchAll(/^\t([a-zA-Z0-9_]+)\s*\{/gm)) {
    const name = match[1], directory = 'plugins/sasl/data/modules/Custom Module/main_panel/';
    assert(fs.existsSync(directory + name + '.lua') || fs.existsSync(directory + name + '/' + name + '.lua'), `Unresolved child ${name}`);
}
console.log('PASS PDU hitboxes, control bindings, manual-only inputs and SASL component registration');
