# Flexy Day Design Spec

Android app (Flutter) to plan and track office days (WFO) for hybrid and full-WFO workers. It reminds the user the night before, forces an answer on the day via a persistent notification and a blocking screen, and summarizes attendance per month.

Status: design agreed, no code yet. This file is the spec. Do not add features outside it without asking.

## Scope

- Platform: Android only. Flutter. Local-only: no backend, no accounts, no sync.
- Local notifications and local storage only.
- Out of scope for now: iOS, web, desktop, accounts, sync, widgets, export, multi-month statistics.

## Work modes

User picks one mode in onboarding and can change it in settings.

- **Fixed days:** the user picks weekdays (for example Mon and Wed). Only those days need an answer.
- **Quota:** the user sets a number of office days per period (`quotaPeriod = week | month`), for example 3 per week or 12 per month. No fixed days. Every working day needs an answer until the quota is met.

## Daily answer

One answer per date. Options:

- Went to the office
- Day off (also used for "did not go")
- Sick
- Reschedule (fixed mode only): move the office day to another weekday. The target date is mandatory and must be a future weekday that is not a holiday.

Every answer takes an optional note. The user can amend any past or present answer later. An unanswered date has no row.

## Data model

Local storage with `drift` (SQLite). Settings in `SharedPreferences`.

- `DayLog(date PK, status, note, rescheduledTo?)`. `status` is `office | leave | sick | rescheduled`. One row per date, so amend is an update.
- `Holiday(date PK, name, source)`. `source` is `bundled` or `user`.
- Settings: `mode`, `fixedWeekdays`, `quota`, `quotaPeriod`, `buffer` (default 2), `reminderTime` (default 20:00, evening before), `blockingTime` (default 08:00), `trackingSince` (date of first launch; "unanswered" days are counted from here, so nothing before it shows as missing).

There is no separate plan table. Effective office days in fixed mode are computed: the fixed weekday pattern, plus dates that are the target of a reschedule, minus dates that were moved out. Amending a `rescheduled` row to another status removes its target automatically.

## Domain logic

Pure Dart, no Flutter imports, unit tested.

- `hariWajib(date)`: whether a date is an office day (fixed mode).
- `ringkasanBulan(month)`: office, leave, sick, denominator, percent.
  - denominator = weekdays - national holidays - leave - sick
  - percent = office / denominator
  - Unanswered past days are not counted as office.
- `statusKuota(today)`: quota mode status.
  - need = quota - office days in the period
  - available = remaining weekdays in the period - holidays - leave already logged
  - green: available - need > buffer
  - yellow: 0 <= available - need <= buffer (act soon)
  - red: need > available (quota cannot be met)

The period window is the current week or month depending on `quotaPeriod`. Same formula for both.

## Holidays

No API. A bundled JSON asset holds national holidays and collective leave for the current and next year, seeded into `Holiday`. The user can add and remove entries (company holidays differ). Holidays are excluded from the denominator and from reminders. If a year has no bundled data, show a warning in settings and compute without holidays for that year. The bundled file needs a yearly update after the government decree is published.

## Notifications

All local. No server.

- **Evening reminder (default 20:00):** fixed mode, only when tomorrow is an office day. Quota mode, every evening before a working day, with quota progress and status color in the body. Never before a holiday.
- **Morning trigger (default 08:00):** exact alarm, persistent (not swipeable) notification, repeated every 30 minutes until today is answered. Answering cancels the rest of that day. No trigger on a non-office day in fixed mode, or on holidays.
- **Rolling window:** schedule only the next 14 days. Rebuild after app open, after any answer, after device reboot, and on resume when timezone or system time changed. Use the device timezone.
- **Quota alert:** an extra notification only when the status color changes to yellow or red.
- **Permissions:** requested in onboarding: notifications and exact alarms. If denied, the app still works and shows a warning that reminders may be late.

## Blocking screen

An in-app gate, not an OS lock. If today needs an answer, is unanswered, and the time is past `blockingTime`, every app open or resume goes to this screen. It cannot be dismissed with back. Tapping the morning notification opens it too.

- Fixed mode, office day: date, then Went to the office / Reschedule (pick target date) / Day off / Sick, with a note field.
- Quota mode: progress ("attended 4 of 12, 8 left") and the color badge, then Went to the office / Day off / Sick, with a note field.
- Fixed mode on a non-office day: no blocking.

Unanswered past days do not block. They show as "unanswered" in the calendar and as a banner on Home ("N days not filled"). The user can fill them any time.

## Screens

1. Onboarding (once): mode, days or quota and period, permissions, default times.
2. Home: today card, unanswered banner, quota badge (quota mode) or next office day (fixed mode), this month summary (office, leave, sick, percent).
3. Calendar and history: one month, status colors, holidays marked, tap a day to amend or fill.
4. Settings: mode, days or quota and period, buffer, reminder and blocking times, manage holidays.
5. Blocking screen: route outside the main navigation.

## Code structure

Feature-first, three layers.

- `domain/`: models and the pure functions above.
- `data/`: `drift` tables, repositories, holiday seed from asset.
- `notifications/`: the rolling-window scheduler. Only this layer touches the notification plugin.
- `ui/`: screens. State with Riverpod. The blocking gate is a `redirect` in `go_router`.

Core dependencies: `drift`, `flutter_local_notifications`, `timezone`, `flutter_riverpod`, `go_router`, `shared_preferences`. Pin versions at setup time and check them first. Do not add a dependency for something a few lines can do.

## Testing

- Unit tests for all of `domain/` with `flutter test`. Cover month boundaries, months with holidays, quota that cannot be met, quota period week and month, and reschedule followed by amend.
- Notifications and the blocking screen are tested manually on an Android emulator (shift the system clock for the 08:00 and evening cases) and ideally on a real device for battery and Doze behavior.
- Firebase Studio is not an option: it is being shut down on 2027-03-22 and no longer accepts new workspaces.

## Milestones

1. Domain, database, unit tests, Home, calendar, amend. No notifications.
2. Notifications, blocking screen, permissions. Highest risk, test on emulator.
3. Onboarding, settings, holiday management, polish.

## Known unknowns (unverified)

- Whether `flutter_local_notifications` reschedules alarms after reboot out of the box, and the exact manifest setup. Check the plugin docs for the pinned version.
- Android 12+ exact alarm permission behavior and what the user must enable manually in system settings.
- Android 14+ restrictions on full-screen intents. The design does not depend on them; the persistent repeating notification is the enforcement mechanism.
- Source and format of the holiday JSON. Needs to be built from the official decree.
- Package id and Play Store name availability for "Flexy Day". The package id cannot change after release.

## Conventions

- Comment only complex logic or workarounds. Workarounds for external issues need the library and version, the issue link, status with date checked, and what to change once fixed. Only link pages that were opened.
- Commit messages in English, short imperative subject. No AI attribution lines.
- Never invent URLs, versions, or file contents. Write "unverified" when unsure.
