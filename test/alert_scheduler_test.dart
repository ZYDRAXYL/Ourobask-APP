import 'package:flutter_test/flutter_test.dart';
import 'package:ourobask/services/alert_scheduler.dart';

void main() {
  final DateTime t0 = DateTime(2026, 11, 3, 9);
  late List<String> fired;
  late AlertScheduler scheduler;

  setUp(() {
    fired = <String>[];
    scheduler = AlertScheduler((String title, String body) => fired.add(title));
  });

  tearDown(() => scheduler.dispose());

  test('fires a one-off alert once, only after its time', () {
    scheduler.add(1, PendingAlert(fireAt: t0, title: 'task', body: ''));
    scheduler.tick(t0.subtract(const Duration(seconds: 1)));
    expect(fired, isEmpty);
    scheduler.tick(t0);
    scheduler.tick(t0.add(const Duration(minutes: 1)));
    expect(fired, <String>['task']);
    expect(scheduler.length, 0);
  });

  test('a repeating alert moves to its next time instead of disappearing', () {
    scheduler.add(
      2,
      PendingAlert(
        fireAt: t0,
        title: 'routine',
        body: '',
        next: () => t0.add(const Duration(days: 7)),
      ),
    );
    scheduler.tick(t0.add(const Duration(hours: 1)));
    scheduler.tick(t0.add(const Duration(days: 1)));
    expect(fired, <String>['routine']);
    expect(scheduler.length, 1);
    scheduler.tick(t0.add(const Duration(days: 7)));
    expect(fired, <String>['routine', 'routine']);
  });

  test('remove and re-add with the same id replaces, never duplicates', () {
    scheduler.add(3, PendingAlert(fireAt: t0, title: 'old', body: ''));
    scheduler.add(3, PendingAlert(fireAt: t0, title: 'new', body: ''));
    scheduler.add(4, PendingAlert(fireAt: t0, title: 'gone', body: ''));
    scheduler.remove(4);
    scheduler.tick(t0);
    expect(fired, <String>['new']);
  });
}
