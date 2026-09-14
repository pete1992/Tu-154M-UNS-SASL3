// Offline structural and control-texture tests. This is not an X-Plane render test.
const assert = require('assert/strict');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { obj, png } = require('./glass_asset_inspection');
const root = path.resolve(__dirname, '..');
process.chdir(root);
const original = obj('objects/glass.obj');
const rain = obj('objects/glass_front_rain.obj');
const inside = obj('objects/glass_front_reflector.obj');
const thermal = png('objects/windshield_thermal_out.png');
const wipers = png('objects/wiper_out.png');
const zones = [
    { start: 1644, count: 108, channel: 0 },
    { start: 1416, count: 108, channel: 1 },
    { start: 1524, count: 120, channel: 2 },
];
// Pin the original mesh instead of comparing the fixed file to itself after commit.
const old = execFileSync('git', ['show', 'aca27493585630980ba9ed35b21942981809c766:objects/glass.obj'], { encoding: 'utf8' });
const geometryLines = text => text.split(/\r?\n/).filter(l => /^(?:VT|IDX|IDX10|POINT_COUNTS)\s/.test(l));
assert.deepEqual(geometryLines(original.text), geometryLines(old), 'The existing cabin/window geometry and UVs must be byte-for-byte unchanged');
assert(!/^TEXTURE_LIT\s/m.test(original.text), 'Opaque dark frosting must not return as the passenger-glass LIT material');
const drawRange = [];
let drawing = true;
for (const line of original.lines) {
    if (line.trim() === 'ATTR_draw_disable') drawing = false;
    if (line.trim() === 'ATTR_draw_enable') drawing = true;
    const match = line.match(/^\s*TRIS\s+(\d+)\s+(\d+)/);
    if (match) drawRange.push({ start: +match[1], count: +match[2], drawing });
}
assert(drawRange.find(g => g.start === 648 && g.count === 768).drawing, 'Passenger glazing stays drawn');
for (const start of [1968,2016,2064]) assert(drawRange.find(g => g.start === start).drawing, 'Passenger door glazing stays drawn');
for (const zone of zones) assert.equal(drawRange.find(g => g.start === zone.start).drawing, false, 'No duplicate legacy front-pane pass');
const clear = png('objects/glass2.png');
assert.equal(clear.channels, 4);
for (let i = 3; i < clear.data.length; i += 4) assert.equal(clear.data[i], 0, 'Existing clear glass must stay transparent');
const expected = { rain: [], inside: [] };
for (const zone of zones) for (let i = zone.start; i < zone.start + zone.count; i += 3) {
    const triangle = original.indices.slice(i, i + 3).map(j => original.vertices[j]);
    expected[triangle[0][4] > 0 ? 'rain' : 'inside'].push(...triangle.map(v => v.slice(0,6)));
}
for (const [name,model] of [['rain',rain],['inside',inside]]) {
    const counts = model.text.match(/^POINT_COUNTS\s+(\d+)\s+0\s+0\s+(\d+)$/m);
    assert.equal(model.vertices.length, +counts[1]);
    assert.equal(model.indices.length, +counts[2]);
    assert.deepEqual(model.indices.map(i => model.vertices[i].slice(0,6)), expected[name], 'Positions, normals and winding must match the M, not donor geometry');
    assert(model.indices.every(i => Number.isInteger(i) && i >= 0 && i < model.vertices.length));
    assert(model.vertices.every(v => v.length === 8 && v.every(Number.isFinite)));
    assert(!/tu154(?:ce|b2)\//.test(model.text));
    assert(!/NORMAL_METALNESS|TEXTURE_LIT/.test(model.text), 'Clear dielectric glass, not a metal or dark frost material');
    for (const texture of model.text.matchAll(/^(?:TEXTURE(?:_NORMAL)?|THERMAL_texture|WIPER_texture)\s+(.+)$/gm)) assert(fs.existsSync(path.join('objects', texture[1].trim())));
    assert.equal((model.text.match(/^TRIS_break$/gm) || []).length, 3, 'Rain stays within each pane');
}
// The separately loaded cockpit_glass.obj contains instruments and sun visors,
// not a second coplanar windshield. Check projected triangle centers to catch an
// accidental addition of another glass pass at the new front-pane positions.
const cockpit = obj('objects/cockpit_glass.obj');
const sub = (a,b) => a.map((v,k)=>v-b[k]);
const dot = (a,b) => a.reduce((n,v,k)=>n+v*b[k],0);
const cross = (a,b) => [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
for (let i = 0; i < cockpit.indices.length; i += 3) {
    const points = cockpit.indices.slice(i,i+3).map(j=>cockpit.vertices[j]);
    const center = [0,1,2].map(k=>points.reduce((sum,v)=>sum+v[k],0)/3);
    for (let j = 0; j < rain.indices.length; j += 3) {
        const tri = rain.indices.slice(j,j+3).map(k=>rain.vertices[k].slice(0,3));
        const a = sub(tri[1],tri[0]), b = sub(tri[2],tri[0]), z = sub(center,tri[0]);
        const normal = cross(a,b), aa=dot(a,a), bb=dot(b,b), ab=dot(a,b), az=dot(a,z), bz=dot(b,z), denominator=aa*bb-ab*ab;
        if (Math.abs(denominator) < 1e-18) continue;
        const u=(bb*az-ab*bz)/denominator, v=(aa*bz-ab*az)/denominator;
        if (u>=0 && v>=0 && u+v<=1) assert(Math.abs(dot(z,normal))/Math.hypot(...normal)>0.02, 'No duplicate coplanar cockpit-glass pass');
    }
}
assert.deepEqual([...rain.text.matchAll(/^WIPER_param\s+(\S+)\s+0\.0\s+62\.0$/gm)].map(m=>m[1]), ['tu154/custom/anim/wiper_angle_left', 'tu154/custom/anim/wiper_angle_right']);
assert(rain.text.includes('THERMAL_source2 0 tu154/custom/antiice/window_heat_time_1 sim/cockpit2/ice/ice_window_heat_running[0]'));
assert(rain.text.includes('THERMAL_source2 1 tu154/custom/antiice/window_heat_time_3 sim/cockpit2/ice/ice_window_heat_running[1]'));
assert(rain.text.includes('THERMAL_source2 2 tu154/custom/antiice/window_heat_time_2 sim/cockpit2/ice/ice_window_heat_running[2]'));
assert(!/^THERMAL_source2 3 /m.test(rain.text), 'Unused mask alpha must not heat all three panes');
let samples = 0;
const heatedSamples = [0,0,0];
const zoneSamples = [0,0,0];
const sweepSamples = [0, 0];
const sweepRange = [[255,0], [255,0]];
const crossChannel = [0,0];
let start = 0;
for (const zone of zones) {
    for (let i = start; i < start + zone.count / 2; i += 3) {
        const vertices = rain.indices.slice(i, i + 3).map(j => rain.vertices[j]);
        for (let a = 0; a <= 40; a++) for (let b = 0; b <= 40-a; b++) {
            const uv = [6,7].map(k => (vertices[0][k]*a + vertices[1][k]*b + vertices[2][k]*(40-a-b))/40);
            zoneSamples[zone.channel]++;
            if (thermal.at(...uv)[zone.channel] > 0) heatedSamples[zone.channel]++;
            samples++;
            if (zone.channel < 2) {
                const mask = wipers.at(...uv);
                // The existing atlas contains a few low-level paint/antialias pixels
                // in its unused channels. They must never contain the other sweep.
                assert(mask[1-zone.channel] <= 12, 'No opposite-side swept gradient');
                if (mask[1-zone.channel] > 0) crossChannel[zone.channel]++;
                if (mask[zone.channel] > 0) {
                    sweepSamples[zone.channel]++;
                    sweepRange[zone.channel][0] = Math.min(sweepRange[zone.channel][0], mask[zone.channel]);
                    sweepRange[zone.channel][1] = Math.max(sweepRange[zone.channel][1], mask[zone.channel]);
                }
            }
        }
    }
    start += zone.count / 2;
}
for (let zone = 0; zone < 3; zone++) assert(heatedSamples[zone] / zoneSamples[zone] > 0.95, 'Heat mask must cover the pane, allowing only its existing narrow seal border');
for (let side = 0; side < 2; side++) {
    assert(crossChannel[side] / zoneSamples[side] < 0.005, 'Only isolated low-level cross-channel pixels are allowed');
    assert(sweepSamples[side] > 1000, 'Wiper must cover a substantial sample of its pane');
    assert(sweepRange[side][1] - sweepRange[side][0] > 100, 'Wiper mask must be a real swept gradient');
}
// Equal sampling per triangle overrepresents the many tiny seal triangles.
// Weight each local sample by physical triangle area for meaningful sweep coverage.
const physicalCoverage = [];
for (let side = 0; side < 2; side++) {
    let paneArea = 0, sweptArea = 0;
    for (let i = side * 54; i < side * 54 + 54; i += 3) {
        const p = rain.indices.slice(i,i+3).map(j=>rain.vertices[j]);
        const triangleArea = Math.hypot(...cross(sub(p[1].slice(0,3),p[0].slice(0,3)),sub(p[2].slice(0,3),p[0].slice(0,3))))/2;
        let count = 0, cleared = 0;
        for (let a=1; a<50; a++) for (let b=1; b<50-a; b++) {
            const uv = [6,7].map(k=>(p[0][k]*a+p[1][k]*b+p[2][k]*(50-a-b))/50);
            count++;
            if (wipers.at(...uv)[side]>16) cleared++;
        }
        paneArea += triangleArea;
        sweptArea += triangleArea * cleared/count;
    }
    const ratio = sweptArea / paneArea;
    assert(ratio>0.4 && ratio<0.5, 'Preserve the measured partial sweep, not only a few edge samples or the entire pane');
    physicalCoverage.push({ paneArea, sweptArea, ratio });
}
const acf = fs.readFileSync('tu154.acf','utf8');
assert(/^P _obja\/27\/_v10_att_file_stl glass_front_rain\.obj\r?$/m.test(acf));
assert(/^P _obja\/27\/_obj_flags 8194\r?$/m.test(acf));
assert(/^P _obja\/28\/_v10_att_file_stl glass_front_reflector\.obj\r?$/m.test(acf));
assert(/^P _obja\/28\/_obj_flags 8195\r?$/m.test(acf));
assert(!/^P _obja\/\d+\/_v10_att_file_stl (?:drops|snow)_window\.obj\r?$/m.test(acf));
console.log('PASS: exact M mesh preservation, clear passenger glazing, native ACF bindings, independent heater/wiper channels.');
console.log('Thermal samples:', samples, 'coverage by pane:', heatedSamples.map((n,i)=>(100*n/zoneSamples[i]).toFixed(2)+'%').join(', '));
console.log('Swept-mask samples:', sweepSamples.join(', '), 'ranges:', JSON.stringify(sweepRange));
console.log('Retained low-level cross-channel atlas pixels:', crossChannel.join(', '));
console.log('Physical swept area by pane:', JSON.stringify(physicalCoverage));
console.log('Existing narrow left thermal-mask seal is retained to preserve exact blade-mask alignment; visual cockpit testing remains required.');
