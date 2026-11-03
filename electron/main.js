// Ourobask desktop — Electron main process.
// Same shell shape as DraconDex-EXE: one frameless window with a custom
// title bar (shell.html). The app itself is the Flutter web build, served
// from app://web/ and shown in an <iframe> under the title bar.
//
//   app://shell/…  → electron/shell/   (title bar + frame)
//   app://web/…    → electron/web/     (copied from `flutter build web`)
//
// A real origin (not file://) is required: the Flutter build registers a
// service worker and sqflite_common_ffi_web keeps the SQLite file in
// IndexedDB, and both refuse to run on file://.
const { app, BrowserWindow, ipcMain, protocol, net, shell, session } = require('electron');
const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');
const { resolveInside } = require('./serve');

const APP_NAME = 'Ourobask';
const ROOTS = {
  shell: path.join(__dirname, 'shell'),
  web: path.join(__dirname, 'web'),
};

app.setName(APP_NAME);

protocol.registerSchemesAsPrivileged([{
  scheme: 'app',
  privileges: { standard: true, secure: true, supportFetchAPI: true, allowServiceWorkers: true, corsEnabled: true, stream: true },
}]);

// One running copy only — a second SQLite writer on the same IndexedDB would race.
if (!app.requestSingleInstanceLock()) app.quit();

const boundsFile = () => path.join(app.getPath('userData'), 'window-bounds.json');
function readBounds() {
  try { return JSON.parse(fs.readFileSync(boundsFile(), 'utf8')); } catch (_) { return null; }
}
function saveBounds(win) {
  try { fs.writeFileSync(boundsFile(), JSON.stringify({ ...win.getNormalBounds(), maximized: win.isMaximized() })); } catch (_) {}
}

let mainWindow = null;

function createWindow() {
  const last = readBounds();
  const win = new BrowserWindow({
    width: last?.width || 1280, height: last?.height || 800,
    ...(last?.x != null ? { x: last.x, y: last.y } : {}),
    minWidth: 960, minHeight: 600,
    show: false,
    frame: false,
    autoHideMenuBar: true,
    backgroundColor: '#0f0f13',
    icon: path.join(__dirname, 'shell', 'icon.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });
  win.once('ready-to-show', () => { if (last?.maximized) win.maximize(); win.show(); });
  win.on('close', () => saveBounds(win));
  const sendMax = () => win.webContents.send('window:maximized', win.isMaximized());
  win.on('maximize', sendMax);
  win.on('unmaximize', sendMax);
  win.loadURL('app://shell/index.html');
  mainWindow = win;
}

app.on('second-instance', () => {
  if (!mainWindow) return;
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.focus();
});

app.whenReady().then(() => {
  protocol.handle('app', (req) => {
    const { host, pathname } = new URL(req.url);
    const root = ROOTS[host];
    const file = root && resolveInside(root, pathname);
    if (!file || !fs.existsSync(file)) return new Response('Not found', { status: 404 });
    return net.fetch(pathToFileURL(file).toString());
  });

  // Desktop notifications are the only permission the app needs, and only
  // the Flutter origin gets it.
  session.defaultSession.setPermissionRequestHandler((wc, permission, cb, details) => {
    cb(permission === 'notifications' && (details.requestingUrl || '').startsWith('app://web/'));
  });

  // Links leave the app: http(s) opens in the system browser, nothing else opens.
  app.on('web-contents-created', (_e, wc) => {
    wc.setWindowOpenHandler(({ url }) => {
      if (/^https?:\/\//.test(url)) shell.openExternal(url);
      return { action: 'deny' };
    });
    wc.on('will-navigate', (e, url) => { if (!url.startsWith('app://')) e.preventDefault(); });
  });

  createWindow();
});

app.on('window-all-closed', () => app.quit());

// Window controls for the custom title bar (same channel names as DraconDex).
const focused = (e) => BrowserWindow.fromWebContents(e.sender);
ipcMain.handle('window:minimize', (e) => focused(e)?.minimize());
ipcMain.handle('window:toggleMaximize', (e) => {
  const win = focused(e);
  if (!win) return false;
  win.isMaximized() ? win.unmaximize() : win.maximize();
  return win.isMaximized();
});
ipcMain.handle('window:close', (e) => focused(e)?.close());
ipcMain.handle('app:version', () => app.getVersion());
ipcMain.handle('app:hasWeb', () => fs.existsSync(path.join(ROOTS.web, 'index.html')));
