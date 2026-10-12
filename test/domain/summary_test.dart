import 'package:flexyday/domain/models.dart';
import 'package:flexyday/domain/summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  // October 2026 has 22 weekdays. Wed 10-14 is a test holiday, so 21 count.
  final holidays = {date('2026-10-14')};

  test('counts office, leave, sick and computes the percent', () {
    final logs = [
      DayLog(date: date('2026-10-05'), status: DayStatus.office),
      DayLog(date: date('2026-10-06'), status: DayStatus.office),
      DayLog(date: date('2026-10-07'), status: DayStatus.office),
      DayLog(date: date('2026-10-08'), status: DayStatus.leave),
      DayLog(date: date('2026-10-09'), status: DayStatus.sick),
    ];
    final s = summarizeMonth(date('2026-10-20'), logs, holidays);
    expect(s.office, 3);
    expect(s.leave, 1);
    expect(s.sick, 1);
    expect(s.denominator, 19);
    expect(s.percent, closeTo(3 / 19, 1e-9));
  });

  test('ignores logs on weekends and holidays', () {
    final logs = [
      DayLog(date: date('2026-10-10'), status: DayStatus.office), // Saturday
      DayLog(date: date('2026-10-14'), status: DayStatus.leave), // holiday
    ];
    final s = summarizeMonth(date('2026-10-01'), logs, holidays);
    expect(s.office, 0);
    expect(s.leave, 0);
    expect(s.denominator, 21);
  });

  test('rescheduled and unanswered days stay in the denominator', () {
    final logs = [
      DayLog(
        date: date('2026-10-05'),
        status: DayStatus.rescheduled,
        rescheduledTo: date('2026-10-06'),
      ),
    ];
    final s = summarizeMonth(date('2026-10-01'), logs, holidays);
    expect(s.office, 0);
    expect(s.denominator, 21);
  });

  test('percent is null when the denominator is zero', () {
    const s = MonthSummary(office: 0, leave: 0, sick: 0, denominator: 0);
    expect(s.percent, isNull);
  });
}
