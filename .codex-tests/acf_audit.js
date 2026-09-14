"use strict";
// Read-only audit of the supplied XP12 text ACF. No automatic flight-model rewrites.
const fs = require("node:fs");
const path = require("node:path");
const file = path.resolve(process.argv[2] || path.join(__dirname, "..", "tu154.acf"));
const root = path.dirname(file);
const xp = path.resolve(root, "../../..");
const source = fs.readFileSync(file, "utf8");
const lines = source.split(/\r?\n/);
const props = new Map(), issues = [], candidates = [], families = {};
let section = null, panelGroups = [], instruments = 0;
function issue(line, description) { issues.push({line, description}); }
for (let i = 0; i < lines.length; i++) {
    const line = lines[i], trimmed = line.trim();
    if (/^(PROPERTIES|PANEL_2D|PANEL_3D)_BEGIN$/.test(trimmed)) {
        if (section) issue(i + 1, "Nested top-level section");
        section = trimmed.replace(/_BEGIN$/, "");
        continue;
    }
    if (/^(PROPERTIES|PANEL_2D|PANEL_3D)_END$/.test(trimmed)) {
        if (section !== trimmed.replace(/_END$/, "")) issue(i + 1, "Mismatched section end");
        if (panelGroups.length) issue(i + 1, "Unclosed panel groups");
        section = null;
        continue;
    }
    if (section === "PROPERTIES") {
        const match = line.match(/^P (\S+) (.*)$/);
        if (!match) { if (trimmed) issue(i + 1, "Malformed property line"); continue; }
        const [, key, value] = match;
        if (props.has(key)) issue(i + 1, "Duplicate property " + key);
        props.set(key, {value, line: i + 1});
        families[key.split("/")[0]] = (families[key.split("/")[0]] || 0) + 1;
        if (/^(?:[-+]?inf(?:inity)?|nan)$/i.test(value)) issue(i + 1, "Non-finite numeric value " + key);
    } else if (section && section.startsWith("PANEL")) {
        if (trimmed.startsWith("GROUP ")) panelGroups.push({line: i + 1, name: trimmed.slice(6)});
        if (trimmed === "END_GROUP" && !panelGroups.pop()) issue(i + 1, "Unmatched END_GROUP");
        if (/^(?:gen_|EFIS_|GPS_|rad_|transponder|ann_)/.test(trimmed)) instruments++;
    }
}
if (section) issue(lines.length, "Unclosed top-level section");
if (lines[0] !== "I" || lines[1] !== "1200 Version" || lines[2] !== "ACF") issue(1, "Unexpected XP12 ACF header");
const countArrays = new Map();
for (const [key, record] of props) {
    if (!key.endsWith("/count")) continue;
    const count = Number(record.value), prefix = key.slice(0, -6);
    countArrays.set(prefix, count);
    if (!Number.isInteger(count) || count < 0) issue(record.line, "Invalid array count " + key);
}
for (const [key, record] of props) {
    const segments = key.split("/");
    for (let i = 1; i < segments.length; i++) {
        if (!/^\d+$/.test(segments[i])) continue;
        const prefix = segments.slice(0, i).join("/"), count = countArrays.get(prefix);
        if (count !== undefined && Number(segments[i]) >= count) issue(record.line, "Index outside count: " + key);
    }
}
const resources = [];
for (const [key, {value, line}] of props) {
    if (!/\.(?:obj|afl|png|dds|wav|wpn)$/i.test(value)) continue;
    const locations = [path.join(root, value)];
    if (/\.obj$/i.test(value)) locations.push(path.join(root, "objects", value));
    if (/\.afl$/i.test(value)) locations.push(path.join(root, "airfoils", value), path.join(xp, "Airfoils", value));
    if (/\.wav$/i.test(value)) locations.push(path.join(root, "sounds", "alert", value),
        path.join(xp, "Resources", "sounds", "alert", value));
    resources.push({key, value, line, exists: locations.some(location => fs.existsSync(location))});
}
const missingResources = resources.filter(resource => !resource.exists);
const images = new Map();
for (let i = 0; i < lines.length; i++) {
    const match = lines[i].trim().match(/^IMAGE (.+)$/);
    if (!match || !match[1]) continue;
    const value = match[1], choices = [];
    for (const base of [path.join(root, "cockpit_3d", "generic"), path.join(root, "cockpit", "generic"),
        path.join(xp, "Resources", "bitmaps", "cockpit", "generic")]) {
        for (const suffix of [".png", ".dds", "-1.png", "-1.dds"]) choices.push(path.join(base, value + suffix));
    }
    if (!images.has(value)) images.set(value, {value, line: i + 1, exists: choices.some(location => fs.existsSync(location))});
}
const native = new Set();
const nativeFile = path.join(xp, "Resources", "plugins", "DataRefs.txt");
if (fs.existsSync(nativeFile)) {
    for (const line of fs.readFileSync(nativeFile, "utf8").split(/\r?\n/)) {
        const match = line.match(/^(sim\/\S+)\s/);
        if (match) native.add(match[1]);
    }
}
const missingNative = new Map();
for (let i = 0; i < lines.length; i++) {
    for (const match of lines[i].matchAll(/\bsim\/[A-Za-z0-9_./]+(?:\[\d+\])?/g)) {
        const value = match[0], base = value.replace(/\[\d+\]$/, "");
        if (native.size && !native.has(base)) missingNative.set(value, {value, line: i + 1});
    }
}
for (const [key, {value, line}] of props) {
    if (/_type$/.test(key) && /^_engn\/[012]\//.test(key) && value === "JET_1SPOOL")
        candidates.push({line, key, value, reason: "Verify two-spool D-30 engine and XP12 conversion guidance"});
}
// Broad plausibility checks only: custom Lua systems own many of the native controls.
function number(key) { return Number(props.get(key)?.value); }
function requireCondition(condition, key, description) {
    if (!condition) issue(props.get(key)?.line || 1, description);
}
const tankCount = number("acf/_tank_rat/count");
let tankRatioSum = 0;
for (let i = 0; i < tankCount; i++) {
    const key = "acf/_tank_rat/" + i, ratio = number(key);
    requireCondition(Number.isFinite(ratio) && ratio >= 0 && ratio <= 1, key, "Invalid tank capacity fraction");
    tankRatioSum += ratio;
}
requireCondition(Math.abs(tankRatioSum - 1) < 1e-6, "acf/_tank_rat/count", "Tank capacity fractions do not sum to one");
requireCondition(number("acf/_m_empty") > 0 && number("acf/_m_empty") < number("acf/_m_max"),
    "acf/_m_empty", "Empty mass must be positive and below maximum mass");
requireCondition(number("acf/_cgZ_fwd") <= number("acf/_cgZ") && number("acf/_cgZ") <= number("acf/_cgZ_aft"),
    "acf/_cgZ", "Default longitudinal CG is outside configured limits");
for (let i = 0; i < number("acf/_num_engn"); i++) {
    const key = "_engn/" + i + "/_type";
    requireCondition(props.has(key), key, "Missing active engine type");
}
for (let i = 0; i < number("_gear/count"); i++) {
    const prefix = "_gear/" + i;
    if (!number(prefix + "/_gear_type")) continue;
    requireCondition(number(prefix + "/_tire_radius") > 0, prefix + "/_tire_radius", "Active gear has no positive tire radius");
}
const result = {
    file, lines: lines.length, propertyCount: props.size, families, arrayCounts: countArrays.size,
    panelInstrumentStarts: instruments, issues,
    resourceReferences: resources.length, missingResources,
    uniquePanelImages: images.size, missingPanelImages: [...images.values()].filter(image => !image.exists),
    missingNativeDatarefs: [...missingNative.values()], candidates, tankRatioSum,
    limitations: "Static structure/resource/plausibility audit; missing resources are unresolved references, not proof of an active fault. No simulator or aerodynamic validation.",
};
console.log(JSON.stringify(result, null, 2));
if (issues.length) process.exitCode = 1;
