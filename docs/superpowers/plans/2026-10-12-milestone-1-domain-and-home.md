# Flexy Day Milestone 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Android app with the pure domain logic (unit tested), local database, themed Home screen, calendar, amend flow, and English and Indonesian strings. No notifications and no blocking screen yet.

**Architecture:** Pure Dart `domain/` (models and functions, no Flutter imports) feeds Riverpod providers. `data/` holds the `drift` database and repositories. `ui/` reads one derived context (`Ctx`) and renders it with a custom (non-Material-looking) theme and components. All user-visible text comes from ARB files. Notifications arrive in milestone 2, so nothing here depends on them.

**Tech Stack:** Flutter (Android only), Dart, `flutter_riverpod`, `drift` + `drift_flutter` + `drift_dev` + `build_runner`, `shared_preferences`, `intl` + `flutter_localizations` (gen-l10n), `phosphoricons_flutter` (the original `phosphor_flutter` 2.1.0 does not compile on Flutter 3.47.0 because `IconData` is a final class), bundled Plus Jakarta Sans font. Versions are resolved by `fvm flutter pub add` in Task 1 and recorded in `docs/superpowers/progress.md`. Do not hand-write version numbers.

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
- Languages: English and Indonesian, via `flutter_localizations`, `intl`, and ARB files (`lib/l10n/app_en.arb` is the template, `app_id.arb`). No user-visible string is written inside a widget. Language is a setting: `system` (follow device, English if the device language is neither), `id`, or `en`.
- Visual design (agreed with the user from the mockups): primary `#6E56F8` (dark `#9A87FF`), background `#F7F6FB` (dark `#121120`), pastel status fills with darker text, radius 20 to 24 on cards, no AppBar and no Material NavigationBar. Navigation is a floating pill. Home uses a hero card and a bento summary. The calendar uses circles.
- Status colors: office mint, day off sky blue, sick rose, moved sand. Quota levels: green `#1FB57A`, yellow `#F5B301`, red `#F0476A`.
- Font: Plus Jakarta Sans, weights 400, 600, 800, bundled as assets (no runtime download).
- Icons: Phosphor, referenced only through `lib/ui/icons.dart`.
- UI is built from core Flutter widgets. Do not add a UI component package.

---

## File Structure

```
lib/
  main.dart                        bootstrap: prefs, seed holidays, ProviderScope
  app/app.dart                     MaterialApp, locale, themes
  app/providers.dart               clock, db, repositories, Settings notifier, locale, Ctx
  domain/dates.dart                date-only helpers, week/month bounds
  domain/models.dart               enums, DayLog, Settings
  domain/schedule.dart             isOfficeDay, needsAnswer, canRescheduleTo, unansweredDates
  domain/summary.dart              summarizeMonth
  domain/quota.dart                computeQuotaStatus
  data/database.dart               drift tables and AppDatabase
  data/log_repository.dart
  data/holiday_repository.dart
  data/settings_repository.dart
  l10n/app_en.arb, app_id.arb      all user-visible strings
  l10n/l10n.dart                   context.l10n
  ui/theme.dart                    AppColors extension, buildTheme
  ui/icons.dart                    Phosphor icon names in one place
  ui/format.dart                   intl date formatting, status text
  ui/widgets.dart                  FloatingNav, StatTile, QuotaProgress, color helpers
  ui/answer_panel.dart             answer tiles, note, reschedule strip, answer sheet
  ui/home_screen.dart
  ui/calendar_screen.dart
  ui/settings_screen.dart          temporary, replaced in milestone 3
  ui/shell.dart                    stack with floating nav
assets/holidays/holidays.json      []
assets/fonts/                      Plus Jakarta Sans TTFs
test/helpers.dart
test/domain/*.dart
test/data/*.dart
test/l10n/arb_parity_test.dart
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
git branch --show-current   # expected: milestone-1 (already created; create it with git checkout -b milestone-1 if not)
fvm list
```

Installed versions seen earlier: `3.24.5` (Dart 3.5.4) and `3.47.0` (listed as "Need setup"). Prefer a current stable. If none is current, run `fvm install stable`. Then:

```bash
fvm use stable --force
fvm flutter --version
```

Expected: prints Flutter and Dart versions. Write both into `docs/superpowers/progress.md` later (Task 15).

- [ ] **Step 3: Create the project in the repo root**

```bash
fvm flutter create --platforms=android --org com.dienn --project-name flexyday .
git status --short
```

If `README.md` shows as modified, restore it: `git checkout README.md`.

- [ ] **Step 4: Add dependencies**

```bash
fvm flutter pub add flutter_riverpod drift drift_flutter shared_preferences intl phosphoricons_flutter
fvm flutter pub add flutter_localizations --sdk=flutter
fvm flutter pub add dev:drift_dev dev:build_runner
```

Expected: `pubspec.yaml` lists them. If the resolver fails on SDK constraints, use a newer Flutter via `fvm`, do not hand-pin old versions. Record the resolved versions in `progress.md` later.

- [ ] **Step 5: Plus Jakarta Sans font files (needs the user's permission to download)**

Before downloading, tell the user: file names (static TTFs for weights 400, 600, 800, plus the OFL license text), source (the Plus Jakarta Sans page on Google Fonts), and the size. Wait for a yes. Put the files in `assets/fonts/`. Source URL, exact file names, size, and license are unverified until opened. If only a variable font is offered, use it and declare the three weights against it.

- [ ] **Step 6: Declare assets, font, l10n and ignore generated files**

In `pubspec.yaml`, under the `flutter:` section, add (use the real file names from Step 5):

```yaml
  generate: true
  assets:
    - assets/holidays/holidays.json
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```

Create `l10n.yaml` in the repo root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Create stub ARB files so generation works until Task 9 fills them in:

`lib/l10n/app_en.arb`:

```json
{ "@@locale": "en", "appName": "Flexy Day" }
```

`lib/l10n/app_id.arb`:

```json
{ "@@locale": "id", "appName": "Flexy Day" }
```

Create `assets/holidays/holidays.json` with exactly:

```json
[]
```

Append to `.gitignore`:

```
*.g.dart
```

- [ ] **Step 7: Remove the default widget test and verify**

```bash
git rm -q test/widget_test.dart
fvm flutter pub get
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

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
  - `enum DayStatus { office, leave, sick, rescheduled }`, `enum WorkMode { fixed, quota }`, `enum QuotaPeriod { week, month }`, `enum QuotaLevel { green, yellow, red }`, `enum AppLanguage { system, id, en }`
  - `class DayLog { date, status, note?, rescheduledTo? }`
  - `class Settings { mode, fixedWeekdays, quota, quotaPeriod, buffer, trackingSince, language; copyWith(...) }`
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

enum AppLanguage { system, id, en }

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
    this.language = AppLanguage.system,
  });

  final WorkMode mode;
  final Set<int> fixedWeekdays;
  final int quota;
  final QuotaPeriod quotaPeriod;
  final int buffer;
  final DateTime trackingSince;
  final AppLanguage language;

  Settings copyWith({
    WorkMode? mode,
    Set<int>? fixedWeekdays,
    int? quota,
    QuotaPeriod? quotaPeriod,
    int? buffer,
    AppLanguage? language,
  }) =>
      Settings(
        trackingSince: trackingSince,
        mode: mode ?? this.mode,
        fixedWeekdays: fixedWeekdays ?? this.fixedWeekdays,
        quota: quota ?? this.quota,
        quotaPeriod: quotaPeriod ?? this.quotaPeriod,
        buffer: buffer ?? this.buffer,
        language: language ?? this.language,
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
    expect(s.language, AppLanguage.system);
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
      language: AppLanguage.id,
    ));
    final s = repo.load(date('2026-10-13'));
    expect(s.mode, WorkMode.quota);
    expect(s.fixedWeekdays, {DateTime.tuesday});
    expect(s.quota, 12);
    expect(s.quotaPeriod, QuotaPeriod.month);
    expect(s.buffer, 1);
    expect(s.language, AppLanguage.id);
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
      language: AppLanguage.values.byName(_prefs.getString('language') ?? 'system'),
    );
  }

  Future<void> save(Settings s) async {
    await _prefs.setString('mode', s.mode.name);
    await _prefs.setStringList('fixedWeekdays', [for (final d in s.fixedWeekdays) '$d']);
    await _prefs.setInt('quota', s.quota);
    await _prefs.setString('quotaPeriod', s.quotaPeriod.name);
    await _prefs.setInt('buffer', s.buffer);
    await _prefs.setString('language', s.language.name);
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

### Task 9: Strings (en, id) and theme

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb` (replace the Task 1 stubs)
- Create: `lib/l10n/l10n.dart`, `lib/ui/theme.dart`
- Test: `test/l10n/arb_parity_test.dart`

**Interfaces:**
- Produces:
  - Generated `AppLocalizations` with the keys below, and `context.l10n`.
  - `AppColors` theme extension: `bg, card, tint, ink, ink2, office, onOffice, leave, onLeave, sick, onSick, moved, onMoved, qGreen, qYellow, qRed`, read through `context.colors`.
  - `ThemeData buildTheme(Brightness)`.

Rule for every later task: no user-visible string is written inside a widget. Add the key to both ARB files first. ICU messages must not contain an apostrophe (`'` is an escape character), so write "is not", not "isn't".

- [ ] **Step 1: Write the English template**

`lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appName": "Flexy Day",
  "tabHome": "Home",
  "tabCalendar": "Calendar",
  "tabSettings": "Settings",
  "question": "Going to the office today?",
  "answerOffice": "Office",
  "answerMove": "Move day",
  "answerLeave": "Day off",
  "answerSick": "Sick",
  "moveTo": "Move to",
  "noteHint": "Note (optional)",
  "save": "Save",
  "notAnswered": "Not answered yet",
  "changeAnswer": "Change answer",
  "notOfficeDay": "Today is not an office day.",
  "statusOffice": "At the office",
  "statusLeave": "Day off today",
  "statusSick": "Out sick",
  "statusMoved": "Moved to {date}",
  "@statusMoved": { "placeholders": { "date": { "type": "String" } } },
  "unfilledBanner": "{count, plural, =1{1 day not filled in} other{{count} days not filled in}}",
  "@unfilledBanner": { "placeholders": { "count": { "type": "int" } } },
  "nextOffice": "Next office day: {date}",
  "@nextOffice": { "placeholders": { "date": { "type": "String" } } },
  "noUpcoming": "No office days in the next 60 days.",
  "quotaWeek": "Quota this week",
  "quotaMonth": "Quota this month",
  "quotaProgress": "{done} of {total}",
  "@quotaProgress": { "placeholders": { "done": { "type": "int" }, "total": { "type": "int" } } },
  "quotaGreen": "On track",
  "quotaYellow": "Act soon",
  "quotaRed": "Quota cannot be met",
  "quotaStats": "Attended {done}, {need} left, {available} days available",
  "@quotaStats": { "placeholders": { "done": { "type": "int" }, "need": { "type": "int" }, "available": { "type": "int" } } },
  "attendance": "Attendance",
  "statOffice": "Office",
  "statLeave": "Off",
  "statSick": "Sick",
  "legendMissing": "Not filled in",
  "modeFixed": "Fixed days",
  "modeQuota": "Quota",
  "periodWeek": "Per week",
  "periodMonth": "Per month",
  "quotaValue": "Quota: {n}",
  "@quotaValue": { "placeholders": { "n": { "type": "int" } } },
  "language": "Language",
  "langSystem": "System",
  "langId": "Bahasa Indonesia",
  "langEn": "English"
}
```

- [ ] **Step 2: Write the Indonesian file**

`lib/l10n/app_id.arb`:

```json
{
  "@@locale": "id",
  "appName": "Flexy Day",
  "tabHome": "Home",
  "tabCalendar": "Kalender",
  "tabSettings": "Pengaturan",
  "question": "Ngantor hari ini?",
  "answerOffice": "Ngantor",
  "answerMove": "Pindah hari",
  "answerLeave": "Libur",
  "answerSick": "Sakit",
  "moveTo": "Pindah ke tanggal",
  "noteHint": "Catatan (opsional)",
  "save": "Simpan",
  "notAnswered": "Belum dijawab",
  "changeAnswer": "Ubah jawaban",
  "notOfficeDay": "Hari ini bukan jadwal ke kantor.",
  "statusOffice": "Udah ngantor",
  "statusLeave": "Libur hari ini",
  "statusSick": "Lagi sakit",
  "statusMoved": "Dipindah ke {date}",
  "unfilledBanner": "{count, plural, other{{count} hari belum diisi}}",
  "nextOffice": "Jadwal ke kantor berikutnya: {date}",
  "noUpcoming": "Belum ada jadwal ke kantor dalam 60 hari ke depan.",
  "quotaWeek": "Kuota minggu ini",
  "quotaMonth": "Kuota bulan ini",
  "quotaProgress": "{done} dari {total}",
  "quotaGreen": "Aman",
  "quotaYellow": "Segera penuhi",
  "quotaRed": "Kuota tidak akan terpenuhi",
  "quotaStats": "Hadir {done}, kurang {need}, tersedia {available} hari",
  "attendance": "Kehadiran",
  "statOffice": "Hadir",
  "statLeave": "Libur",
  "statSick": "Sakit",
  "legendMissing": "Belum diisi",
  "modeFixed": "Hari tetap",
  "modeQuota": "Kuota",
  "periodWeek": "Per minggu",
  "periodMonth": "Per bulan",
  "quotaValue": "Kuota: {n}",
  "language": "Bahasa",
  "langSystem": "Ikuti sistem",
  "langId": "Bahasa Indonesia",
  "langEn": "English"
}
```

- [ ] **Step 3: Generate and write the barrel**

```bash
fvm flutter gen-l10n
```

Expected: generated `app_localizations.dart` (and `_en`, `_id`). Note where it was written. This plan assumes `lib/l10n/`. If the resolved Flutter writes a synthetic package instead (import `package:flutter_gen/gen_l10n/app_localizations.dart`), change only the import in the barrel below, and record the location in `progress.md`.

`lib/l10n/l10n.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

With Flutter 3.47.0, `AppLocalizations.of` returns a nullable, hence the `!`. Inside an extension on `BuildContext`, pass `this`, not `context`.

- [ ] **Step 4: Write the parity test**

`test/l10n/arb_parity_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> keys(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
    .keys
    .where((k) => !k.startsWith('@'))
    .toSet();

void main() {
  test('en and id have the same message keys', () {
    final en = keys('lib/l10n/app_en.arb');
    final id = keys('lib/l10n/app_id.arb');
    expect(id.difference(en), isEmpty, reason: 'only in id');
    expect(en.difference(id), isEmpty, reason: 'only in en');
  });
}
```

Run: `fvm flutter test test/l10n/arb_parity_test.dart`
Expected: PASS. To see it work, temporarily delete one key from `app_id.arb`: the test must FAIL naming that key. Restore it.

- [ ] **Step 5: Write the theme**

`lib/ui/theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.tint,
    required this.ink,
    required this.ink2,
    required this.office,
    required this.onOffice,
    required this.leave,
    required this.onLeave,
    required this.sick,
    required this.onSick,
    required this.moved,
    required this.onMoved,
    required this.qGreen,
    required this.qYellow,
    required this.qRed,
  });

  final Color bg, card, tint, ink, ink2;
  final Color office, onOffice, leave, onLeave, sick, onSick, moved, onMoved;
  final Color qGreen, qYellow, qRed;

  static const light = AppColors(
    bg: Color(0xFFF7F6FB),
    card: Color(0xFFFFFFFF),
    tint: Color(0xFFEFEDFA),
    ink: Color(0xFF1B1A2E),
    ink2: Color(0xFF6B6A80),
    office: Color(0xFFCFF5E7),
    onOffice: Color(0xFF0B8F6A),
    leave: Color(0xFFD6EAFF),
    onLeave: Color(0xFF2F7DE1),
    sick: Color(0xFFFFD9E0),
    onSick: Color(0xFFD6336C),
    moved: Color(0xFFFFF0C2),
    onMoved: Color(0xFFA8710F),
    qGreen: Color(0xFF1FB57A),
    qYellow: Color(0xFFF5B301),
    qRed: Color(0xFFF0476A),
  );

  static const dark = AppColors(
    bg: Color(0xFF121120),
    card: Color(0xFF1C1B2E),
    tint: Color(0xFF25233B),
    ink: Color(0xFFF2F1FA),
    ink2: Color(0xFFA09FB8),
    office: Color(0xFF1D4D3F),
    onOffice: Color(0xFF6FE3B6),
    leave: Color(0xFF1B3A66),
    onLeave: Color(0xFF8DBBFF),
    sick: Color(0xFF4A1F2E),
    onSick: Color(0xFFFF8FB0),
    moved: Color(0xFF4A3A12),
    onMoved: Color(0xFFFFD36B),
    qGreen: Color(0xFF1FB57A),
    qYellow: Color(0xFFF5B301),
    qRed: Color(0xFFF0476A),
  );

  @override
  AppColors copyWith() => this;

  // ponytail: no animated theme switch, so lerp just snaps to the target.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => other is AppColors ? (t < 0.5 ? this : other) : this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const _primaryLight = Color(0xFF6E56F8);
const _primaryDark = Color(0xFF9A87FF);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: _primaryLight,
    brightness: brightness,
  ).copyWith(
    primary: dark ? _primaryDark : _primaryLight,
    onPrimary: dark ? const Color(0xFF1B1A2E) : Colors.white,
    primaryContainer: dark ? const Color(0xFF3A3170) : const Color(0xFFE4DFFF),
    onSurface: c.ink,
    surface: c.card,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    extensions: [c],
  );
}
```

- [ ] **Step 6: Verify and commit**

```bash
fvm flutter analyze
fvm flutter test
git add lib/l10n lib/ui/theme.dart test/l10n
git commit -m "Add en and id strings and app theme"
```

Expected: `No issues found!` and all tests pass. Commit generated l10n files if they were written under `lib/l10n/`.

---

### Task 10: Providers and app bootstrap

**Files:**
- Create: `lib/app/providers.dart`, `lib/app/app.dart`, `lib/ui/shell.dart` (stub, replaced in Task 14)
- Modify: `lib/main.dart` (replace fully)

**Interfaces:**
- Consumes: repositories, `Settings`, `AppLanguage`, `buildTheme`, `AppLocalizations`.
- Produces:
  - `clockProvider` (`DateTime Function()`), `sharedPreferencesProvider`, `databaseProvider`
  - `logRepositoryProvider`, `holidayRepositoryProvider`, `settingsRepositoryProvider`
  - `settingsProvider` (`NotifierProvider<SettingsNotifier, Settings>`; `notifier.update(Settings)`)
  - `localeProvider` (`Provider<Locale?>`; `null` follows the device)
  - `logsProvider`, `holidaysProvider` (`StreamProvider`)
  - `ctxProvider` (`Provider<Ctx>`) with `Ctx { DateTime today; Settings settings; List<DayLog> logs; Set<DateTime> holidays; DayLog? logFor(DateTime) }`
  - `FlexyDayApp`

- [ ] **Step 1: Write providers**

`lib/app/providers.dart`:

```dart
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
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

final localeProvider = Provider<Locale?>((ref) => switch (ref.watch(settingsProvider).language) {
      AppLanguage.system => null,
      AppLanguage.id => const Locale('id'),
      AppLanguage.en => const Locale('en'),
    });

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

- [ ] **Step 2: Write the app widget, stub shell and main**

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../ui/shell.dart';
import '../ui/theme.dart';
import 'providers.dart';

class FlexyDayApp extends ConsumerWidget {
  const FlexyDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        onGenerateTitle: (c) => c.l10n.appName,
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Shell(),
      );
}
```

`lib/ui/shell.dart` (stub):

```dart
import 'package:flutter/material.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Flexy Day')));
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

`supportedLocales` lists `en` before `id` (alphabetical), so a device in any other language falls back to English. Verify this in Task 15.

- [ ] **Step 3: Verify and commit**

```bash
fvm flutter analyze
fvm flutter test
git add lib/app lib/main.dart lib/ui/shell.dart
git commit -m "Add providers, locale selection and app bootstrap"
```

Expected: `No issues found!` and all tests pass.

---

### Task 11: Shared UI pieces (icons, formatting, widgets)

**Files:**
- Create: `lib/ui/icons.dart`, `lib/ui/format.dart`, `lib/ui/widgets.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppLocalizations`, `QuotaStatus`, `QuotaLevel`, `DayStatus`.
- Produces:
  - `AppIcons.*` (one place to adjust Phosphor names)
  - `fmtWeekday(ctx, d)`, `fmtDate(ctx, d)`, `fmtDateLong(ctx, d)`, `fmtMonth(ctx, d)`, `List<String> shortWeekdays(ctx)` (Monday first), `String statusText(ctx, DayLog)`
  - `(Color bg, Color fg) statusColors(AppColors, DayStatus)`, `(Color bg, Color fg) levelColors(AppColors, QuotaLevel)`
  - `FloatingNav`, `NavEntry`, `StatTile`, `QuotaProgress`

- [ ] **Step 1: Icons in one place**

`lib/ui/icons.dart`:

```dart
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

abstract final class AppIcons {
  static const home = PhosphorIconsRegular.house;
  static const homeActive = PhosphorIconsFill.house;
  static const calendar = PhosphorIconsRegular.calendarBlank;
  static const calendarActive = PhosphorIconsFill.calendarBlank;
  static const settings = PhosphorIconsRegular.sliders;
  static const settingsActive = PhosphorIconsFill.sliders;
  static const office = PhosphorIconsRegular.buildings;
  static const move = PhosphorIconsRegular.calendarPlus;
  static const leave = PhosphorIconsRegular.umbrellaSimple;
  static const sick = PhosphorIconsRegular.thermometer;
  static const check = PhosphorIconsBold.check;
  static const prev = PhosphorIconsRegular.caretLeft;
  static const next = PhosphorIconsRegular.caretRight;
  static const arrow = PhosphorIconsRegular.arrowRight;
}
```

Run `fvm flutter analyze`. Names were checked against `phosphoricons_flutter` 1.1.1 by compiling. If one ever disappears, fix it here only. Do not change call sites.

- [ ] **Step 2: Formatting with intl**

`lib/ui/format.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../l10n/l10n.dart';

String _loc(BuildContext c) => Localizations.localeOf(c).languageCode;

String fmtWeekday(BuildContext c, DateTime d) => DateFormat.EEEE(_loc(c)).format(d);

String fmtDate(BuildContext c, DateTime d) => DateFormat.yMMMMd(_loc(c)).format(d);

String fmtDateLong(BuildContext c, DateTime d) => DateFormat.yMMMMEEEEd(_loc(c)).format(d);

String fmtMonth(BuildContext c, DateTime d) => DateFormat.yMMMM(_loc(c)).format(d);

// 2024-01-01 is a Monday.
List<String> shortWeekdays(BuildContext c) =>
    [for (var i = 0; i < 7; i++) DateFormat.E(_loc(c)).format(DateTime(2024, 1, 1 + i))];

String statusText(BuildContext c, DayLog log) {
  final l = c.l10n;
  return switch (log.status) {
    DayStatus.office => l.statusOffice,
    DayStatus.leave => l.statusLeave,
    DayStatus.sick => l.statusSick,
    DayStatus.rescheduled =>
      l.statusMoved(log.rescheduledTo == null ? '' : fmtDate(c, log.rescheduledTo!)),
  };
}
```

If a locale throws a "locale data not initialized" error at runtime, call `initializeDateFormatting()` from `package:intl/date_symbol_data_local.dart` in `main()` before `runApp`. Check this in Task 15.

- [ ] **Step 3: Shared widgets**

`lib/ui/widgets.dart`:

```dart
import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'theme.dart';

(Color, Color) statusColors(AppColors c, DayStatus s) => switch (s) {
      DayStatus.office => (c.office, c.onOffice),
      DayStatus.leave => (c.leave, c.onLeave),
      DayStatus.sick => (c.sick, c.onSick),
      DayStatus.rescheduled => (c.moved, c.onMoved),
    };

(Color, Color) levelColors(AppColors c, QuotaLevel l) => switch (l) {
      QuotaLevel.green => (c.qGreen, Colors.white),
      QuotaLevel.yellow => (c.qYellow, const Color(0xFF1B1A2E)),
      QuotaLevel.red => (c.qRed, Colors.white),
    };

class NavEntry {
  const NavEntry(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.entries,
    required this.index,
    required this.onChanged,
  });

  final List<NavEntry> entries;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < entries.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: i == index ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      i == index ? entries[i].activeIcon : entries[i].icon,
                      size: 22,
                      color: i == index ? cs.primary : context.colors.ink2,
                    ),
                    if (i == index) ...[
                      const SizedBox(width: 6),
                      Text(
                        entries[i].label,
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.colors});

  final String label;
  final int value;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: colors.$2, fontWeight: FontWeight.w600, fontSize: 12)),
            const Spacer(),
            Text('$value', style: TextStyle(color: colors.$2, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      );
}

// Dots for small quotas, a bar for large ones (12 dots would not fit).
class QuotaProgress extends StatelessWidget {
  const QuotaProgress({super.key, required this.total, required this.done, required this.color});

  final int total;
  final int done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final empty = context.colors.tint;
    if (total > 7) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : (done / total).clamp(0, 1).toDouble(),
          minHeight: 8,
          color: color,
          backgroundColor: empty,
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: i < done ? color : empty),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Verify and commit**

```bash
fvm flutter analyze
git add lib/ui/icons.dart lib/ui/format.dart lib/ui/widgets.dart
git commit -m "Add icons, intl formatting and shared widgets"
```

Expected: `No issues found!`

---

### Task 12: Answer panel and sheet

**Files:**
- Create: `lib/ui/answer_panel.dart`

**Interfaces:**
- Consumes: `ctxProvider`, `logRepositoryProvider`, `isOfficeDay`, `canRescheduleTo`, `daysInRange`, `AppIcons`, `fmtDateLong`, `shortWeekdays`.
- Produces:
  - `AnswerPanel({required DateTime date, bool onHero = false, VoidCallback? onSaved})`: tiles (office, move if allowed, leave, sick). After a tile is chosen, a note field and Save appear. "Move day" adds a strip of selectable target dates (future non-holiday weekdays); Save stays inactive until one is picked.
  - `Future<void> showAnswerSheet(BuildContext, DateTime date)`: the panel inside a bottom sheet, used for amend and for filling past days.
  - Reused by the blocking screen in milestone 2.

- [ ] **Step 1: Write the panel**

`lib/ui/answer_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';

Future<void> showAnswerSheet(BuildContext context, DateTime date) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fmtDateLong(ctx, date),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AnswerPanel(date: date, onSaved: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );

class AnswerPanel extends ConsumerStatefulWidget {
  const AnswerPanel({super.key, required this.date, this.onHero = false, this.onSaved});

  final DateTime date;
  final bool onHero;
  final VoidCallback? onSaved;

  @override
  ConsumerState<AnswerPanel> createState() => _AnswerPanelState();
}

class _AnswerPanelState extends ConsumerState<AnswerPanel> {
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

  List<DateTime> _candidates(Ctx c) {
    final tomorrow = DateTime(c.today.year, c.today.month, c.today.day + 1);
    final list = daysInRange(
      tomorrow,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 45),
    ).where((d) => canRescheduleTo(d, c.today, c.holidays)).take(10).toList();
    if (_target != null && !list.contains(_target) && canRescheduleTo(_target!, c.today, c.holidays)) {
      list.insert(0, _target!);
    }
    return list;
  }

  Future<void> _save() async {
    final note = _note.text.trim();
    await ref.read(logRepositoryProvider).upsert(DayLog(
          date: widget.date,
          status: _status!,
          note: note.isEmpty ? null : note,
          rescheduledTo: _status == DayStatus.rescheduled ? _target : null,
        ));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final colors = context.colors;
    final hero = widget.onHero;
    final tileBg = hero ? const Color(0x33FFFFFF) : colors.tint;
    final tileFg = hero ? Colors.white : colors.ink;
    final selBg = hero ? Colors.white : cs.primary;
    final selFg = hero ? cs.primary : cs.onPrimary;

    final canMove = c.settings.mode == WorkMode.fixed &&
        (c.logFor(widget.date)?.status == DayStatus.rescheduled ||
            isOfficeDay(widget.date, c.settings, c.logs, c.holidays));
    final entries = [
      (DayStatus.office, AppIcons.office, l.answerOffice),
      if (canMove) (DayStatus.rescheduled, AppIcons.move, l.answerMove),
      (DayStatus.leave, AppIcons.leave, l.answerLeave),
      (DayStatus.sick, AppIcons.sick, l.answerSick),
    ];
    final canSave = _status != null && (_status != DayStatus.rescheduled || _target != null);
    final weekdays = shortWeekdays(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: entries.length == 4 ? 2 : 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: entries.length == 4 ? 1.9 : 1.15,
          children: [
            for (final e in entries)
              GestureDetector(
                onTap: () => setState(() => _status = e.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _status == e.$1 ? selBg : tileBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(e.$2, size: 24, color: _status == e.$1 ? selFg : tileFg),
                      const SizedBox(height: 4),
                      Text(
                        e.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _status == e.$1 ? selFg : tileFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _status == null
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_status == DayStatus.rescheduled) ...[
                      const SizedBox(height: 14),
                      Text(
                        l.moveTo,
                        style: TextStyle(color: tileFg, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final d in _candidates(c))
                              GestureDetector(
                                onTap: () => setState(() => _target = d),
                                child: Container(
                                  width: 52,
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _target == d ? selBg : tileBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        weekdays[d.weekday - 1],
                                        style: TextStyle(fontSize: 11, color: _target == d ? selFg : tileFg),
                                      ),
                                      Text(
                                        '${d.day}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _target == d ? selFg : tileFg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      style: TextStyle(color: tileFg),
                      decoration: InputDecoration(
                        hintText: l.noteHint,
                        hintStyle: TextStyle(color: hero ? const Color(0xB3FFFFFF) : colors.ink2),
                        filled: true,
                        fillColor: tileBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: canSave ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: hero ? Colors.white : cs.primary,
                        foregroundColor: hero ? cs.primary : cs.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l.save, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify and commit**

```bash
fvm flutter analyze
git add lib/ui/answer_panel.dart
git commit -m "Add answer panel and answer sheet"
```

Expected: `No issues found!`

---

### Task 13: Home screen

**Files:**
- Create: `lib/ui/home_screen.dart`

**Interfaces:**
- Consumes: `ctxProvider`, `needsAnswer`, `unansweredDates`, `summarizeMonth`, `computeQuotaStatus`, `isOfficeDay`, `AnswerPanel`, `showAnswerSheet`, format helpers, `StatTile`, `QuotaProgress`, `statusColors`, `levelColors`.
- Produces: `HomeScreen`: large weekday header, a hero card (primary with inline `AnswerPanel` when unanswered; status-colored summary with "Change answer" when answered; a quiet card when today needs no answer), the unfilled-days banner, a quota card (quota mode) or next office day (fixed mode), and the bento summary.

- [ ] **Step 1: Write the screen**

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
import '../l10n/l10n.dart';
import 'answer_panel.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final colors = context.colors;
    final theme = Theme.of(context);
    final log = c.logFor(c.today);
    final needs = needsAnswer(c.today, c.settings, c.logs, c.holidays);
    final missing = unansweredDates(
      today: c.today,
      settings: c.settings,
      logs: c.logs,
      holidays: c.holidays,
    ).length;
    final summary = summarizeMonth(c.today, c.logs, c.holidays);
    final percent = summary.percent;
    final quota = c.settings.mode == WorkMode.quota
        ? computeQuotaStatus(
            today: c.today,
            settings: c.settings,
            logs: c.logs,
            holidays: c.holidays,
          )
        : null;

    Widget card({required Widget child, Color? color}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color ?? colors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        );

    Widget hero() {
      if (log == null && !needs) {
        return card(child: Text(l.notOfficeDay, style: TextStyle(color: colors.ink2)));
      }
      if (log == null) {
        return card(
          color: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.question,
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              AnswerPanel(date: c.today, onHero: true),
            ],
          ),
        );
      }
      final (bg, fg) = statusColors(colors, log.status);
      return card(
        color: bg,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: Icon(AppIcons.check, size: 20, color: bg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText(context, log),
                    style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (log.note != null) Text(log.note!, style: TextStyle(color: fg, fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => showAnswerSheet(context, c.today),
              child: Text(l.changeAnswer, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    Widget middle() {
      if (quota != null) {
        final (bg, fg) = levelColors(colors, quota.level);
        final label = switch (quota.level) {
          QuotaLevel.green => l.quotaGreen,
          QuotaLevel.yellow => l.quotaYellow,
          QuotaLevel.red => l.quotaRed,
        };
        final total = c.settings.quota;
        return card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.settings.quotaPeriod == QuotaPeriod.week ? l.quotaWeek : l.quotaMonth,
                style: TextStyle(color: colors.ink2, fontSize: 12),
              ),
              const SizedBox(height: 10),
              QuotaProgress(total: total, done: quota.done, color: bg),
              const SizedBox(height: 10),
              Text(
                l.quotaProgress(quota.done, total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Text(
                l.quotaStats(quota.done, quota.need, quota.available),
                style: TextStyle(color: colors.ink2, fontSize: 11),
              ),
            ],
          ),
        );
      }
      final end = DateTime(c.today.year, c.today.month, c.today.day + 60);
      DateTime? next;
      for (final d in daysInRange(c.today, end)) {
        if (isOfficeDay(d, c.settings, c.logs, c.holidays)) {
          next = d;
          break;
        }
      }
      return card(
        child: Text(next == null ? l.noUpcoming : l.nextOffice(fmtDate(context, next))),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text(
          fmtWeekday(context, c.today),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
        ),
        Text(fmtDate(context, c.today), style: TextStyle(color: colors.ink2)),
        const SizedBox(height: 16),
        hero(),
        if (missing > 0) ...[
          const SizedBox(height: 12),
          card(
            color: colors.sick,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.unfilledBanner(missing),
                    style: TextStyle(color: colors.onSick, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(AppIcons.arrow, color: colors.onSick, size: 18),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        middle(),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: Row(
            children: [
              Expanded(
                flex: 12,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l.attendance}, ${fmtMonth(context, c.today)}',
                        style: TextStyle(color: colors.ink2, fontSize: 11),
                      ),
                      Text(
                        percent == null ? '-' : '${(percent * 100).round()}%',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent ?? 0,
                          minHeight: 6,
                          color: theme.colorScheme.primary,
                          backgroundColor: colors.tint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: Column(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l.statOffice,
                        value: summary.office,
                        colors: statusColors(colors, DayStatus.office),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StatTile(
                        label: l.statLeave,
                        value: summary.leave,
                        colors: statusColors(colors, DayStatus.leave),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StatTile(
                        label: l.statSick,
                        value: summary.sick,
                        colors: statusColors(colors, DayStatus.sick),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

The banner does not navigate in this milestone. It is a hint; the calendar shows the missing days.

- [ ] **Step 2: Verify**

Run: `fvm flutter analyze`
Expected: `No issues found!` Commit together with Task 14 (the shell is still a stub, but the screen compiles).

```bash
git add lib/ui/home_screen.dart
git commit -m "Add Home screen"
```

---

### Task 14: Calendar, settings screen, shell

**Files:**
- Create: `lib/ui/calendar_screen.dart`, `lib/ui/settings_screen.dart`
- Modify: `lib/ui/shell.dart` (replace the stub)

**Interfaces:**
- Consumes: `ctxProvider`, `settingsProvider`, `showAnswerSheet`, `needsAnswer`, `isWeekday`, `monthStart`, `monthEnd`, format helpers, `FloatingNav`, `statusColors`.
- Produces:
  - `CalendarScreen`: month header with prev/next, circles per day colored by status, holidays in red text, today with a primary ring, past unanswered required days with a red ring. Tapping a non-holiday weekday opens `showAnswerSheet`.
  - `SettingsScreen`: temporary, replaced in milestone 3. Language (system, Indonesia, English), mode, fixed weekdays or quota number and period.
  - `Shell`: `IndexedStack` of Home, Calendar, Settings with a `FloatingNav` pill at the bottom.

- [ ] **Step 1: Calendar**

`lib/ui/calendar_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/schedule.dart';
import '../l10n/l10n.dart';
import 'answer_panel.dart';
import 'format.dart';
import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(ctxProvider);
    final l = context.l10n;
    final colors = context.colors;
    final primary = Theme.of(context).colorScheme.primary;
    final month = _month ??= monthStart(c.today);
    final lead = month.weekday - 1;
    final last = monthEnd(month).day;
    final weekdays = shortWeekdays(context);

    Widget cell(int day) {
      final d = DateTime(month.year, month.month, day);
      final log = c.logFor(d);
      final holiday = c.holidays.contains(d);
      final tappable = isWeekday(d) && !holiday;
      final missing = d.isBefore(c.today) &&
          log == null &&
          !d.isBefore(c.settings.trackingSince) &&
          needsAnswer(d, c.settings, c.logs, c.holidays);
      final fill = log == null ? null : statusColors(colors, log.status);
      final border = d == c.today
          ? Border.all(color: primary, width: 2)
          : missing
              ? Border.all(color: colors.qRed, width: 1.5)
              : null;
      return GestureDetector(
        onTap: tappable ? () => showAnswerSheet(context, d) : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill?.$1, border: border),
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: fill?.$2 ?? (holiday ? colors.qRed : (isWeekday(d) ? colors.ink : colors.ink2)),
            ),
          ),
        ),
      );
    }

    Widget legend(Color color, String label, {bool ring = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ring ? null : color,
                border: ring ? Border.all(color: color, width: 1.5) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, color: colors.ink2)),
          ],
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(AppIcons.prev), onPressed: () => _shift(-1)),
            Text(
              fmtMonth(context, month),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            IconButton(icon: const Icon(AppIcons.next), onPressed: () => _shift(1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(child: Text(w, style: TextStyle(fontSize: 11, color: colors.ink2))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox(),
            for (var day = 1; day <= last; day++) cell(day),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            legend(colors.onOffice, l.answerOffice),
            legend(colors.onLeave, l.answerLeave),
            legend(colors.onSick, l.answerSick),
            if (c.settings.mode == WorkMode.fixed) legend(colors.onMoved, l.answerMove),
            legend(colors.qRed, l.legendMissing, ring: true),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Temporary settings screen**

`lib/ui/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import '../l10n/l10n.dart';
import 'format.dart';

// Temporary. Replaced by the real Settings screen in milestone 3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l = context.l10n;
    final weekdays = shortWeekdays(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
      children: [
        Text(l.tabSettings, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Text(l.language, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<AppLanguage>(
          segments: [
            ButtonSegment(value: AppLanguage.system, label: Text(l.langSystem)),
            ButtonSegment(value: AppLanguage.id, label: Text(l.langId)),
            ButtonSegment(value: AppLanguage.en, label: Text(l.langEn)),
          ],
          selected: {s.language},
          onSelectionChanged: (v) => notifier.update(s.copyWith(language: v.first)),
        ),
        const SizedBox(height: 24),
        SegmentedButton<WorkMode>(
          segments: [
            ButtonSegment(value: WorkMode.fixed, label: Text(l.modeFixed)),
            ButtonSegment(value: WorkMode.quota, label: Text(l.modeQuota)),
          ],
          selected: {s.mode},
          onSelectionChanged: (v) => notifier.update(s.copyWith(mode: v.first)),
        ),
        const SizedBox(height: 16),
        if (s.mode == WorkMode.fixed)
          Wrap(
            spacing: 8,
            children: [
              for (var d = 1; d <= 5; d++)
                FilterChip(
                  label: Text(weekdays[d - 1]),
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
            segments: [
              ButtonSegment(value: QuotaPeriod.week, label: Text(l.periodWeek)),
              ButtonSegment(value: QuotaPeriod.month, label: Text(l.periodMonth)),
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
              Text(l.quotaValue(s.quota)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => notifier.update(s.copyWith(quota: s.quota + 1)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 3: Shell with floating pill nav**

`lib/ui/shell.dart` (replace the stub):

```dart
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'icons.dart';
import 'settings_screen.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: const [HomeScreen(), CalendarScreen(), SettingsScreen()],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: FloatingNav(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
                entries: [
                  NavEntry(AppIcons.home, AppIcons.homeActive, l.tabHome),
                  NavEntry(AppIcons.calendar, AppIcons.calendarActive, l.tabCalendar),
                  NavEntry(AppIcons.settings, AppIcons.settingsActive, l.tabSettings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify and commit**

```bash
fvm flutter analyze
fvm flutter test
git add lib/ui
git commit -m "Add calendar, temporary settings screen and floating nav shell"
```

Expected: `No issues found!` and all tests pass.

---

### Task 15: Manual verification on an Android emulator and wrap-up

**Files:**
- Modify: `docs/superpowers/progress.md`, `docs/superpowers/specs/2026-10-12-flexy-day-design.md` (only if behavior differs from the spec)

- [ ] **Step 1: Run on an emulator**

```bash
fvm flutter emulators
fvm flutter emulators --launch <emulator-id>
fvm flutter run
```

If no emulator exists, create one in Android Studio (Device Manager) first. Expected: the app launches on Home with the floating pill nav and no crash.

- [ ] **Step 2: Walk through this checklist**

Mark each result in `progress.md`.

1. Fresh install shows Home: large weekday, hero card, bento summary with `-` for attendance when nothing is logged.
2. Fixed mode (default Mon, Wed, Fri) on an office day: the violet hero shows the question and four tiles. Choosing a tile reveals the note field and Save.
3. Answer "Office" with a note and save. The hero turns mint with "Change answer". Change it to "Sick" through the sheet. The bento counts update.
4. Choose "Move day". Save stays inactive until a date pill is selected. Weekends, past dates, and holidays are not offered.
5. After a move, Home shows the next office day including the target. Change the same day back to "Office": the target stops being an office day.
6. Calendar: circles match statuses, today has a primary ring, a past required day with no answer has a red ring. Tap one, fill it, and the Home banner count drops.
7. Settings tab: switch to Quota. The "Move day" tile disappears. The quota card shows dots (or a bar above 7) and a green, yellow, or red chip matching the rule in Global Constraints. Change the quota number and period and watch it change.
8. Language: switch System, Indonesia, English. Every visible string changes, including month and weekday names. With the device in a language other than id or en, System shows English.
9. Dark mode: switch the emulator to dark. Contrast is readable on hero, tiles, calendar, and status colors.
10. Kill and reopen the app. Answers, settings, and language persist.
11. Percent check: for the current month compute by hand `office / (weekdays - holidays - leave - sick)` and compare with Home.

- [ ] **Step 3: Record results and fix gaps**

Update `docs/superpowers/progress.md`: tick milestone 1 tasks, record the Flutter and package versions actually resolved (`fvm flutter --version`, `pubspec.lock`), the l10n output location, and any failures. Fix real bugs in new commits. If behavior differs from the spec, edit the spec in the same commit and say why.

- [ ] **Step 4: Commit and push the branch**

```bash
git add -A
git commit -m "Record milestone 1 verification results"
git push -u origin milestone-1
```

Do not open a pull request until the user asks.
