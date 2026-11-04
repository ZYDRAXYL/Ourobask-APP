const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const { resolveInside } = require('../serve');

const root = path.resolve('/srv/web');

test('serves files inside the root', () => {
  assert.strictEqual(resolveInside(root, '/main.dart.js'), path.join(root, 'main.dart.js'));
  assert.strictEqual(resolveInside(root, '/'), path.join(root, 'index.html'));
  assert.strictEqual(resolveInside(root, '/assets/a%20b.png'), path.join(root, 'assets', 'a b.png'));
});

test('refuses anything that escapes the root', () => {
  // normalize('/../x') clamps to '/x', so plain ../ stays inside — check that it does
  assert.strictEqual(resolveInside(root, '/../../etc/passwd'), path.join(root, 'etc', 'passwd'));
  assert.strictEqual(resolveInside(root, '/%2e%2e/%2e%2e/etc/passwd'), path.join(root, 'etc', 'passwd'));
  assert.strictEqual(resolveInside(root, '/a%00b'), null);
  assert.strictEqual(resolveInside(root, '/%E0%A4%A'), null); // malformed escape
});
