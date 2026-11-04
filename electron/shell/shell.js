// Title bar wiring + mount the Flutter web build under it.
const $ = (id) => document.getElementById(id);
const w = window.api.window;

$('win-min').onclick = () => w.minimize();
$('win-max').onclick = () => w.toggleMaximize();
$('win-close').onclick = () => w.close();
w.onMaximized((max) => { $('win-max').textContent = max ? '❐' : '▢'; });
window.api.version().then((v) => { $('title-version').textContent = 'v' + v; });

// app://web/ is empty until `npm run web` has copied the Flutter build in.
window.api.hasWeb().then((ok) => {
  if (ok) {
    const f = document.createElement('iframe');
    f.src = 'app://web/index.html';
    f.allow = 'clipboard-read; clipboard-write';
    $('app').appendChild(f);
  } else {
    $('app').innerHTML = '<p id="missing">ยังไม่มี Flutter web build<br>รัน <code>npm run web -- &lt;path&gt;/build/web</code> แล้วเปิดใหม่</p>';
  }
});
