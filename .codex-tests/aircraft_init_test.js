// Fengari omits io.open. Supply read-only test file access, then execute the
// same Lua assertions that also run under a native Lua interpreter.
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/fengari/0.1.5/408eb665a92f4399b3e8e8f1aae0fbd19457556f12fde3f740dcb8717139dc6e/node_modules/fengari');
const parser = require('C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/luaparse/0.3.1/82dd6c85b5cba35b7b7d3876f24283120e046525c6dbb6fea0be51ebb1912b54/node_modules/luaparse/luaparse.js');
const root = path.resolve(process.argv[2] || '.');
const test = path.join(root, '.codex-tests/aircraft_init_test.lua');
const component = path.join(root, 'plugins/sasl/data/modules/Custom Module/aircraft_init.lua');
for (const file of [test, component]) parser.parse(fs.readFileSync(file, 'utf8'), {luaVersion: '5.1'});

// Verify host ordering and the exact external startup settings independently of
// the mock fixture. Init creators are synchronous and already publish UNS/WX
// DataRefs used by existing SASL components in the same aircraft load.
const main = fs.readFileSync(path.join(root, 'plugins/sasl/data/modules/main.lua'), 'utf8');
const initIndex = main.search(/\baircraft_init\s*\{/);
assert(initIndex > main.search(/\bdataref_creator_4\s*\{/), 'Aircraft refs must exist before initialization');
for (const system of ['main_panel', 'overhead', 'electric_system', 'engines_system', 'fuel_system', 'start_system']) {
    assert(initIndex < main.search(new RegExp('\\b' + system + '\\s*\\{')), 'Initialize before ' + system);
}
const misc = fs.readFileSync(path.join(root, 'plugins/xtlua/init/scripts/T154.zmisc/T154.zmisc.lua'), 'utf8');
const miscAst = parser.parse(misc, {luaVersion: '5.1'});
const loadHandler = miscAst.body.find(node => node.type === 'FunctionDeclaration' && node.identifier.name === 'aircraft_load');
assert(loadHandler, 'Existing xTlua aircraft_load handler must remain available');
const hotBranch = loadHandler.body.find(node => node.type === 'IfStatement').clauses[0];
const existingHot = new Map();
for (const node of hotBranch.body) {
    if (node.type === 'AssignmentStatement' && node.variables.length === 1 && node.init[0].type === 'NumericLiteral') {
        existingHot.set(node.variables[0].name, node.init[0].value);
    }
}
const xRefs = [
    ['kontur_pow_l', 'tu154/custom/kontur/left_power', 1, 'T154.kontur'],
    ['kontur_pow_r', 'tu154/custom/kontur/right_power', 1, 'T154.kontur'],
    ['ubs_pow_l', 'tu154/custom/ubs/left_power', 1, 'T154.kontur'],
    ['ubs_pow_r', 'tu154/custom/ubs/right_power', 1, 'T154.kontur'],
    ['uns1_on', 'tu154/custom/uns1_on', 1, 'T154.kontur'],
    ['uns2_on', 'tu154/custom/uns2_on', 1, 'T154.kontur'],
    ['weather_sys', 'tu154/custom/kontur/weather_sys', 1, 'T154.kontur'],
    ['weather_mode', 'tu154/custom/kontur/weather_mode', 1, 'T154.kontur'],
    ['tcas2000_mode', 'tu154/custom/tcas2000/mode', 4, 'T154.tcas2000'],
    ['srpbz', 'tu154/custom/kontur/srpbz', 1, 'T154.egpws'],
    ['szt_1', 'tu154/custom/switchers/eng/szt_1', 1, 'T154.zmisc'],
    ['szt_2', 'tu154/custom/switchers/eng/szt_2', 1, 'T154.zmisc'],
    ['szt_3', 'tu154/custom/switchers/eng/szt_3', 1, 'T154.zmisc'],
];
for (const [name, ref, value, owner] of xRefs) {
    assert.strictEqual(existingHot.get(name), value, 'Existing xTlua hot default: ' + name);
    const text = fs.readFileSync(path.join(root, 'plugins/xtlua/init/scripts', owner, owner + '.lua'), 'utf8');
    assert(text.includes('"' + ref + '"'), 'Existing xTlua creator path: ' + ref);
    assert(text.includes('XLuaCreateDataRef'), 'Existing synchronous xTlua constructor: ' + owner);
}
console.log('aircraft_init host ordering and 13 xTlua hot defaults: PASS');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushcfunction(L, state => {
    const file = path.resolve(to_jsstring(lua.lua_tostring(state, 1)));
    const relative = path.relative(root, file);
    assert(relative !== '..' && !relative.startsWith('..' + path.sep) && !path.isAbsolute(relative), 'Test reads stay in the aircraft tree');
    lua.lua_pushstring(state, to_luastring(fs.readFileSync(file, 'utf8')));
    return 1;
});
lua.lua_setglobal(L, to_luastring('readTestFile'));
lua.lua_newtable(L);
lua.lua_pushstring(L, to_luastring(root.replace(/\\/g, '/')));
lua.lua_rawseti(L, -2, 1);
lua.lua_setglobal(L, to_luastring('arg'));
if (lauxlib.luaL_dostring(L, to_luastring(fs.readFileSync(test, 'utf8'))) !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
}
lua.lua_close(L);
console.log('aircraft_init Lua 5.1 syntax: PASS');
