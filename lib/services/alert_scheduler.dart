import 'dart:async';

/// การเตือนหนึ่งรายการที่รอเวลาอยู่ในแอป
class PendingAlert {
  const PendingAlert({
    required this.fireAt,
    required this.title,
    required this.body,
    this.next,
  });

  final DateTime fireAt;
  final String title;
  final String body;

  /// กิจวัตรที่ซ้ำ: คืนเวลาเตือนรอบถัดไป (เรียกหลังเตือนรอบนี้แล้ว) · งานทั่วไปเป็น null
  final DateTime Function()? next;
}

/// ตัวตั้งเวลาการเตือนในแอปเอง — ใช้บน web / Electron ที่ไม่มีตัวตั้งเวลาของระบบ
/// (บน Android/iOS ใช้ `zonedSchedule` ของ flutter_local_notifications เหมือนเดิม)
///
/// ponytail: เช็กทุก 30 วินาที → เตือนช้าได้สูงสุด 30 วินาที และเตือนได้เฉพาะตอนแอปเปิดอยู่
/// (การย่อลงถาดของ Electron จะทำให้แอปเปิดค้างไว้ได้ — ยังไม่ทำ)
class AlertScheduler {
  AlertScheduler(this.onFire);

  final void Function(String title, String body) onFire;
  final Map<int, PendingAlert> _pending = <int, PendingAlert>{};
  Timer? _timer;

  int get length => _pending.length;

  void add(int id, PendingAlert alert) {
    _pending[id] = alert;
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => tick(DateTime.now()));
  }

  void remove(int id) => _pending.remove(id);

  void clear() => _pending.clear();

  /// เตือนทุกรายการที่ถึงเวลาแล้ว (รวมรายการที่เลยเวลาไปตอนเครื่องหลับ)
  void tick(DateTime now) {
    for (final MapEntry<int, PendingAlert> entry in _pending.entries.toList()) {
      final PendingAlert alert = entry.value;
      if (alert.fireAt.isAfter(now)) continue;
      onFire(alert.title, alert.body);
      final DateTime Function()? next = alert.next;
      if (next == null) {
        _pending.remove(entry.key);
      } else {
        _pending[entry.key] = PendingAlert(
          fireAt: next(),
          title: alert.title,
          body: alert.body,
          next: next,
        );
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
