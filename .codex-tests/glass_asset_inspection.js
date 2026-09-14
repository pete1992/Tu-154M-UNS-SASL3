// Read-only inspection of OBJ triangle groups and existing PNG control textures.
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');
function png(file) {
    const b = fs.readFileSync(file), idat = [];
    let width, height, channels, palette, transparency;
    for (let p = 8; p < b.length;) {
        const n = b.readUInt32BE(p), type = b.toString('ascii', p + 4, p + 8), d = b.subarray(p + 8, p + 8 + n);
        if (type === 'IHDR') {
            width = d.readUInt32BE(0); height = d.readUInt32BE(4);
            if (d[8] !== 8 || d[12] !== 0 || ![2, 3, 6].includes(d[9])) throw new Error('Unsupported PNG: ' + file);
            channels = d[9] === 6 ? 4 : d[9] === 3 ? 1 : 3;
        }
        if (type === 'PLTE') palette = d;
        if (type === 'tRNS') transparency = d;
        if (type === 'IDAT') idat.push(d);
        p += n + 12;
    }
    const packed = zlib.inflateSync(Buffer.concat(idat)), stride = width * channels;
    let data = Buffer.alloc(height * stride);
    for (let y = 0; y < height; y++) {
        const filter = packed[y * (stride + 1)];
        for (let x = 0; x < stride; x++) {
            const a = x >= channels ? data[y * stride + x - channels] : 0;
            const c = y && x >= channels ? data[(y - 1) * stride + x - channels] : 0;
            const up = y ? data[(y - 1) * stride + x] : 0;
            const predictor = a + up - c, da = Math.abs(predictor - a), db = Math.abs(predictor - up), dc = Math.abs(predictor - c);
            const v = [0, a, up, Math.floor((a + up) / 2), da <= db && da <= dc ? a : db <= dc ? up : c][filter];
            if (v === undefined) throw new Error('Unknown PNG filter');
            data[y * stride + x] = (packed[y * (stride + 1) + x + 1] + v) & 255;
        }
    }
    if (channels === 1) {
        if (!palette) throw new Error('Missing palette: ' + file);
        const rgba = Buffer.alloc(width * height * 4);
        for (let i = 0; i < data.length; i++) {
            const index = data[i];
            for (let k = 0; k < 3; k++) rgba[i * 4 + k] = palette[index * 3 + k];
            rgba[i * 4 + 3] = transparency && index < transparency.length ? transparency[index] : 255;
        }
        data = rgba;
        channels = 4;
    }
    return { width, height, channels, data, at(u, v) {
        const x = Math.max(0, Math.min(width - 1, Math.floor(u * width)));
        const y = Math.max(0, Math.min(height - 1, Math.floor((1 - v) * height)));
        const n = (y * width + x) * channels;
        return Array.from(data.subarray(n, n + channels));
    }};
}
function obj(file) {
    const text = fs.readFileSync(file, 'utf8'), lines = text.split(/\r?\n/);
    const vertices = lines.filter(l => /^VT\s/.test(l)).map(l => l.trim().split(/\s+/).slice(1).map(Number));
    const indices = lines.filter(l => /^IDX(?:10)?\s/.test(l)).flatMap(l => l.trim().split(/\s+/).slice(1).map(Number));
    return { text, lines, vertices, indices };
}
if (require.main === module) {
    const root = path.resolve(__dirname, '..', 'objects');
    const glass = obj(path.join(root, 'glass_ext_xp12.obj'));
    const thermal = png(path.join(root, 'glass_THERMAL.png')), wiper = png(path.join(root, 'wipers.png'));
    for (let i = 0; i < 984; i += 3) {
        const points = glass.indices.slice(i, i + 3).map(j => glass.vertices[j]);
        const mean = Array.from({length: 8}, (_, j) => points.reduce((n, v) => n + v[j], 0) / 3);
        if (mean[2] < -19) console.log(JSON.stringify({ i, xyz: mean.slice(0,3), uv: mean.slice(6,8), heat: thermal.at(mean[6], mean[7]), wipe: wiper.at(mean[6], mean[7]) }));
    }
}
module.exports = { png, obj };
