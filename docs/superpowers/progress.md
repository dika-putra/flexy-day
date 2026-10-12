# Flexy Day Progress

Single place to see where the project stands. Update this file in the same commit as the work it describes. Step-level checkboxes live in each plan file.

Last updated: 2026-10-12 (plan revised for theme, i18n, new components)

## Milestones

| # | Milestone | Status | Plan |
|---|-----------|--------|------|
| 0 | Design spec | Done | [spec](specs/2026-10-12-flexy-day-design.md) |
| 1 | Domain, database, Home, calendar, amend | Not started | [plan](plans/2026-10-12-milestone-1-domain-and-home.md) |
| 2 | Notifications, blocking screen, permissions | Not planned | write after milestone 1 |
| 3 | Onboarding, settings, holiday management, polish | Not planned | write after milestone 2 |

Status values: Not planned, Not started, In progress, Blocked, Done.

## Milestone 1 tasks

- [ ] 1. Scaffold project, dependencies, l10n config, font
- [ ] 2. Domain models and date helpers
- [ ] 3. Schedule logic (office days, reschedule, unanswered)
- [ ] 4. Monthly summary
- [ ] 5. Quota status
- [ ] 6. Database and log repository
- [ ] 7. Holiday repository and seed
- [ ] 8. Settings repository (includes language)
- [ ] 9. Strings (en, id) and theme
- [ ] 10. Providers and app bootstrap
- [ ] 11. Shared UI pieces (icons, formatting, widgets)
- [ ] 12. Answer panel and sheet
- [ ] 13. Home screen
- [ ] 14. Calendar, temporary settings screen, shell
- [ ] 15. Manual verification on emulator and wrap-up

Checkpoints for inline execution: A = tasks 1 to 5, B = tasks 6 to 8, C = tasks 9 to 14, D = task 15 (needs the user at the emulator).

## Decisions

- 2026-10-12: Android only, Flutter, local-only, no backend.
- 2026-10-12: Both fixed-day and quota modes. Quota mode has no per-day plan: every working day asks until the quota is met. Quota period is `week` or `month`, chosen by the user.
- 2026-10-12: "Did not go" is recorded as `leave`. There is no separate skipped status.
- 2026-10-12: Percent = office / (weekdays - holidays - leave - sick).
- 2026-10-12: Holidays from a bundled JSON asset plus manual edits. No API.
- 2026-10-12: Unanswered past days do not block. They show in the calendar and as a Home banner.
- 2026-10-12: App name is Flexy Day.
- 2026-10-12: Milestone 1 adds `trackingSince` to settings so "unanswered" has a start date. The spec is updated to match.
- 2026-10-12: UI direction approved from mockups: primary violet `#6E56F8`, pastel status colors, hero card, bento summary, calendar circles, floating pill nav. Phosphor icons, Plus Jakarta Sans font.
- 2026-10-12: Two languages (English, Indonesian) via ARB and gen-l10n. Language is a setting (system, id, en). All strings live in ARB files.
- 2026-10-12: Blocking screen design approved from mockups (milestone 2): full-screen color wash, large question, answer tiles, reschedule date strip. In quota mode the wash follows the quota status. The notification has no answer buttons.

## Open items (verify before relying on them)

- Application id `com.dienn.flexyday`: confirmed by the user on 2026-10-12. Dart package name is `flexyday`. Cannot change after release.
- Play Store name availability for "Flexy Day": the user says they checked, not recorded here.
- Flutter version: not chosen yet. FVM has 3.24.5 and 3.47.0 (needs setup, which downloads SDK artifacts: the user has not yet approved). Package versions: not chosen yet. Record the resolved versions here after milestone 1 Task 1.
- Plus Jakarta Sans files: the download needs the user's permission (name, source, size). License and exact source unverified until opened.
- Phosphor icon names in `lib/ui/icons.dart` are from memory and unverified. The l10n output location (`lib/l10n` vs synthetic package) depends on the resolved Flutter version.
- Holiday data: `assets/holidays/holidays.json` is an empty array. It needs real national holidays and collective leave from the official decree, current and next year.
- Notification reboot behavior, exact alarm permission, and Android 14+ full-screen intent limits: unverified. Check in milestone 2 against the pinned plugin version.
- Generated drift files (`*.g.dart`) are not committed. After a fresh clone run `fvm dart run build_runner build --delete-conflicting-outputs`.

## Environment

- Flutter is managed with FVM. Use `fvm flutter` and `fvm dart`. `flutter` is not on PATH.
- Test on an Android emulator. Firebase Studio is not an option (shutting down 2027-03-22).

## Log

- 2026-10-12: Spec written, repo made public, milestone 1 plan written, then revised for design direction and two languages (now 15 tasks). Branch `milestone-1` created, no code yet.
