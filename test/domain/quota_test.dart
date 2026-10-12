import 'package:flexyday/domain/models.dart';
import 'package:flexyday/domain/quota.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Settings weekly({int quota = 3, int buffer = 2}) => Settings(
      trackingSince: date('2026-10-01'),
      mode: WorkMode.quota,
      quota: quota,
      buffer: buffer,
    );

void main() {
  // Week of Mon 2026-10-12 to Sun 2026-10-18.
  QuotaStatus at(String today, Settings s,
          {List<DayLog> logs = const [], Set<DateTime> holidays = const {}}) =>
      computeQuotaStatus(
        today: date(today),
        settings: s,
        logs: logs,
        holidays: holidays,
      );

  test('Monday, nothing done: slack 2 with buffer 2 is yellow', () {
    final r = at('2026-10-12', weekly());
    expect((r.done, r.need, r.available), (0, 3, 5));
    expect(r.level, QuotaLevel.yellow);
  });

  test('Monday with buffer 1 is green', () {
    expect(at('2026-10-12', weekly(buffer: 1)).level, QuotaLevel.green);
  });

  test('Wednesday, nothing done: slack 0 is yellow', () {
    final r = at('2026-10-14', weekly());
    expect(r.available, 3);
    expect(r.level, QuotaLevel.yellow);
  });

  test('Thursday, nothing done: cannot be met, red', () {
    final r = at('2026-10-15', weekly());
    expect((r.need, r.available), (3, 2));
    expect(r.level, QuotaLevel.red);
  });

  test('quota met is green even late in the week', () {
    final logs = [
      DayLog(date: date('2026-10-12'), status: DayStatus.office),
      DayLog(date: date('2026-10-13'), status: DayStatus.office),
      DayLog(date: date('2026-10-14'), status: DayStatus.office),
    ];
    final r = at('2026-10-16', weekly(), logs: logs);
    expect((r.done, r.need), (3, 0));
    expect(r.level, QuotaLevel.green);
  });

  test('a logged leave day today is not available', () {
    final logs = [DayLog(date: date('2026-10-15'), status: DayStatus.leave)];
    final r = at('2026-10-15', weekly(), logs: logs);
    expect(r.available, 1); // only Friday
    expect(r.level, QuotaLevel.red);
  });

  test('holidays reduce availability', () {
    final r = at('2026-10-13', weekly(), holidays: {date('2026-10-14')});
    expect(r.available, 3); // Tue, Thu, Fri
    expect(r.level, QuotaLevel.yellow);
  });

  test('monthly period uses the calendar month', () {
    final s = Settings(
      trackingSince: date('2026-10-01'),
      mode: WorkMode.quota,
      quota: 12,
      quotaPeriod: QuotaPeriod.month,
    );
    final logs = [
      for (final d in ['2026-10-05', '2026-10-06', '2026-10-07', '2026-10-08'])
        DayLog(date: date(d), status: DayStatus.office),
    ];
    final r = at('2026-10-26', s, logs: logs);
    expect((r.done, r.need, r.available), (4, 8, 5));
    expect(r.level, QuotaLevel.red);
  });
}
