// Maps an app:// request path to a file inside one root folder.
// Pure (no electron import) so `node --test` can check it without a window.
const path = require('path');

// Returns the absolute file path, or null when the request escapes `root`
// (../ tricks, encoded or not). An empty path or a folder means index.html.
function resolveInside(root, urlPath) {
  let rel;
  try { rel = decodeURIComponent(urlPath || '/'); } catch (_) { return null; }
  if (rel.includes('\0')) return null;
  if (rel.endsWith('/')) rel += 'index.html';
  const abs = path.resolve(root, '.' + path.posix.normalize('/' + rel));
  const base = path.resolve(root);
  return abs === base || abs.startsWith(base + path.sep) ? abs : null;
}

module.exports = { resolveInside };
