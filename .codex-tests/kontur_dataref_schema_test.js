"use strict";

// Offline structural regression only: this does not load X-Plane or xTlua.
// Usage: node .codex-tests/kontur_dataref_schema_test.js [aircraft-root] [baseline-ref]
// Freeze the pre-migration revision so later commits do not change the reference.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { isDeepStrictEqual, inspect } = require("node:util");
const { execFileSync } = require("node:child_process");
const root = path.resolve(process.argv[2] || path.join(__dirname, ".."));
const baselineRef = process.argv[3] || "a1e028306c09bc01724cade33ca044258265623a";
// Preserve the user's later radar tuning; compare controller logic to the pre-fix revision.
const runtimeBaselineRef = "f0e066d7bfdeccd387e7fd3036f548c295bcd962";
const relativePath = "plugins/xtlua/init/scripts/T154.kontur/T154.kontur.lua";
const cachedParser = "C:/Users/Administrator/AppData/Local/pnpm/store/v11/links/@/luaparse/0.3.1/82dd6c85b5cba35b7b7d3876f24283120e046525c6dbb6fea0be51ebb1912b54/node_modules/luaparse/luaparse.js";
let luaparse;
try {
    luaparse = require("luaparse");
} catch (error) {
    if (error.code !== "MODULE_NOT_FOUND") throw error;
    luaparse = require(process.env.LUAPARSE_PATH || cachedParser);
}

let checks = 0;
function check(condition, description) {
    assert.ok(condition, description);
    checks++;
}
function equal(actual, expected, description) {
    function firstDifference(left, right, at = "value") {
        if (isDeepStrictEqual(left, right)) return null;
        if (left && right && typeof left === "object" && typeof right === "object") {
            for (const key of new Set([...Object.keys(left), ...Object.keys(right)])) {
                const difference = firstDifference(left[key], right[key], at + "." + key);
                if (difference) return difference;
            }
        }
        return at + ": " + inspect(left, { depth: 0, maxArrayLength: 3 }) +
            " != " + inspect(right, { depth: 0, maxArrayLength: 3 });
    }
    assert.ok(isDeepStrictEqual(actual, expected), description + ": " + firstDifference(actual, expected));
    checks++;
}
function parse(source) {
    return luaparse.parse(source, {
        luaVersion: "5.1", comments: false, scope: false,
        locations: false, ranges: false, encodingMode: "pseudo-latin1",
    });
}
function clean(node) {
    if (Array.isArray(node)) return node.map(clean);
    if (!node || typeof node !== "object") return node;
    const result = {};
    for (const [key, value] of Object.entries(node)) {
        if (!["raw", "comments", "loc", "range"].includes(key)) result[key] = clean(value);
    }
    return result;
}
function named(node, name) {
    return node && node.type === "Identifier" && node.name === name;
}
function directBinding(statement) {
    if (statement.type !== "AssignmentStatement" || statement.variables.length !== 1 ||
        statement.variables[0].type !== "Identifier" || statement.init.length !== 1) return null;
    const call = statement.init[0];
    if (call.type !== "CallExpression" || call.base.type !== "Identifier" ||
        !["find_dataref", "deferred_dataref"].includes(call.base.name)) return null;
    return { category: call.base.name, name: statement.variables[0].name, args: call.arguments };
}
function literal(node, description) {
    check(node && node.type === "StringLiteral", description + " is a string literal");
    return node.value;
}
function rowFromBinding(binding) {
    const row = [binding.name, literal(binding.args[0], binding.name + " path")];
    if (binding.category === "find_dataref") {
        equal(binding.args.length, 1, binding.name + " original binding arity");
    } else {
        check(binding.args.length === 2 || binding.args.length === 3, binding.name + " original creation arity");
        row.push(literal(binding.args[1], binding.name + " type"));
        if (binding.args.length === 3) {
            check(binding.args[2].type === "Identifier", binding.name + " notifier remains a named function");
            row.push(binding.args[2].name);
        }
    }
    return row;
}

const original = parse(execFileSync("git", ["show", baselineRef + ":" + relativePath], {
    cwd: root, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
}));
const current = parse(fs.readFileSync(path.join(root, relativePath), "utf8"));
const oldBindings = original.body.map(directBinding).filter(Boolean);
check(oldBindings.length > 0, "reference revision contains individual DataRef bindings");
const removed = new Set();

function tableRows(tableName, category) {
    const declarations = current.body.filter(statement => statement.type === "LocalStatement" &&
        statement.variables.some(variable => named(variable, tableName)));
    equal(declarations.length, 1, tableName + " has exactly one local declaration");
    const declaration = declarations[0];
    equal(declaration.variables.length, 1, tableName + " declaration is independent");
    equal(declaration.init.length, 1, tableName + " has one initializer");
    const table = declaration.init[0];
    equal(table.type, "TableConstructorExpression", tableName + " is declarative");
    removed.add(declaration);
    const rows = table.fields.map((field, index) => {
        equal(field.type, "TableValue", tableName + " uses sequential rows");
        equal(field.value.type, "TableConstructorExpression", tableName + " row is a table");
        const cells = field.value.fields;
        check(category === "find_dataref" ? cells.length === 2 : cells.length === 3 || cells.length === 4,
            tableName + " row " + index + " arity");
        return cells.map((cell, column) => {
            equal(cell.type, "TableValue", tableName + " row uses positional fields");
            if (column === 3) {
                equal(cell.value.type, "Identifier", "notifier uses a named function reference");
                return cell.value.name;
            }
            return literal(cell.value, tableName + " cell");
        });
    });
    const expected = oldBindings.filter(binding => binding.category === category).map(rowFromBinding);
    equal(rows, expected, tableName + " preserves every global name, path, type, notifier and row order");
    equal(new Set(rows.map(row => row[0])).size, rows.length, tableName + " contains no duplicate global names");
    return { declaration, rows };
}

const finds = tableRows("find_datarefs", "find_dataref");
const creates = tableRows("deferred_datarefs", "deferred_dataref");
for (const row of creates.rows.filter(row => row.length === 4)) {
    const handlers = current.body.filter(statement => statement.type === "FunctionDeclaration" && named(statement.identifier, row[3]));
    equal(handlers.length, 1, row[0] + " notifier has one existing definition");
    check(current.body.indexOf(handlers[0]) < current.body.indexOf(creates.declaration), row[0] + " notifier exists before table construction");
}

// Compare helper ASTs rather than text, allowing comments and ordinary formatting.
const helperSource = `
local function bind_datarefs(definitions)
    for _, def in ipairs(definitions) do
        dataref_namespace[def[1]] = find_dataref(def[2])
    end
end
local function create_datarefs(definitions)
    for _, def in ipairs(definitions) do
        if def[4] ~= nil then
            dataref_namespace[def[1]] = deferred_dataref(def[2], def[3], def[4])
        else
            dataref_namespace[def[1]] = deferred_dataref(def[2], def[3])
        end
    end
end
bind_datarefs(find_datarefs)
create_datarefs(deferred_datarefs)
`;
const helperTemplate = parse(helperSource).body;
const calls = [];
for (const expected of helperTemplate) {
    const isFunction = expected.type === "FunctionDeclaration";
    const name = isFunction ? expected.identifier.name : expected.expression.base.name;
    const matches = current.body.filter(statement => isFunction
        ? statement.type === "FunctionDeclaration" && named(statement.identifier, name)
        : statement.type === "CallStatement" && statement.expression.type === "CallExpression" && named(statement.expression.base, name));
    equal(matches.length, 1, name + (isFunction ? " helper exists exactly once" : " is called exactly once"));
    equal(clean(matches[0]), clean(expected), name + " binds through the actual script namespace");
    removed.add(matches[0]);
    if (!isFunction) calls.push(matches[0]);
}
check(current.body.indexOf(calls[0]) < current.body.indexOf(calls[1]), "find bindings precede custom DataRef creation");
check(current.body.indexOf(finds.declaration) < current.body.indexOf(calls[0]), "find table is initialized before its loop");
check(current.body.indexOf(creates.declaration) < current.body.indexOf(calls[1]), "creation table is initialized before its loop");
const namespaceDeclarations = current.body.filter(statement => statement.type === "LocalStatement" &&
    statement.variables.some(variable => named(variable, "dataref_namespace")));
equal(namespaceDeclarations.length, 1, "capture the script environment exactly once");
equal(clean(namespaceDeclarations[0]), clean(parse("local dataref_namespace = getfenv(1)").body[0]),
    "use the Lua 5.1 script environment, not parent _G");
check(current.body.indexOf(namespaceDeclarations[0]) < current.body.indexOf(calls[0]),
    "capture the namespace before binding any properties");
removed.add(namespaceDeclarations[0]);
const remainingBindings = [];
function walk(node) {
    if (!node || typeof node !== "object") return;
    if (directBinding(node)) remainingBindings.push(node);
    for (const value of Object.values(node)) {
        if (Array.isArray(value)) value.forEach(walk);
        else if (value && typeof value === "object") walk(value);
    }
}
walk(current);
equal(remainingBindings.length, 0, "no individual DataRef binding assignments remain anywhere");

// All non-declaration runtime code remains exact, including the global creation helper and handle.
const runtimeOriginal = parse(execFileSync("git", ["show", runtimeBaselineRef + ":" + relativePath], {
    cwd: root, encoding: "utf8", maxBuffer: 8 * 1024 * 1024,
}));
function isBindingSetup(statement) {
    if (statement.type === "LocalStatement") {
        return statement.variables.some(variable => ["find_datarefs", "deferred_datarefs"].includes(variable.name));
    }
    if (statement.type === "FunctionDeclaration") {
        return ["bind_datarefs", "create_datarefs"].some(name => named(statement.identifier, name));
    }
    return statement.type === "CallStatement" && statement.expression.type === "CallExpression" &&
        ["bind_datarefs", "create_datarefs"].some(name => named(statement.expression.base, name));
}
const baselineRuntime = clean(runtimeOriginal.body.filter(statement => !isBindingSetup(statement)));
const baselineDeferred = baselineRuntime.find(statement => statement.type === "FunctionDeclaration" && named(statement.identifier, "deferred_dataref"));
check(Boolean(baselineDeferred), "baseline deferred_dataref helper exists");
const handleStatements = baselineDeferred.body.filter(statement => statement.type === "AssignmentStatement" &&
    statement.variables.length === 1 && named(statement.variables[0], "dref"));
equal(handleStatements.length, 1, "baseline scratch handle has one global assignment");
const currentRuntime = clean(current.body.filter(statement => !removed.has(statement)));
equal(currentRuntime, baselineRuntime, "all remaining runtime AST is identical, including global deferred_dataref and dref");

const initialStateIndex = current.body.findIndex(statement => statement.type === "LocalStatement" &&
    statement.variables.some(variable => named(variable, "radioalt_loc")));
check(initialStateIndex > current.body.indexOf(calls[1]), "all bindings are available before controller state initialization");
console.log(`PASS Kontur DataRef schema: ${finds.rows.length} existing bindings, ${creates.rows.length} created DataRefs; ${checks} structural checks; remaining runtime AST unchanged.`);
