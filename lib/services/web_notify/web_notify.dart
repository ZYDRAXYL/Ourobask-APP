// Browser Notification API — ใน Electron จะขึ้นเป็นการแจ้งเตือนของ Windows
// (shell อนุญาตสิทธิ์ `notifications` ให้ app://web/ เท่านั้น)
export 'web_notify_stub.dart' if (dart.library.js_interop) 'web_notify_web.dart';
