import 'dart:js_interop';

@JS('Notification')
extension type _Notification._(JSObject _) implements JSObject {
  external factory _Notification(String title, [_Options options]);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

extension type _Options._(JSObject _) implements JSObject {
  external factory _Options({String body});
}

Future<bool> requestWebNotificationPermission() async {
  if (_Notification.permission == 'granted') return true;
  final JSString result = await _Notification.requestPermission().toDart;
  return result.toDart == 'granted';
}

void showWebNotification(String title, String body) {
  if (_Notification.permission != 'granted') return;
  _Notification(title, _Options(body: body));
}
