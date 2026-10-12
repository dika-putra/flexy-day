# Flexy Day Progress

Single place to see where the project stands. Update this file in the same commit as the work it describes. Step-level checkboxes live in each plan file.

Last updated: 2026-10-12

## Milestones

| # | Milestone | Status | Plan |
|---|-----------|--------|------|
| 0 | Design spec | Done | [spec](specs/2026-10-12-flexy-day-design.md) |
| 1 | Domain, database, Home, calendar, amend | Not started | [plan](plans/2026-10-12-milestone-1-domain-and-home.md) |
| 2 | Notifications, blocking screen, permissions | Not planned | write after milestone 1 |
| 3 | Onboarding, settings, holiday management, polish | Not planned | write after milestone 2 |

Status values: Not planned, Not started, In progress, Blocked, Done.

## Milestone 1 tasks

- [ ] 1. Scaffold project and dependencies
- [ ] 2. Domain models and date helpers
- [ ] 3. Schedule logic (office days, reschedule, unanswered)
- [ ] 4. Monthly summary
- [ ] 5. Quota status
- [ ] 6. Database and log repository
- [ ] 7. Holiday repository and seed
- [ ] 8. Settings repository
- [ ] 9. Providers and app bootstrap
- [ ] 10. Shared UI (format, quota badge, answer sheet)
- [ ] 11. Home screen, shell, temporary settings sheet
- [ ] 12. Calendar screen with amend
- [ ] 13. Manual verification on emulator and wrap-up

## Decisions

- 2026-10-12: Android only, Flutter, local-only, no backend.
- 2026-10-12: Both fixed-day and quota modes. Quota mode has no per-day plan: every working day asks until the quota is met. Quota period is `week` or `month`, chosen by the user.
- 2026-10-12: "Did not go" is recorded as `leave`. There is no separate skipped status.
- 2026-10-12: Percent = office / (weekdays - holidays - leave - sick).
- 2026-10-12: Holidays from a bundled JSON asset plus manual edits. No API.
- 2026-10-12: Unanswered past days do not block. They show in the calendar and as a Home banner.
- 2026-10-12: App name is Flexy Day.
- 2026-10-12: Milestone 1 adds `trackingSince` to settings so "unanswered" has a start date. The spec is updated to match.

## Open items (verify before relying on them)

- Application id `com.dikaputra.flexy_day`: proposed, needs the user's confirmation before milestone 1 Task 1. Cannot change after release.
- Play Store name availability for "Flexy Day": the user says they checked, not recorded here.
- Flutter and package versions: not chosen yet. Record the resolved versions here after milestone 1 Task 1.
- Holiday data: `assets/holidays/holidays.json` is an empty array. It needs real national holidays and collective leave from the official decree, current and next year.
- Notification reboot behavior, exact alarm permission, and Android 14+ full-screen intent limits: unverified. Check in milestone 2 against the pinned plugin version.
- Generated drift files (`*.g.dart`) are not committed. After a fresh clone run `fvm dart run build_runner build --delete-conflicting-outputs`.

## Environment

- Flutter is managed with FVM. Use `fvm flutter` and `fvm dart`.
- Test on an Android emulator. Firebase Studio is not an option (shutting down 2027-03-22).

## Log

- 2026-10-12: Spec written, repo made public, milestone 1 plan written.
