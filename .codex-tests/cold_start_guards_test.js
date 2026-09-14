// Static binding/logic equivalence checks plus execution of the actual startup
// predicates in Lua. This is not an X-Plane runtime test.
const fs = require('fs');
const cp = require('child_process');
const assert = require('assert');
const parser = require('C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/luaparse/0.3.1/82dd6c85b5cba35b7b7d3876f24283120e046525c6dbb6fea0be51ebb1912b54/node_modules/luaparse/luaparse.js');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/fengari/0.1.5/408eb665a92f4399b3e8e8f1aae0fbd19457556f12fde3f740dcb8717139dc6e/node_modules/fengari');
const base = 'plugins/sasl/data/modules/Custom Module/';
// Pin the pre-fix source so this audit stays meaningful after commit/rebase.
const baseline = 'aca27493585630980ba9ed35b21942981809c766';
const names = [
    'fuel_system/fuel_panel.lua', 'electric_system/electric_panel.lua',
    'engines_system/engines_panel.lua', 'controls/controls_panel.lua',
    'fire_system/fire_panel.lua', 'kskv/kskv_panel.lua',
    'lights_system/light_panel.lua', 'antiice/antiice_panel.lua',
    'overhead/overhead.lua', 'main_panel/absu/absu_panel.lua',
    'main_panel/diss/diss_panel.lua', 'main_panel/nvu/nvu_panel.lua',
    'main_panel/tcas/tcas_panel.lua', 'main_panel/radio/ark15.lua',
    'main_panel/tks/bgmk.lua', 'main_panel/tks/gyro.lua',
    'main_panel/water_panel.lua', 'panels_2d/ground_panel.lua',
    'msrp/msrp_panel.lua', 'hydro_system/hydro_logic.lua',
    'main_panel/mgv.lua', 'main_panel/pkp.lua', 'main_panel/agr.lua',
];
let assertions = 0;
function check(test, message) { assert(test, message); assertions++; }
const parse = source => parser.parse(source, {luaVersion: '5.1', ranges: true, encodingMode: 'x-user-defined'});
const callName = node => node && node.type === 'CallExpression' && node.base.type === 'Identifier' ? node.base.name : null;
function bindings(ast) {
    const result = [];
    function add(name, ref, accessor) {
        if (name === 'xp_version') return;
        if (accessor.type === 'LogicalExpression') accessor = accessor.right;
        result.push(JSON.stringify([name, ref, accessor.name]));
    }
    for (const statement of ast.body) {
        const exp = statement.expression;
        if (callName(exp) === 'defineProperty' && /^globalProperty/.test(callName(exp.arguments[1]) || '')) {
            add(exp.arguments[0].value, exp.arguments[1].arguments[0].value, exp.arguments[1].base);
        } else if (callName(exp) === 'defineProps') {
            for (const field of exp.arguments[0].fields) {
                const row = field.value.fields.map(entry => entry.value);
                add(row[0].value, row[1].value, row[2]);
            }
        }
    }
    return [...new Set(result)].sort();
}
function normalize(value) {
    if (Array.isArray(value)) return value.flatMap(item => {
        const norm = normalize(item);
        return norm == null ? [] : Array.isArray(norm) ? norm : [norm];
    });
    if (value == null || typeof value !== 'object') return value;
    if (value.type === 'CallStatement') {
        const name = callName(value.expression);
        if (name === 'defineProps') return null;
        if (name === 'defineProperty' && /^globalProperty/.test(callName(value.expression.arguments[1]) || '')) return null;
    }
    if (value.type === 'FunctionDeclaration' && value.identifier?.name === 'defineProps') return null;
    if (value.type === 'LocalStatement' && value.variables[0]?.name === 'XP11') return null;
    if (value.type === 'IfStatement' && value.clauses[0].condition?.type === 'Identifier' && value.clauses[0].condition.name === 'XP11') {
        return normalize(value.clauses.find(clause => clause.type === 'ElseClause').body);
    }
    if (value.type === 'LogicalExpression' && value.operator === 'and' && callName(value.left) === 'isColdAndDarkStart') return normalize(value.right);
    const out = {};
    for (const [key, entry] of Object.entries(value)) {
        if (['range', 'loc', 'raw', 'comments'].includes(key)) continue;
        out[key] = normalize(entry);
    }
    return out;
}
function runLua(source, label) {
    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    const status = lauxlib.luaL_dostring(L, to_luastring(source));
    const error = status === lua.LUA_OK ? '' : to_jsstring(lua.lua_tostring(L, -1));
    lua.lua_close(L);
    check(status === lua.LUA_OK, label + ': ' + error);
}
for (const name of names) {
    const file = base + name;
    const source = fs.readFileSync(file, 'utf8');
    const ast = parse(source);
    check((source.match(/isColdAndDarkStart\(\)/g) || []).length === 1, name + ': exactly one startup guard');
    check(!/^defineProperty\([^\n]+globalProperty/m.test(source), name + ': no individual DataRef declarations');
    check((source.match(/^defineProps\(\{/gm) || []).length === 1, name + ': one declarative binding block');
    // Existing heater work predates this fix and is not compared to the baseline.
    if (name !== 'antiice/antiice_panel.lua') {
        let original = cp.execFileSync('git', ['show', baseline + ':' + file], {encoding: 'utf8'});
        if (name === 'hydro_system/hydro_logic.lua') {
            original = original.replace('get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng2_N1) < 5', 'get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5');
        }
        const oldAst = parse(original);
        assert.deepStrictEqual(bindings(ast), bindings(oldAst), name + ': DataRef names, paths and XP12 accessors'); assertions++;
        assert.deepStrictEqual(normalize(ast), normalize(oldAst), name + ': unrelated full-file logic unchanged'); assertions++;
    }
    let expression;
    if (name === 'main_panel/water_panel.lua') {
        expression = source.match(/water_level = (isColdAndDarkStart\(\)[^\r\n]*)/)[1];
    } else {
        expression = source.match(/if (isColdAndDarkStart\(\)[\s\S]*?)\s+then/)[1];
    }
    const scenarios = [
        {cold: false, n: [0, 0, 0], expected: false, label: 'hot start before native RPM initialization'},
        {cold: false, n: [35, 35, 35], expected: false, label: 'hot start with engines running'},
        {cold: true, n: [0, 0, 0], expected: true, label: 'cold start with engines stopped'},
        {cold: true, n: [35, 0, 0], expected: false, label: 'cold-selected load with engine 1 running'},
        {cold: true, n: [0, 35, 0], expected: false, label: 'cold-selected load with engine 2 running'},
        {cold: true, n: [0, 0, 35], expected: false, label: 'cold-selected load with engine 3 running'},
    ];
    for (const scenario of scenarios) {
        const water = name === 'main_panel/water_panel.lua';
        const expected = water ? (scenario.expected ? 0.25 : 1) : scenario.expected;
        runLua(`
            local cold = ${scenario.cold}
            local values = {${scenario.n.join(',')}}
            local eng1_N1, eng2_N1, eng3_N1 = 1, 2, 3
            local eng_rpm1, eng_rpm2, eng_rpm3 = 1, 2, 3
            local N1, N2, N3 = 1, 2, 3
            local time_counter, notLoaded = 0.35, true
            local engine_1_n1, engine_2_n1, engine_3_n1 = values[1], values[2], values[3]
            local ENGINE_STOPPED_N1, WATER_MAX = 5, 1
            local function get(property) return values[property] end
            local function isColdAndDarkStart() return cold end
            local function engines_are_stopped() return values[1] < 5 and values[2] < 5 and values[3] < 5 end
            math.random = function() return 0.25 end
            assert((${expression}) == ${expected})
        `, name + ': ' + scenario.label);
    }
}
console.log(`PASS: ${names.length} Lua 5.1 files; ${assertions} checks including ${names.length * 6} executed startup-predicate scenarios.`);
