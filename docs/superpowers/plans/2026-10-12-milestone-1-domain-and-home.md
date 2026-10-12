# Flexy Day Milestone 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Android app with the pure domain logic (unit tested), local database, Home screen, calendar, and amend flow. No notifications and no blocking screen yet.

**Architecture:** Pure Dart `domain/` (models and functions, no Flutter imports) feeds Riverpod providers. `data/` holds the `drift` database and repositories. `ui/` reads one derived context (`Ctx`) and renders it. Notifications arrive in milestone 2, so nothing here depends on them.

**Tech Stack:** Flutter (Android only), Dart, `flutter_riverpod`, `drift` + `drift_flutter` + `drift_dev` + `build_runner`, `shared_preferences`. Versions are resolved by `fvm flutter pub add` in Task 1 and recorded in `docs/superpowers/progress.md`. Do not hand-write version numbers.

**Spec:** `docs/superpowers/specs/2026-10-12-flexy-day-design.md`

## Global Constraints

- Android only, local-only. No backend, no accounts, no sync.
- Two modes: fixed days and quota (`quotaPeriod = week | month`). Quota mode has no reschedule option.
- Answers per date: `office | leave | sick | rescheduled`. "Did not go" is `leave`.
- Percent = office / (weekdays - national holidays - leave - sick). Unanswered days never count as office.
- Quota status: `need = quota - office in period`; `available = remaining weekdays in period - holidays - days already logged`. Green if `available - need > buffer`, yellow if `0 <= available - need <= buffer`, red if `need > available`. Buffer default 2.
- Holidays come from a bundled JSON asset. The asset in this milestone is an empty array. Real data must be built from the official government decree and is not invented here.
- `domain/` has no Flutter imports.
- The Flutter toolchain is managed with FVM. Use `fvm flutter` and `fvm dart`. `flutter` is not on PATH.
- Application id is `com.dienn.flexyday` (confirmed by the user, 2026-10-12). It cannot change after release. The Dart package name is `flexyday`, so imports are `package:flexyday/...`.
- Commits: English, short imperative subject, no AI attribution lines, local git identity of this repo.
- Do not add a dependency for something a few lines can do.

---

## File Structure

```
lib/
  main.dart                        bootstrap: prefs, seed holidays, ProviderScope
  app/app.dart                     MaterialApp
  app/providers.dart               clock, db, repositories, Settings notifier, Ctx
  domain/dates.dart                date-only helpers, week/month bounds
  domain/models.dart               enums, DayLog, Settings
  domain/schedule.dart             isOfficeDay, needsAnswer, canRescheduleTo, unansweredDates
  domain/summary.dart              summarizeMonth
  domain/quota.dart                computeQuotaStatus
  data/database.dart               drift tables and AppDatabase
  data/log_repository.dart
  data/holiday_repository.dart
  data/settings_repository.dart
  ui/format.dart                   Indonesian date and status labels
  ui/quota_badge.dart
  ui/answer_sheet.dart             shared by Home and Calendar (answer and amend)
  ui/home_screen.dart
  ui/calendar_screen.dart
  ui/shell.dart                    bottom navigation
  ui/dev_settings_sheet.dart       temporary, replaced by Settings in milestone 3
assets/holidays/holidays.json      []
test/helpers.dart
test/domain/*.dart
test/data/*.dart
```

---

### Task 1: Scaffold the project and dependencies

**Files:**
- Create: Flutter project in repo root, `.fvmrc`
- Modify: `pubspec.yaml`, `.gitignore`, `README.md` (only if `flutter create` overwrote it)
- Delete: `test/widget_test.dart`

**Interfaces:**
- Produces: a compiling Android project, package name `flexyday`, dependencies installed.

- [x] **Step 1: Application id confirmed**

Application id `com.dienn.flexyday` is confirmed by the user. Do not change it.

- [ ] **Step 2: Pick and pin a Flutter version**

```bash
cd ~/Documents/Projects/flexy-day
git checkout -b milestone-1
fvm list
```

Installed versions seen earlier: `3.24.5` (Dart 3.5.4) and `3.47.0` (listed as "Need setup"). Prefer a current stable. If none is current, run `fvm install stable`. Then:

```bash
fvm use stable --force
fvm flutter --version
```

Expected: prints Flutter and Dart versions. Write both into `docs/superpowers/progress.md` later (Task 13).

- [ ] **Step 3: Create the project in the repo root**

```bash
fvm flutter create --platforms=android --org com.dienn --project-name flexyday .
git status --short
```

If `README.md` shows as modified, restore it: `git checkout README.md`.

- [ ] **Step 4: Add dependencies**

```bash
fvm flutter pub add flutter_riverpod drift drift_flutter shared_preferences
fvm flutter pub add dev:drift_dev dev:build_runner
```

Expected: `pubspec.yaml` lists them. If the resolver fails on SDK constraints, use a newer Flutter via `fvm`, do not hand-pin old versions.

- [ ] **Step 5: Declare the holiday asset and ignore generated files**

In `pubspec.yaml`, under the `flutter:` section, add:

```yaml
  assets:
    - assets/holidays/holidays.json
```

Create `assets/holidays/holidays.json` with exactly:

```json
[]
```

Append to `.gitignore`:

```
*.g.dart
```

- [ ] **Step 6: Remove the default widget test and verify**

```bash
git rm -q test/widget_test.dart
fvm flutter pub get
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Scaffold Flutter project with core dependencies"
```

---

### Task 2: Domain models and date helpers

**Files:**
- Create: `lib/domain/dates.dart`, `lib/domain/models.dart`, `test/helpers.dart`
- Test: `test/domain/dates_test.dart`

**Interfaces:**
- Produces:
  - `DateTime dateOnly(DateTime)`, `bool isWeekday(DateTime)`, `String dateKey(DateTime)`, `DateTime parseDateKey(String)`
  - `Iterable<DateTime> daysInRange(DateTime from, DateTime to)` (inclusive)
  - `DateTime weekStart(DateTime)` (Monday), `weekEnd(DateTime)` (Sunday), `monthStart(DateTime)`, `monthEnd(DateTime)`
  - `enum DayStatus { office, leave, sick, rescheduled }`, `enum WorkMode { fixed, quota }`, `enum QuotaPeriod { week, month }`, `enum QuotaLevel { green, yellow, red }`
  - `class DayLog { date, status, note?, rescheduledTo? }`
  - `class Settings { mode, fixedWeekdays, quota, quotaPeriod, buffer, trackingSince; copyWith(...) }`
  - Test helper `DateTime date(String yyyyMmDd)`

- [ ] **Step 1: Write the failing test**

`test/helpers.dart`:

```dart
import 'package:flexyday/domain/dates.dart';

DateTime date(String key) => parseDateKey(key);
```

`test/domain/dates_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/dates_test.dart`
Expected: FAIL, `lib/domain/dates.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/domain/dates.dart`:

```dart
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isWeekday(DateTime d) => d.weekday <= DateTime.friday;

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

Iterable<DateTime> daysInRange(DateTime from, DateTime to) sync* {
  final end = dateOnly(to);
  for (var d = dateOnly(from); !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
    yield d;
  }
}

DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime weekEnd(DateTime d) => DateTime(d.year, d.month, d.day + (7 - d.weekday));

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);
```

`lib/domain/models.dart`:

```dart
enum DayStatus { office, leave, sick, rescheduled }

enum WorkMode { fixed, quota }

enum QuotaPeriod { week, month }

enum QuotaLevel { green, yellow, red }

class DayLog {
  const DayLog({
    required this.date,
    required this.status,
    this.note,
    this.rescheduledTo,
  });

  final DateTime date;
  final DayStatus status;
  final String? note;
  final DateTime? rescheduledTo;
}

class Settings {
  const Settings({
    required this.trackingSince,
    this.mode = WorkMode.fixed,
    this.fixedWeekdays = const {DateTime.monday, DateTime.wednesday, DateTime.friday},
    this.quota = 3,
    this.quotaPeriod = QuotaPeriod.week,
    this.buffer = 2,
  });

  final WorkMode mode;
  final Set<int> fixedWeekdays;
  final int quota;
  final QuotaPeriod quotaPeriod;
  final int buffer;
  final DateTime trackingSince;

  Settings copyWith({
    WorkMode? mode,
    Set<int>? fixedWeekdays,
    int? quota,
    QuotaPeriod? quotaPeriod,
    int? buffer,
  }) =>
      Settings(
        trackingSince: trackingSince,
        mode: mode ?? this.mode,
        fixedWeekdays: fixedWeekdays ?? this.fixedWeekdays,
        quota: quota ?? this.quota,
        quotaPeriod: quotaPeriod ?? this.quotaPeriod,
        buffer: buffer ?? this.buffer,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/dates_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain test
git commit -m "Add domain models and date helpers"
```

---

### Task 3: Schedule logic (office days, reschedule rules, unanswered)

**Files:**
- Create: `lib/domain/schedule.dart`
- Test: `test/domain/schedule_test.dart`

**Interfaces:**
- Consumes: `DayLog`, `Settings`, `WorkMode`, `DayStatus`, `dateOnly`, `isWeekday`, `daysInRange` from Task 2.
- Produces:
  - `bool isOfficeDay(DateTime date, Settings s, List<DayLog> logs, Set<DateTime> holidays)` (fixed-mode office day, after reschedules)
  - `bool needsAnswer(DateTime date, Settings s, List<DayLog> logs, Set<DateTime> holidays)` (fixed: `isOfficeDay`; quota: non-holiday weekday)
  - `bool canRescheduleTo(DateTime target, DateTime today, Set<DateTime> holidays)`
  - `List<DateTime> unansweredDates({required DateTime today, required Settings settings, required List<DayLog> logs, required Set<DateTime> holidays})` (from `trackingSince` to yesterday, ascending)

- [ ] **Step 1: Write the failing test**

`test/domain/schedule_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/schedule_test.dart`
Expected: FAIL, `schedule.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/domain/schedule.dart`:

```dart
import 'dates.dart';
import 'models.dart';

bool isOfficeDay(DateTime date, Settings s, List<DayLog> logs, Set<DateTime> holidays) {
  final d = dateOnly(date);
  if (holidays.contains(d)) return false;
  final movedIn = logs.any((l) =>
      l.status == DayStatus.rescheduled &&
      l.rescheduledTo != null &&
      dateOnly(l.rescheduledTo!) == d);
  if (movedIn) return true;
  if (!isWeekday(d) || !s.fixedWeekdays.contains(d.weekday)) return false;
  final movedOut =
      logs.any((l) => l.status == DayStatus.rescheduled && dateOnly(l.date) == d);
  return !movedOut;
}

bool needsAnswer(DateTime date, Settings s, List<DayLog> logs, Set<DateTime> holidays) {
  final d = dateOnly(date);
  if (s.mode == WorkMode.fixed) return isOfficeDay(d, s, logs, holidays);
  return isWeekday(d) && !holidays.contains(d);
}

bool canRescheduleTo(DateTime target, DateTime today, Set<DateTime> holidays) {
  final t = dateOnly(target);
  return t.isAfter(dateOnly(today)) && isWeekday(t) && !holidays.contains(t);
}

List<DateTime> unansweredDates({
  required DateTime today,
  required Settings settings,
  required List<DayLog> logs,
  required Set<DateTime> holidays,
}) {
  final answered = {for (final l in logs) dateOnly(l.date)};
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  return [
    for (final d in daysInRange(settings.trackingSince, yesterday))
      if (!answered.contains(d) && needsAnswer(d, settings, logs, holidays)) d,
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/schedule_test.dart`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/schedule.dart test/domain/schedule_test.dart
git commit -m "Add schedule logic for office days, reschedule and unanswered days"
```

---

### Task 4: Monthly summary

**Files:**
- Create: `lib/domain/summary.dart`
- Test: `test/domain/summary_test.dart`

**Interfaces:**
- Consumes: `DayLog`, `DayStatus`, `dateOnly`, `isWeekday`, `daysInRange`, `monthStart`, `monthEnd`.
- Produces: `class MonthSummary { office, leave, sick, denominator; double? percent }` and `MonthSummary summarizeMonth(DateTime month, List<DayLog> logs, Set<DateTime> holidays)`.

Rules: only non-holiday weekdays are counted. Logs on weekends or holidays are ignored. `denominator = weekdays - leave - sick`. `rescheduled` days stay in the denominator and count as neither office, leave nor sick.

- [ ] **Step 1: Write the failing test**

`test/domain/summary_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/summary_test.dart`
Expected: FAIL, `summary.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/domain/summary.dart`:

```dart
import 'dates.dart';
import 'models.dart';

class MonthSummary {
  const MonthSummary({
    required this.office,
    required this.leave,
    required this.sick,
    required this.denominator,
  });

  final int office;
  final int leave;
  final int sick;
  final int denominator;

  double? get percent => denominator == 0 ? null : office / denominator;
}

MonthSummary summarizeMonth(DateTime month, List<DayLog> logs, Set<DateTime> holidays) {
  final byDate = {for (final l in logs) dateOnly(l.date): l};
  var weekdays = 0, office = 0, leave = 0, sick = 0;
  for (final d in daysInRange(monthStart(month), monthEnd(month))) {
    if (!isWeekday(d) || holidays.contains(d)) continue;
    weekdays++;
    switch (byDate[d]?.status) {
      case DayStatus.office:
        office++;
      case DayStatus.leave:
        leave++;
      case DayStatus.sick:
        sick++;
      case DayStatus.rescheduled:
      case null:
        break;
    }
  }
  return MonthSummary(
    office: office,
    leave: leave,
    sick: sick,
    denominator: weekdays - leave - sick,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/summary_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/summary.dart test/domain/summary_test.dart
git commit -m "Add monthly attendance summary"
```

---

### Task 5: Quota status

**Files:**
- Create: `lib/domain/quota.dart`
- Test: `test/domain/quota_test.dart`

**Interfaces:**
- Consumes: `Settings`, `QuotaPeriod`, `QuotaLevel`, `DayLog`, `DayStatus`, date helpers.
- Produces: `class QuotaStatus { done, need, available, level }` and `QuotaStatus computeQuotaStatus({required DateTime today, required Settings settings, required List<DayLog> logs, required Set<DateTime> holidays})`.

Rules: window is the current week (Mon to Sun) or calendar month. `done` counts `office` logs on non-holiday weekdays in the window. `available` counts non-holiday weekdays from `today` to the window end that have no log. `need = max(quota - done, 0)`. `need == 0` is green.

- [ ] **Step 1: Write the failing test**

`test/domain/quota_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/quota_test.dart`
Expected: FAIL, `quota.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/domain/quota.dart`:

```dart
import 'dart:math';

import 'dates.dart';
import 'models.dart';

class QuotaStatus {
  const QuotaStatus({
    required this.done,
    required this.need,
    required this.available,
    required this.level,
  });

  final int done;
  final int need;
  final int available;
  final QuotaLevel level;
}

QuotaStatus computeQuotaStatus({
  required DateTime today,
  required Settings settings,
  required List<DayLog> logs,
  required Set<DateTime> holidays,
}) {
  final t = dateOnly(today);
  final weekly = settings.quotaPeriod == QuotaPeriod.week;
  final start = weekly ? weekStart(t) : monthStart(t);
  final end = weekly ? weekEnd(t) : monthEnd(t);
  final byDate = {for (final l in logs) dateOnly(l.date): l};

  var done = 0, available = 0;
  for (final d in daysInRange(start, end)) {
    if (!isWeekday(d) || holidays.contains(d)) continue;
    final log = byDate[d];
    if (log?.status == DayStatus.office) {
      done++;
    } else if (log == null && !d.isBefore(t)) {
      available++;
    }
  }

  final need = max(settings.quota - done, 0);
  final slack = available - need;
  final level = need == 0
      ? QuotaLevel.green
      : slack < 0
          ? QuotaLevel.red
          : slack <= settings.buffer
              ? QuotaLevel.yellow
              : QuotaLevel.green;
  return QuotaStatus(done: done, need: need, available: available, level: level);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/quota_test.dart`
Expected: PASS (8 tests). If `(r.done, r.need, r.available)` record comparison fails to compile, the Dart SDK is older than 3.0; use a newer Flutter via FVM.

- [ ] **Step 5: Run all domain tests and commit**

```bash
fvm flutter test test/domain
git add lib/domain/quota.dart test/domain/quota_test.dart
git commit -m "Add quota status calculation"
```

Expected: all domain tests pass.

---

### Task 6: Database and log repository

**Files:**
- Create: `lib/data/database.dart`, `lib/data/log_repository.dart`
- Test: `test/data/log_repository_test.dart`

**Interfaces:**
- Consumes: `DayLog`, `DayStatus`, `dateKey`, `parseDateKey`.
- Produces:
  - `class AppDatabase extends _$AppDatabase` with tables `dayLogs` (`DayLogRow`) and `holidays` (`HolidayRow`). Constructor `AppDatabase(QueryExecutor e)`.
  - `class LogRepository(AppDatabase)`: `Stream<List<DayLog>> watchAll()`, `Future<void> upsert(DayLog)`.

Dates are stored as `yyyy-MM-dd` text primary keys.

- [ ] **Step 1: Write the database file**

`lib/data/database.dart`:

```dart
import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('DayLogRow')
class DayLogs extends Table {
  TextColumn get date => text()();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  TextColumn get rescheduledTo => text().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('HolidayRow')
class Holidays extends Table {
  TextColumn get date => text()();
  TextColumn get name => text()();
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(tables: [DayLogs, Holidays])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 2: Generate code**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/data/database.g.dart` created, no errors.

- [ ] **Step 3: Write the failing test**

`test/data/log_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flexyday/data/database.dart';
import 'package:flexyday/data/log_repository.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late LogRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LogRepository(db);
  });
  tearDown(() => db.close());

  test('upsert stores and watchAll returns the log', () async {
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office, note: 'in'));
    final logs = await repo.watchAll().first;
    expect(logs, hasLength(1));
    expect(logs.single.date, date('2026-10-12'));
    expect(logs.single.status, DayStatus.office);
    expect(logs.single.note, 'in');
  });

  test('upsert on the same date amends the answer', () async {
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office));
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.sick, note: 'flu'));
    final logs = await repo.watchAll().first;
    expect(logs, hasLength(1));
    expect(logs.single.status, DayStatus.sick);
    expect(logs.single.note, 'flu');
  });

  test('reschedule target round trips and clears on amend', () async {
    await repo.upsert(DayLog(
      date: date('2026-10-12'),
      status: DayStatus.rescheduled,
      rescheduledTo: date('2026-10-14'),
    ));
    expect((await repo.watchAll().first).single.rescheduledTo, date('2026-10-14'));
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office));
    expect((await repo.watchAll().first).single.rescheduledTo, isNull);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `fvm flutter test test/data/log_repository_test.dart`
Expected: FAIL, `log_repository.dart` not found.

- [ ] **Step 5: Write the repository**

`lib/data/log_repository.dart`:

```dart
import 'package:drift/drift.dart';

import '../domain/dates.dart';
import '../domain/models.dart';
import 'database.dart';

class LogRepository {
  LogRepository(this._db);

  final AppDatabase _db;

  Stream<List<DayLog>> watchAll() =>
      _db.select(_db.dayLogs).watch().map((rows) => rows.map(_toDomain).toList());

  Future<void> upsert(DayLog log) => _db.into(_db.dayLogs).insertOnConflictUpdate(
        DayLogsCompanion.insert(
          date: dateKey(log.date),
          status: log.status.name,
          note: Value(log.note),
          rescheduledTo: Value(log.rescheduledTo == null ? null : dateKey(log.rescheduledTo!)),
        ),
      );

  DayLog _toDomain(DayLogRow r) => DayLog(
        date: parseDateKey(r.date),
        status: DayStatus.values.byName(r.status),
        note: r.note,
        rescheduledTo: r.rescheduledTo == null ? null : parseDateKey(r.rescheduledTo!),
      );
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `fvm flutter test test/data/log_repository_test.dart`
Expected: PASS (3 tests). If it fails to load the sqlite library on macOS, check the `sqlite3` package notes for the resolved version and fix before continuing. Do not skip the test.

- [ ] **Step 7: Commit**

```bash
git add lib/data test/data
git commit -m "Add drift database and day log repository"
```

---

### Task 7: Holiday repository and seed

**Files:**
- Create: `lib/data/holiday_repository.dart`
- Test: `test/data/holiday_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `parseDateKey`.
- Produces: `class HolidayRepository(AppDatabase)`: `Stream<Set<DateTime>> watchDates()`, `Future<void> seedBundled(String json)`. Seed JSON format: `[{"date":"yyyy-MM-dd","name":"..."}]`. Existing rows (including user-added) are never overwritten.

- [ ] **Step 1: Write the failing test**

`test/data/holiday_repository_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flexyday/data/database.dart';
import 'package:flexyday/data/holiday_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late HolidayRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HolidayRepository(db);
  });
  tearDown(() => db.close());

  const seed = '[{"date":"2099-01-01","name":"Test A"},{"date":"2099-01-02","name":"Test B"}]';

  test('seed inserts holidays', () async {
    await repo.seedBundled(seed);
    expect(await repo.watchDates().first, {date('2099-01-01'), date('2099-01-02')});
  });

  test('seeding twice does not duplicate or overwrite user entries', () async {
    await db.into(db.holidays).insert(
          HolidaysCompanion.insert(date: '2099-01-02', name: 'Mine', source: 'user'),
        );
    await repo.seedBundled(seed);
    await repo.seedBundled(seed);
    final rows = await db.select(db.holidays).get();
    expect(rows, hasLength(2));
    expect(rows.firstWhere((r) => r.date == '2099-01-02').name, 'Mine');
  });

  test('an empty seed is fine', () async {
    await repo.seedBundled('[]');
    expect(await repo.watchDates().first, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/data/holiday_repository_test.dart`
Expected: FAIL, `holiday_repository.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/data/holiday_repository.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/dates.dart';
import 'database.dart';

class HolidayRepository {
  HolidayRepository(this._db);

  final AppDatabase _db;

  Stream<Set<DateTime>> watchDates() => _db
      .select(_db.holidays)
      .watch()
      .map((rows) => {for (final r in rows) parseDateKey(r.date)});

  Future<void> seedBundled(String json) async {
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    await _db.batch((b) => b.insertAll(
          _db.holidays,
          [
            for (final h in list)
              HolidaysCompanion.insert(
                date: h['date'] as String,
                name: h['name'] as String,
                source: 'bundled',
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        ));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/data/holiday_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/holiday_repository.dart test/data/holiday_repository_test.dart
git commit -m "Add holiday repository with bundled seed"
```

---

### Task 8: Settings repository

**Files:**
- Create: `lib/data/settings_repository.dart`
- Test: `test/data/settings_repository_test.dart`

**Interfaces:**
- Consumes: `Settings`, `WorkMode`, `QuotaPeriod`, `dateKey`, `parseDateKey`, `dateOnly`.
- Produces: `class SettingsRepository(SharedPreferences)`: `Settings load(DateTime today)`, `Future<void> save(Settings)`. On first `load`, `trackingSince` is set to `today` and kept on later loads.

- [ ] **Step 1: Write the failing test**

`test/data/settings_repository_test.dart`:

```dart
import 'package:flexyday/data/settings_repository.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults on first load, trackingSince is today', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    final s = repo.load(date('2026-10-12'));
    expect(s.mode, WorkMode.fixed);
    expect(s.fixedWeekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});
    expect(s.quota, 3);
    expect(s.quotaPeriod, QuotaPeriod.week);
    expect(s.buffer, 2);
    expect(s.trackingSince, date('2026-10-12'));
  });

  test('trackingSince is kept on later loads', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    repo.load(date('2026-10-12'));
    expect(repo.load(date('2026-11-20')).trackingSince, date('2026-10-12'));
  });

  test('save then load round trips', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    final base = repo.load(date('2026-10-12'));
    await repo.save(base.copyWith(
      mode: WorkMode.quota,
      fixedWeekdays: {DateTime.tuesday},
      quota: 12,
      quotaPeriod: QuotaPeriod.month,
      buffer: 1,
    ));
    final s = repo.load(date('2026-10-13'));
    expect(s.mode, WorkMode.quota);
    expect(s.fixedWeekdays, {DateTime.tuesday});
    expect(s.quota, 12);
    expect(s.quotaPeriod, QuotaPeriod.month);
    expect(s.buffer, 1);
    expect(s.trackingSince, date('2026-10-12'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/data/settings_repository_test.dart`
Expected: FAIL, `settings_repository.dart` not found.

- [ ] **Step 3: Write the implementation**

`lib/data/settings_repository.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/dates.dart';
import '../domain/models.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  Settings load(DateTime today) {
    var since = _prefs.getString('trackingSince');
    if (since == null) {
      since = dateKey(dateOnly(today));
      _prefs.setString('trackingSince', since);
    }
    return Settings(
      trackingSince: parseDateKey(since),
      mode: WorkMode.values.byName(_prefs.getString('mode') ?? 'fixed'),
      fixedWeekdays: (_prefs.getStringList('fixedWeekdays') ?? ['1', '3', '5'])
          .map(int.parse)
          .toSet(),
      quota: _prefs.getInt('quota') ?? 3,
      quotaPeriod: QuotaPeriod.values.byName(_prefs.getString('quotaPeriod') ?? 'week'),
      buffer: _prefs.getInt('buffer') ?? 2,
    );
  }

  Future<void> save(Settings s) async {
    await _prefs.setString('mode', s.mode.name);
    await _prefs.setStringList('fixedWeekdays', [for (final d in s.fixedWeekdays) '$d']);
    await _prefs.setInt('quota', s.quota);
    await _prefs.setString('quotaPeriod', s.quotaPeriod.name);
    await _prefs.setInt('buffer', s.buffer);
  }
}
```

- [ ] **Step 4: Run test to verify it passes, then run everything**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/settings_repository.dart test/data/settings_repository_test.dart
git commit -m "Add settings repository"
```

---

### Task 9: Providers and app bootstrap

**Files:**
- Create: `lib/app/providers.dart`, `lib/app/app.dart`
- Modify: `lib/main.dart` (replace fully)

**Interfaces:**
- Consumes: all repositories and domain types.
- Produces:
  - `clockProvider` (`DateTime Function()`), `sharedPreferencesProvider`, `databaseProvider`
  - `logRepositoryProvider`, `holidayRepositoryProvider`, `settingsRepositoryProvider`
  - `settingsProvider` (`NotifierProvider<SettingsNotifier, Settings>`; `notifier.update(Settings)`)
  - `logsProvider`, `holidaysProvider` (`StreamProvider`)
  - `ctxProvider` (`Provider<Ctx>`) where `Ctx { DateTime today; Settings settings; List<DayLog> logs; Set<DateTime> holidays; DayLog? logFor(DateTime) }`
  - `class FlexyDayApp extends StatelessWidget`

- [ ] **Step 1: Write providers**

`lib/app/providers.dart`:

```dart
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/holiday_repository.dart';
import '../data/log_repository.dart';
import '../data/settings_repository.dart';
import '../domain/dates.dart';
import '../domain/models.dart';

final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('override in main'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'flexy_day'));
  ref.onDispose(db.close);
  return db;
});

final logRepositoryProvider =
    Provider((ref) => LogRepository(ref.watch(databaseProvider)));

final holidayRepositoryProvider =
    Provider((ref) => HolidayRepository(ref.watch(databaseProvider)));

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => ref
      .read(settingsRepositoryProvider)
      .load(dateOnly(ref.read(clockProvider)()));

  Future<void> update(Settings s) async {
    state = s;
    await ref.read(settingsRepositoryProvider).save(s);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

final logsProvider =
    StreamProvider<List<DayLog>>((ref) => ref.watch(logRepositoryProvider).watchAll());

final holidaysProvider = StreamProvider<Set<DateTime>>(
    (ref) => ref.watch(holidayRepositoryProvider).watchDates());

class Ctx {
  const Ctx({
    required this.today,
    required this.settings,
    required this.logs,
    required this.holidays,
  });

  final DateTime today;
  final Settings settings;
  final List<DayLog> logs;
  final Set<DateTime> holidays;

  DayLog? logFor(DateTime d) {
    final k = dateOnly(d);
    for (final l in logs) {
      if (dateOnly(l.date) == k) return l;
    }
    return null;
  }
}

final ctxProvider = Provider<Ctx>((ref) => Ctx(
      today: dateOnly(ref.watch(clockProvider)()),
      settings: ref.watch(settingsProvider),
      logs: ref.watch(logsProvider).value ?? const [],
      holidays: ref.watch(holidaysProvider).value ?? const {},
    ));
```

- [ ] **Step 2: Write the app widget and main**

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import '../ui/shell.dart';

class FlexyDayApp extends StatelessWidget {
  const FlexyDayApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flexy Day',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const Shell(),
      );
}
```

`lib/main.dart` (replace the whole file):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  await container
      .read(holidayRepositoryProvider)
      .seedBundled(await rootBundle.loadString('assets/holidays/holidays.json'));
  runApp(UncontrolledProviderScope(container: container, child: const FlexyDayApp()));
}
```

`lib/ui/shell.dart` does not exist yet, so analysis fails until Task 11. Create a temporary stub now so this task compiles on its own:

`lib/ui/shell.dart`:

```dart
import 'package:flutter/material.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Flexy Day')));
}
```

- [ ] **Step 3: Verify**

```bash
fvm flutter analyze
fvm flutter test
```

Expected: `No issues found!` and all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/app lib/main.dart lib/ui/shell.dart
git commit -m "Add providers and app bootstrap"
```

---

### Task 10: Shared UI pieces (format, quota badge, answer sheet)

**Files:**
- Create: `lib/ui/format.dart`, `lib/ui/quota_badge.dart`, `lib/ui/answer_sheet.dart`

**Interfaces:**
- Consumes: `Ctx`, providers, `LogRepository.upsert`, `isOfficeDay`, `canRescheduleTo`, `daysInRange`.
- Produces:
  - `String formatDate(DateTime)` ("Senin, 12 Oktober 2026"), `String formatMonth(DateTime)`, `const List<String> weekdayShort`, `String statusLabel(DayStatus)`
  - `class QuotaBadge(QuotaStatus)`
  - `Future<void> showAnswerSheet(BuildContext, DateTime date)`: answers or amends a date. Options: office, leave, sick, plus reschedule only in fixed mode on an office day or on a day already rescheduled. Reschedule requires a target date. Save writes one `DayLog`.

- [ ] **Step 1: Write `format.dart`**

`lib/ui/format.dart`:

```dart
import '../domain/models.dart';

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const weekdayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String formatDate(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

String formatMonth(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String statusLabel(DayStatus s) => switch (s) {
      DayStatus.office => 'Ke kantor',
      DayStatus.leave => 'Libur',
      DayStatus.sick => 'Sakit',
      DayStatus.rescheduled => 'Reschedule',
    };
```

- [ ] **Step 2: Write `quota_badge.dart`**

`lib/ui/quota_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/quota.dart';

class QuotaBadge extends StatelessWidget {
  const QuotaBadge(this.status, {super.key});

  final QuotaStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status.level) {
      QuotaLevel.green => (Colors.green, 'Aman'),
      QuotaLevel.yellow => (Colors.amber.shade700, 'Segera penuhi'),
      QuotaLevel.red => (Colors.red, 'Kuota tidak akan terpenuhi'),
    };
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label. Hadir ${status.done}, kurang ${status.need}, hari tersedia ${status.available}.',
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Write `answer_sheet.dart`**

`lib/ui/answer_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import 'format.dart';

Future<void> showAnswerSheet(BuildContext context, DateTime date) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnswerSheet(date: date),
    );

class AnswerSheet extends ConsumerStatefulWidget {
  const AnswerSheet({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<AnswerSheet> {
  DayStatus? _status;
  DateTime? _target;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final log = ref.read(ctxProvider).logFor(widget.date);
    _status = log?.status;
    _target = log?.rescheduledTo;
    _note.text = log?.note ?? '';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTarget(Ctx c) async {
    final tomorrow = DateTime(c.today.year, c.today.month, c.today.day + 1);
    bool ok(DateTime d) => canRescheduleTo(d, c.today, c.holidays);
    final candidates = daysInRange(tomorrow, DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 60));
    final initial = (_target != null && ok(_target!)) ? _target! : candidates.firstWhere(ok);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow,
      lastDate: DateTime(tomorrow.year + 1, tomorrow.month, tomorrow.day),
      selectableDayPredicate: ok,
    );
    if (picked != null) setState(() => _target = dateOnly(picked));
  }

  Future<void> _save() async {
    final note = _note.text.trim();
    await ref.read(logRepositoryProvider).upsert(DayLog(
          date: widget.date,
          status: _status!,
          note: note.isEmpty ? null : note,
          rescheduledTo: _status == DayStatus.rescheduled ? _target : null,
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final alreadyRescheduled = c.logFor(widget.date)?.status == DayStatus.rescheduled;
    final canReschedule = c.settings.mode == WorkMode.fixed &&
        (alreadyRescheduled || isOfficeDay(widget.date, c.settings, c.logs, c.holidays));
    final options = [
      DayStatus.office,
      DayStatus.leave,
      DayStatus.sick,
      if (canReschedule) DayStatus.rescheduled,
    ];
    final canSave = _status != null && (_status != DayStatus.rescheduled || _target != null);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatDate(widget.date), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final s in options)
                  ChoiceChip(
                    label: Text(statusLabel(s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
            if (_status == DayStatus.rescheduled) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _pickTarget(c),
                child: Text(_target == null ? 'Pilih tanggal tujuan' : formatDate(_target!)),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSave ? _save : null,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify**

Run: `fvm flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/ui
git commit -m "Add formatting, quota badge and answer sheet"
```

---

### Task 11: Home screen, shell, temporary settings sheet

**Files:**
- Create: `lib/ui/home_screen.dart`, `lib/ui/dev_settings_sheet.dart`
- Modify: `lib/ui/shell.dart` (replace the stub)

**Interfaces:**
- Consumes: `ctxProvider`, `settingsProvider`, `needsAnswer`, `unansweredDates`, `summarizeMonth`, `computeQuotaStatus`, `isOfficeDay`, `showAnswerSheet`, `QuotaBadge`, format helpers.
- Produces: `Shell` with Home and Calendar tabs (`CalendarScreen` from Task 12), a tune button opening `DevSettingsSheet`. `DevSettingsSheet` is temporary and is replaced by the real Settings screen in milestone 3.

- [ ] **Step 1: Write the Home screen**

`lib/ui/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/quota.dart';
import '../domain/schedule.dart';
import '../domain/summary.dart';
import 'answer_sheet.dart';
import 'format.dart';
import 'quota_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(ctxProvider);
    final todayLog = c.logFor(c.today);
    final needs = needsAnswer(c.today, c.settings, c.logs, c.holidays);
    final missing = unansweredDates(
      today: c.today,
      settings: c.settings,
      logs: c.logs,
      holidays: c.holidays,
    ).length;
    final summary = summarizeMonth(c.today, c.logs, c.holidays);
    final percent = summary.percent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDate(c.today), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (!needs && todayLog == null)
                  const Text('Hari ini bukan jadwal ke kantor.')
                else ...[
                  Text(todayLog == null
                      ? 'Belum dijawab.'
                      : '${statusLabel(todayLog.status)}${todayLog.note == null ? '' : ': ${todayLog.note}'}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => showAnswerSheet(context, c.today),
                    child: Text(todayLog == null ? 'Jawab' : 'Ubah jawaban'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (missing > 0)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$missing hari belum diisi. Buka Kalender untuk mengisinya.'),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: c.settings.mode == WorkMode.quota
                ? QuotaBadge(computeQuotaStatus(
                    today: c.today,
                    settings: c.settings,
                    logs: c.logs,
                    holidays: c.holidays,
                  ))
                : Text(_nextOfficeDay(c)),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatMonth(c.today), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Hadir ${summary.office}, libur ${summary.leave}, sakit ${summary.sick}'),
                Text('Hari kerja dihitung: ${summary.denominator}'),
                Text('Kehadiran: ${percent == null ? '-' : '${(percent * 100).toStringAsFixed(0)}%'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _nextOfficeDay(Ctx c) {
    final end = DateTime(c.today.year, c.today.month, c.today.day + 60);
    for (final d in daysInRange(c.today, end)) {
      if (isOfficeDay(d, c.settings, c.logs, c.holidays)) {
        return 'Jadwal ke kantor berikutnya: ${formatDate(d)}';
      }
    }
    return 'Belum ada jadwal ke kantor dalam 60 hari ke depan.';
  }
}
```

- [ ] **Step 2: Write the temporary settings sheet**

`lib/ui/dev_settings_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import 'format.dart';

// Temporary. Replaced by the Settings screen in milestone 3.
class DevSettingsSheet extends ConsumerWidget {
  const DevSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<WorkMode>(
            segments: const [
              ButtonSegment(value: WorkMode.fixed, label: Text('Hari tetap')),
              ButtonSegment(value: WorkMode.quota, label: Text('Kuota')),
            ],
            selected: {s.mode},
            onSelectionChanged: (v) => notifier.update(s.copyWith(mode: v.first)),
          ),
          const SizedBox(height: 12),
          if (s.mode == WorkMode.fixed)
            Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 5; d++)
                  FilterChip(
                    label: Text(weekdayShort[d - 1]),
                    selected: s.fixedWeekdays.contains(d),
                    onSelected: (on) {
                      final next = {...s.fixedWeekdays};
                      on ? next.add(d) : next.remove(d);
                      notifier.update(s.copyWith(fixedWeekdays: next));
                    },
                  ),
              ],
            )
          else ...[
            SegmentedButton<QuotaPeriod>(
              segments: const [
                ButtonSegment(value: QuotaPeriod.week, label: Text('Per minggu')),
                ButtonSegment(value: QuotaPeriod.month, label: Text('Per bulan')),
              ],
              selected: {s.quotaPeriod},
              onSelectionChanged: (v) => notifier.update(s.copyWith(quotaPeriod: v.first)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: s.quota > 1 ? () => notifier.update(s.copyWith(quota: s.quota - 1)) : null,
                ),
                Text('Kuota: ${s.quota}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => notifier.update(s.copyWith(quota: s.quota + 1)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Replace the shell**

`lib/ui/shell.dart`:

```dart
import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'dev_settings_sheet.dart';
import 'home_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Flexy Day'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const DevSettingsSheet(),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const [HomeScreen(), CalendarScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          ],
        ),
      );
}
```

Analysis fails until Task 12 creates `calendar_screen.dart`. That is expected. Do not commit until Task 12 passes analysis; commit both together in Task 12.

---

### Task 12: Calendar screen with amend

**Files:**
- Create: `lib/ui/calendar_screen.dart`

**Interfaces:**
- Consumes: `ctxProvider`, `showAnswerSheet`, `needsAnswer`, `monthStart`, `monthEnd`, `isWeekday`, format helpers.
- Produces: `class CalendarScreen`: month grid with prev/next, status colors, holidays marked, unanswered past required days outlined. Tapping a non-holiday weekday opens the answer sheet (answer or amend).

- [ ] **Step 1: Write the calendar**

`lib/ui/calendar_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import 'answer_sheet.dart';
import 'format.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime? _month;

  void _shift(int months) {
    final m = _month!;
    setState(() => _month = DateTime(m.year, m.month + months, 1));
  }

  Color? _fill(DayStatus? s) => switch (s) {
        DayStatus.office => Colors.green.shade200,
        DayStatus.leave => Colors.blue.shade200,
        DayStatus.sick => Colors.orange.shade200,
        DayStatus.rescheduled => Colors.purple.shade100,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final month = _month ??= monthStart(c.today);
    final lead = month.weekday - 1;
    final last = monthEnd(month).day;

    Widget cell(int day) {
      final d = DateTime(month.year, month.month, day);
      final log = c.logFor(d);
      final holiday = c.holidays.contains(d);
      final tappable = isWeekday(d) && !holiday;
      final missing = d.isBefore(c.today) &&
          log == null &&
          !d.isBefore(c.settings.trackingSince) &&
          needsAnswer(d, c.settings, c.logs, c.holidays);
      final isToday = d == c.today;
      return InkWell(
        onTap: tappable ? () => showAnswerSheet(context, d) : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _fill(log?.status),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : missing
                      ? Colors.red
                      : Colors.transparent,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              color: holiday ? Colors.red : (isWeekday(d) ? null : Colors.grey),
              fontWeight: holiday ? FontWeight.bold : null,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
              Text(formatMonth(month), style: Theme.of(context).textTheme.titleMedium),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shift(1)),
            ],
          ),
          Row(
            children: [
              for (final w in weekdayShort)
                Expanded(child: Center(child: Text(w, style: Theme.of(context).textTheme.labelSmall))),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox(),
                for (var day = 1; day <= last; day++) cell(day),
              ],
            ),
          ),
          const Wrap(
            spacing: 12,
            children: [
              Text('Hijau: kantor'),
              Text('Biru: libur'),
              Text('Oranye: sakit'),
              Text('Ungu: reschedule'),
              Text('Garis merah: belum diisi'),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
fvm flutter analyze
fvm flutter test
```

Expected: `No issues found!` and all tests pass.

- [ ] **Step 3: Commit Tasks 11 and 12 together**

```bash
git add lib/ui
git commit -m "Add Home, calendar and temporary settings sheet"
```

---

### Task 13: Manual verification on an Android emulator and wrap-up

**Files:**
- Modify: `docs/superpowers/progress.md`, `docs/superpowers/specs/2026-10-12-flexy-day-design.md` (only if behavior differs from the spec)

- [ ] **Step 1: Run on an emulator**

```bash
fvm flutter emulators
fvm flutter emulators --launch <emulator-id>
fvm flutter run
```

If no emulator exists, create one in Android Studio (Device Manager) first. Expected: app launches on the Home tab with no crash.

- [ ] **Step 2: Walk through this checklist**

Mark each result in `progress.md`.

1. Fresh install shows Home, today card, month summary with `Kehadiran: -` when nothing is logged.
2. Fixed mode (default Mon, Wed, Fri): on a Mon/Wed/Fri the today card has "Jawab". On Tue/Thu it says today is not an office day.
3. Answer "Ke kantor" with a note. Card shows the answer. Tap "Ubah jawaban", change to "Sakit", save. Summary updates.
4. Choose "Reschedule". Save is disabled until a target date is picked. Weekends and past dates are not selectable.
5. After a reschedule, Home shows the next office day including the target. Amend the same day back to "Ke kantor": the target stops counting as an office day.
6. Calendar: colors match statuses, today has an outline, tap a past weekday with no answer, fill it. The Home banner count drops.
7. Switch to Kuota in the tune sheet. Reschedule option disappears. The status badge shows green/yellow/red per the Global Constraints. Change the quota number and period and watch the status change.
8. Kill and reopen the app. Answers and settings persist.
9. Percent check: with N office days and known leave/sick, compute by hand `office / (weekdays - holidays - leave - sick)` for the current month and compare with Home.

- [ ] **Step 3: Record results and fix gaps**

Update `docs/superpowers/progress.md`: tick milestone 1 tasks, record the Flutter and package versions actually resolved (`fvm flutter --version`, `pubspec.lock`), and list any failures found. Fix real bugs in new commits. If behavior differs from the spec, edit the spec in the same commit and say why.

- [ ] **Step 4: Commit and push the branch**

```bash
git add -A
git commit -m "Record milestone 1 verification results"
git push -u origin milestone-1
```

Do not open a pull request until the user asks.
