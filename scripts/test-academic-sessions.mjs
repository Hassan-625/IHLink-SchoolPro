import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import ts from 'typescript';
import vm from 'node:vm';

const source = readFileSync('src/lib/academicSessions.ts', 'utf8');
const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText;
const exports = {};
vm.runInNewContext(compiled, { exports });
const sessions = exports.academicSessionOptions(2026);
assert.equal(sessions[0], '2001/2002');
assert.equal(sessions.at(-1), '2026/2027');
assert.equal(sessions.length, 26);
assert.ok(sessions.includes('2025/2026'));
assert.deepEqual(Array.from(new Set(sessions)).length, sessions.length);
assert.deepEqual(exports.academicSessionOptions(2027).slice(-2), ['2026/2027', '2027/2028']);
console.log('PASS: academic sessions cover 2001/2002 through the current academic year plus the next session.');
