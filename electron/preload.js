// Only the title bar (app://shell/) gets this bridge; the Flutter iframe
// runs as a plain web page with no access to Electron.
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  window: {
    minimize: () => ipcRenderer.invoke('window:minimize'),
    toggleMaximize: () => ipcRenderer.invoke('window:toggleMaximize'),
    close: () => ipcRenderer.invoke('window:close'),
    onMaximized: (fn) => ipcRenderer.on('window:maximized', (_e, v) => fn(v)),
  },
  version: () => ipcRenderer.invoke('app:version'),
  hasWeb: () => ipcRenderer.invoke('app:hasWeb'),
});
