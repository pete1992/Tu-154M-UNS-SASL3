"use strict";
// Verify the reviewed edit boundary against the immutable, user-requested backup.
// This checks file integrity, not engine performance in the simulator.
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");
const assert = require("node:assert/strict");
const cp = require("node:child_process");
const root = path.resolve(__dirname, "..");
const backup = fs.readFileSync(path.join(root, "tu154.acf.bak"));
const current = fs.readFileSync(path.join(root, "tu154.acf"));
assert.equal(crypto.createHash("sha256").update(backup).digest("hex"),
    "889db84e1cbdee3d3801eeed161ad222d3bc52a4ca983d164ffdd646a25ce2bc", "Original backup must remain unchanged");
const before = backup.toString("utf8"), after = current.toString("utf8");
const expectedEdits = [
    ["_engn/0/_type", "JET_1SPOOL", "JET_2SPOOL"],
    ["_engn/1/_type", "JET_1SPOOL", "JET_2SPOOL"],
    ["_engn/2/_type", "JET_1SPOOL", "JET_2SPOOL"],
    ["acf/_jet_SFC_hicrz", "0.497999996", "0.728999972"],
    ["acf/_jet_SFC_takeoff", "0.728999972", "0.497999996"],
];
let expected = before;
for (const [key, oldValue, newValue] of expectedEdits) {
    const oldLine = `P ${key} ${oldValue}\n`;
    assert.equal(expected.split(oldLine).length - 1, 1, `Unique original property ${key}`);
    expected = expected.replace(oldLine, `P ${key} ${newValue}\n`);
}
assert.equal(after, expected, "Only the five reviewed property lines may change; all other bytes must match");
assert.equal(after.slice(after.indexOf("PANEL_2D_BEGIN")), before.slice(before.indexOf("PANEL_2D_BEGIN")),
    "Preserve all panel geometry, NAV/TCAS/WX wiring and Tilt graphics");
const audit = JSON.parse(cp.execFileSync(process.execPath, [path.join(__dirname, "acf_audit.js")], {encoding: "utf8"}));
assert.deepEqual(audit.issues, []);
assert.deepEqual(audit.missingPanelImages, []);
assert.deepEqual(audit.missingNativeDatarefs, []);
assert.deepEqual(audit.candidates, []);
assert(audit.missingResources.every(resource => resource.key.startsWith("acf/_ann_wav_file/")),
    "No missing objects, airfoils or image references");
console.log("PASS: immutable backup, five exact edits, byte-identical remaining ACF and panels, static ACF audit.");
console.log("Open legacy sound references: " + [...new Set(audit.missingResources.map(resource => resource.value))].join(", "));
