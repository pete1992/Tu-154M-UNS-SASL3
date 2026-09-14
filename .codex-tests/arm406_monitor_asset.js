// Reproducible, synthetic PDU monitor tone. No borrowed/FMOD audio or radio output.
// Run from the aircraft directory to generate the new WAV, never another asset.
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const target = path.resolve('plugins/sasl/data/modules/Custom Module/Custom Sounds/arm406_monitor.wav');
const rate = 22050, seconds = 1, count = rate * seconds;
const wav = Buffer.alloc(44 + count * 2);
wav.write('RIFF', 0); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
wav.writeUInt32LE(rate, 24); wav.writeUInt32LE(rate * 2, 28);
wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
wav.write('data', 36); wav.writeUInt32LE(count * 2, 40);
let phase = 0;
for (let i = 0; i < count; i++) {
    const t = (i / rate) % 0.25;
    phase += 2 * Math.PI * (1500 - 1000 * t / 0.25) / rate;
    // Smooth edges keep each sweep and the one-second loop free of clicks.
    const envelope = Math.min(1, t / 0.008, (0.25 - t) / 0.008);
    wav.writeInt16LE(Math.round(8000 * envelope * Math.sin(phase)), 44 + i * 2);
}
if (fs.existsSync(target)) {
    assert(fs.readFileSync(target).equals(wav), 'Existing audio differs; refusing to overwrite it');
    console.log('PASS ARM-406 monitor WAV matches its generator');
} else {
    fs.writeFileSync(target, wav, {flag: 'wx'});
    console.log('Created synthetic ARM-406 monitor WAV:', target);
}
