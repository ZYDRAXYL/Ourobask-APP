/// นอก web ไม่ได้ใช้ — Android/iOS ใช้ flutter_local_notifications
Future<bool> requestWebNotificationPermission() async => false;

void showWebNotification(String title, String body) {}
