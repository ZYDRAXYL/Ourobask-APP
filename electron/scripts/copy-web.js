// Copies a `flutter build web` output folder into electron/web/.
// Usage: npm run web -- ../Ourobask-APP/build/web
const fs = require('fs');
const path = require('path');

const src = process.argv[2];
if (!src || !fs.existsSync(path.join(src, 'index.html'))) {
  console.error('usage: npm run web -- <path to build/web>  (needs index.html inside)');
  process.exit(1);
}
const dest = path.join(__dirname, '..', 'web');
fs.rmSync(dest, { recursive: true, force: true });
fs.cpSync(src, dest, { recursive: true });
console.log(`copied ${path.resolve(src)} -> ${dest}`);
