// Mechanical-only schema check for the opened SASL fuel-pump component.
// Compare active bindings and the complete executable body with the git baseline.
const assert = require('assert');
const fs = require('fs');
const cp = require('child_process');
const luaparse = require(process.env.LUAPARSE_PATH ||
    'C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/luaparse/0.3.1/82dd6c85b5cba35b7b7d3876f24283120e046525c6dbb6fea0be51ebb1912b54/node_modules/luaparse/luaparse.js');
const file = 'plugins/sasl/data/modules/Custom Module/fuel_system/fuel_pumps.lua';
// Use the pre-fix baseline even after these changes have been committed.
const before = cp.execFileSync('git', ['show', 'aca27493585630980ba9ed35b21942981809c766:' + file], { encoding: 'utf8' });
const after = fs.readFileSync(file, 'utf8');
const parse = source => luaparse.parse(source, { luaVersion: '5.1', encodingMode: 'x-user-defined' });
const beforeAst = parse(before);
const afterAst = parse(after);

const isCall = (node, name) => node.type === 'CallStatement' &&
    node.expression.type === 'CallExpression' && node.expression.base.name === name;
const oldCalls = beforeAst.body.filter(node => isCall(node, 'defineProperty'));
const oldRows = oldCalls.map(node => {
    const [name, accessor] = node.expression.arguments;
    return [name.value, accessor.arguments[0].value, accessor.base.name];
});
const tableCalls = afterAst.body.filter(node => isCall(node, 'defineProps'));
assert.strictEqual(tableCalls.length, 1, 'Exactly one declarative binding block');
const newRows = tableCalls[0].expression.arguments[0].fields.map(field => {
    const row = field.value.fields.map(item => item.value);
    return [row[0].value, row[1].value, row[2].name];
});
assert.deepStrictEqual(newRows, oldRows, 'Binding names, paths, constructor types and order preserved');
assert.strictEqual(new Set(newRows.map(row => row[0])).size, newRows.length, 'No duplicate bindings');
assert(!afterAst.body.some(node => isCall(node, 'defineProperty')), 'No individual active property declarations');

const beforeBody = beforeAst.body.filter(node => !isCall(node, 'defineProperty'));
const afterBody = afterAst.body.filter(node => !isCall(node, 'defineProps') &&
    !(node.type === 'FunctionDeclaration' && node.isLocal && node.identifier.name === 'defineProps'));
assert.deepStrictEqual(afterBody, beforeBody, 'All executable logic after bindings is identical');
const marker = '-- fuel press after pumps';
assert.strictEqual(after.slice(after.indexOf(marker)).replace(/\r\n/g, '\n'),
    before.slice(before.indexOf(marker)).replace(/\r\n/g, '\n'), 'Logic text and comments preserved');
assert.strictEqual((after.match(/\r\n/g) || []).length,
    (after.match(/\n/g) || []).length, 'Original CRLF style preserved');

for (let index = 0; index < 6; index++) {
    const expected = ['tank1_w', 'tank4_w', 'tank2R_w', 'tank2L_w', 'tank3R_w', 'tank3L_w'][index];
    assert.deepStrictEqual(newRows[index], [expected,
        'sim/flightmodel/weight/m_fuel[' + index + ']', 'globalProperty'], 'Working SASL generic array access unchanged');
}
console.log('PASS fuel-pump schema: ' + oldRows.length + ' identical bindings; Lua 5.1 syntax; complete logic AST/text equivalent; CRLF preserved');
