import 'package:flexyday/domain/dates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('dateOnly drops the time', () {
    expect(dateOnly(DateTime(2026, 10, 12, 15, 30)), date('2026-10-12'));
  });

  test('dateKey and parseDateKey round trip', () {
    expect(dateKey(date('2026-01-05')), '2026-01-05');
    expect(parseDateKey('2026-01-05'), DateTime(2026, 1, 5));
  });

  test('isWeekday', () {
    expect(isWeekday(date('2026-10-12')), isTrue); // Monday
    expect(isWeekday(date('2026-10-16')), isTrue); // Friday
    expect(isWeekday(date('2026-10-17')), isFalse); // Saturday
  });

  test('week bounds are Monday to Sunday', () {
    expect(weekStart(date('2026-10-14')), date('2026-10-12'));
    expect(weekEnd(date('2026-10-14')), date('2026-10-18'));
    expect(weekStart(date('2026-10-18')), date('2026-10-12'));
  });

  test('month bounds', () {
    expect(monthStart(date('2026-10-14')), date('2026-10-01'));
    expect(monthEnd(date('2026-10-14')), date('2026-10-31'));
    expect(monthEnd(date('2026-02-03')), date('2026-02-28'));
  });

  test('daysInRange is inclusive', () {
    final days = daysInRange(date('2026-10-30'), date('2026-11-02')).toList();
    expect(days, [
      date('2026-10-30'),
      date('2026-10-31'),
      date('2026-11-01'),
      date('2026-11-02'),
    ]);
  });
}
