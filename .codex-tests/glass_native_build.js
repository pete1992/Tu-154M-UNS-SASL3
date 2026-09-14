// Emit an apply_patch patch; never write the source or generated aircraft files.
// Reuse only UV coordinates from the B2 masks. Every position, normal and triangle
// comes from the M's glass.obj, including the original inside/outside separation.
const { obj } = require('./glass_asset_inspection');
const path = require('path');
const fs = require('fs');
const root = path.resolve(__dirname, '..');
const source = obj(path.join(root, 'objects/glass.obj'));
const donor = obj('I:/X-Plane 12/Aircraft/Laminar Research/Tu-154B2-CE-master/objects/Cockpit_glass_out.obj');
const zones = [
    { name: 'left', start: 1644, count: 108, donorStart: 0 },
    { name: 'right', start: 1416, count: 108, donorStart: 378 },
    { name: 'center', start: 1524, count: 120, donorStart: 432 },
];
const models = { rain: [], reflector: [] };
for (const zone of zones) {
    const points = donor.indices.slice(zone.donorStart, zone.donorStart + zone.count / 2).map(i => donor.vertices[i]);
    const outside = [...new Set(source.indices.slice(zone.start, zone.start + zone.count))].map(i => source.vertices[i]).filter(v => v[4] > 0);
    function outsideUV(v) {
        // Y/Z geometry is shared to 10 micrometres; B2's different window width
        // must not be transplanted into this aircraft. X only resolves the two
        // mirrored corners of the narrow center pane at identical Y/Z.
        const candidates = points.filter(q => Math.hypot(q[1] - v[1], q[2] - v[2]) < 0.00002);
        if (!candidates.length) throw new Error('No measured donor UV match: ' + zone.name);
        candidates.sort((a,b) => Math.abs(a[0] - v[0]) - Math.abs(b[0] - v[0]));
        return candidates[0].slice(6,8);
    }
    const groups = { rain: [], reflector: [] };
    for (let i = zone.start; i < zone.start + zone.count; i += 3) {
        const triangle = source.indices.slice(i, i + 3).map(j => source.vertices[j]);
        const kind = triangle[0][4] > 0 ? 'rain' : 'reflector';
        for (const vertex of triangle) {
            let match = vertex;
            if (kind === 'reflector') {
                match = outside.reduce((a,b) => Math.hypot(...[0,1,2].map(k=>b[k]-vertex[k])) < Math.hypot(...[0,1,2].map(k=>a[k]-vertex[k])) ? b : a);
                if (Math.hypot(...[0,1,2].map(k=>match[k]-vertex[k])) > 0.01) throw new Error('Unmatched inside pane vertex');
            }
            groups[kind].push([...vertex.slice(0,6), ...outsideUV(match)]);
        }
    }
    for (const kind of Object.keys(models)) models[kind].push({ name: zone.name, vertices: groups[kind] });
}
function render(kind) {
    const vertices = models[kind].flatMap(g => g.vertices);
    const lines = [
        'I', '800', 'OBJ', '',
        '# XP12 front windows: original M positions, normals and winding retained.',
        '# Only UVs are mapped to the existing three-zone heat and wiper textures.',
        '# Mask UVs are preserved exactly; do not move them to hide thermal-mask seals.',
        'TEXTURE glass2.png', 'TEXTURE_NORMAL glass_NML.png',
        'GLOBAL_specular 1.0', 'BLEND_GLASS', 'RAIN_scale 0.5', '',
    ];
    if (kind === 'rain') lines.push(
        'THERMAL_texture windshield_thermal_out.png',
        'THERMAL_source2 0 tu154/custom/antiice/window_heat_time_1 sim/cockpit2/ice/ice_window_heat_running[0]',
        'THERMAL_source2 1 tu154/custom/antiice/window_heat_time_3 sim/cockpit2/ice/ice_window_heat_running[1]',
        'THERMAL_source2 2 tu154/custom/antiice/window_heat_time_2 sim/cockpit2/ice/ice_window_heat_running[2]',
        '', 'WIPER_texture wiper_out.png',
        'WIPER_param tu154/custom/anim/wiper_angle_left 0.0 62.0',
        'WIPER_param tu154/custom/anim/wiper_angle_right 0.0 62.0', '',
    );
    lines.push('POINT_COUNTS ' + vertices.length + ' 0 0 ' + vertices.length);
    for (const v of vertices) lines.push('VT ' + v.map((n,k) => n.toFixed(k < 6 ? 6 : 8)).join(' '));
    for (let i = 0; i < vertices.length; i += 3) lines.push('IDX ' + i, 'IDX ' + (i+1), 'IDX ' + (i+2));
    let start = 0;
    for (const group of models[kind]) {
        lines.push('# ' + group.name + ' front pane', 'TRIS ' + start + ' ' + group.vertices.length, 'TRIS_break');
        start += group.vertices.length;
    }
    return lines.join('\n') + '\n';
}
if (require.main === module) {
    console.log('*** Begin Patch');
    for (const kind of Object.keys(models)) {
        const target = path.join(root, 'objects/glass_front_' + kind + '.obj').replaceAll('\\','/');
        if (fs.existsSync(target)) {
            console.log('*** Update File: ' + target);
            console.log('@@');
            console.log(fs.readFileSync(target, 'utf8').trimEnd().split(/\r?\n/).map(l=>'-'+l).join('\n'));
        } else console.log('*** Add File: ' + target);
        console.log(render(kind).trimEnd().split('\n').map(l=>'+'+l).join('\n'));
    }
    console.log('*** End Patch');
}
module.exports = { models, render };
