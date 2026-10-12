import 'package:flexyday/domain/models.dart';
import 'package:flexyday/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final fixed = Settings(
    trackingSince: date('2026-10-05'),
    fixedWeekdays: {DateTime.monday, DateTime.wednesday},
  );
  final quota = Settings(trackingSince: date('2026-10-05'), mode: WorkMode.quota);

  group('isOfficeDay', () {
    test('pattern weekday is an office day', () {
      expect(isOfficeDay(date('2026-10-12'), fixed, [], {}), isTrue);
    });

    test('non-pattern weekday and weekend are not', () {
      expect(isOfficeDay(date('2026-10-13'), fixed, [], {}), isFalse);
      expect(isOfficeDay(date('2026-10-17'), fixed, [], {}), isFalse);
    });

    test('holiday is not an office day', () {
      expect(isOfficeDay(date('2026-10-12'), fixed, [], {date('2026-10-12')}), isFalse);
    });

    test('rescheduled day moves out and target moves in', () {
      final logs = [
        DayLog(
          date: date('2026-10-12'),
          status: DayStatus.rescheduled,
          rescheduledTo: date('2026-10-13'),
        ),
      ];
      expect(isOfficeDay(date('2026-10-12'), fixed, logs, {}), isFalse);
      expect(isOfficeDay(date('2026-10-13'), fixed, logs, {}), isTrue);
    });

    test('amending a reschedule back to office restores the pattern', () {
      final logs = [DayLog(date: date('2026-10-12'), status: DayStatus.office)];
      expect(isOfficeDay(date('2026-10-12'), fixed, logs, {}), isTrue);
      expect(isOfficeDay(date('2026-10-13'), fixed, logs, {}), isFalse);
    });
  });

  group('needsAnswer', () {
    test('fixed mode follows office days', () {
      expect(needsAnswer(date('2026-10-12'), fixed, [], {}), isTrue);
      expect(needsAnswer(date('2026-10-13'), fixed, [], {}), isFalse);
    });

    test('quota mode needs an answer on every non-holiday weekday', () {
      expect(needsAnswer(date('2026-10-13'), quota, [], {}), isTrue);
      expect(needsAnswer(date('2026-10-17'), quota, [], {}), isFalse);
      expect(needsAnswer(date('2026-10-13'), quota, [], {date('2026-10-13')}), isFalse);
    });
  });

  group('canRescheduleTo', () {
    final holidays = {date('2026-10-14')};
    final today = date('2026-10-12');

    test('accepts a future non-holiday weekday', () {
      expect(canRescheduleTo(date('2026-10-13'), today, holidays), isTrue);
    });

    test('rejects today, past, weekend, holiday', () {
      expect(canRescheduleTo(date('2026-10-12'), today, holidays), isFalse);
      expect(canRescheduleTo(date('2026-10-09'), today, holidays), isFalse);
      expect(canRescheduleTo(date('2026-10-17'), today, holidays), isFalse);
      expect(canRescheduleTo(date('2026-10-14'), today, holidays), isFalse);
    });
  });

  group('unansweredDates', () {
    test('lists past required days without a log, excluding today', () {
      final logs = [DayLog(date: date('2026-10-07'), status: DayStatus.office)];
      final result = unansweredDates(
        today: date('2026-10-14'),
        settings: fixed,
        logs: logs,
        holidays: {},
      );
      // Office days since 10-05: Mon 5, Wed 7, Mon 12. Wed 14 is today.
      expect(result, [date('2026-10-05'), date('2026-10-12')]);
    });

    test('is empty when tracking starts today', () {
      final s = Settings(trackingSince: date('2026-10-14'));
      expect(
        unansweredDates(today: date('2026-10-14'), settings: s, logs: [], holidays: {}),
        isEmpty,
      );
    });
  });
}
