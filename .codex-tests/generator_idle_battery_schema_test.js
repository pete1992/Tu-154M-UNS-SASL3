// The battery component change only folds two existing SCP bindings into its table.
const assert = require('assert');
const fs = require('fs');
const cp = require('child_process');
const luaparse = require(process.env.LUAPARSE_PATH ||
    'C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/luaparse/0.3.1/82dd6c85b5cba35b7b7d3876f24283120e046525c6dbb6fea0be51ebb1912b54/node_modules/luaparse/luaparse.js');
const file = 'plugins/sasl/data/modules/Custom Module/electric_system/battery_logic.lua';
// Use the pre-fix baseline even after these changes have been committed.
const before = cp.execFileSync('git', ['show', 'aca27493585630980ba9ed35b21942981809c766:' + file], {encoding: 'utf8'});
const after = fs.readFileSync(file, 'utf8');
const parse = source => luaparse.parse(source, {luaVersion: '5.1', encodingMode: 'x-user-defined'});
const beforeAst = parse(before), afterAst = parse(after);
const isCall = (node, name) => node.type === 'CallStatement' &&
    node.expression.type === 'CallExpression' && node.expression.base.name === name;
const rows = ast => ast.body.flatMap(node => {
    if (isCall(node, 'defineProperty')) {
        const [name, accessor] = node.expression.arguments;
        return [[name.value, accessor.arguments[0].value, accessor.base.name]];
    }
    if (isCall(node, 'defineProps')) {
        return node.expression.arguments[0].fields.map(field => {
            const row = field.value.fields.map(item => item.value);
            return [row[0].value, row[1].value, row[2].name];
        });
    }
    return [];
});
assert.deepStrictEqual(rows(afterAst), rows(beforeAst), 'All bindings remain identical and in original order');
assert.strictEqual(afterAst.body.filter(node => isCall(node, 'defineProps')).length, 1, 'Single binding block');
assert.strictEqual(afterAst.body.filter(node => isCall(node, 'defineProperty')).length, 0, 'No individual SCP bindings');
const withoutBindings = ast => ast.body.filter(node =>
    !isCall(node, 'defineProps') && !isCall(node, 'defineProperty'));
assert.deepStrictEqual(withoutBindings(afterAst), withoutBindings(beforeAst), 'Complete helper and system-logic AST unchanged');
const marker = '-- Battery charge/discharge and temperature logic';
const normalized = text => text.replace(/\r\n/g, '\n');
assert.strictEqual(normalized(after.slice(after.indexOf(marker))), normalized(before.slice(before.indexOf(marker))), 'System body unchanged apart from Git checkout line endings');
assert(!after.includes('\r') || !/(?<!\r)\n|\r(?!\n)/.test(after), 'Uniform LF or CRLF checkout endings');
console.log('PASS battery schema: ' + rows(beforeAst).length + ' identical bindings; complete logic AST/text equivalent; Lua 5.1 syntax; uniform line endings');
