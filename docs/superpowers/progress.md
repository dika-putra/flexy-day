# Flexy Day Progress

Single place to see where the project stands. Update this file in the same commit as the work it describes. Task-level status lives here. The step checkboxes inside the plan file are not maintained, so ignore them.

Last updated: 2026-10-22 (checkpoint C done: tasks 1 to 14; task 15 blocked on Android SDK; no code changes since 2026-10-12)

## Milestones

| # | Milestone | Status | Plan |
|---|-----------|--------|------|
| 0 | Design spec | Done | [spec](specs/2026-10-12-flexy-day-design.md) |
| 1 | Domain, database, Home, calendar, amend | In progress (tasks 1 to 14 done, 15 blocked) | [plan](plans/2026-10-12-milestone-1-domain-and-home.md) |
| 2 | Notifications, blocking screen, permissions | Not planned | write after milestone 1 |
| 3 | Onboarding, settings, holiday management, polish | Not planned | write after milestone 2 |

Status values: Not planned, Not started, In progress, Blocked, Done.

## Milestone 1 tasks

- [x] 1. Scaffold project, dependencies, l10n config, font
- [x] 2. Domain models and date helpers
- [x] 3. Schedule logic (office days, reschedule, unanswered)
- [x] 4. Monthly summary
- [x] 5. Quota status
- [x] 6. Database and log repository
- [x] 7. Holiday repository and seed
- [x] 8. Settings repository (includes language)
- [x] 9. Strings (en, id) and theme
- [x] 10. Providers and app bootstrap
- [x] 11. Shared UI pieces (icons, formatting, widgets)
- [x] 12. Answer panel and sheet
- [x] 13. Home screen
- [x] 14. Calendar, temporary settings screen, shell
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
- 2026-10-12: Icons use `phosphoricons_flutter`, not the official `phosphor_flutter`, because the official package does not compile on Flutter 3.47.0.
- 2026-10-12: Blocking screen design approved from mockups (milestone 2): full-screen color wash, large question, answer tiles, reschedule date strip. In quota mode the wash follows the quota status. The notification has no answer buttons.

## Open items (verify before relying on them)

- Application id `com.dienn.flexyday`: confirmed by the user on 2026-10-12. Dart package name is `flexyday`. Cannot change after release.
- Play Store name availability for "Flexy Day": the user says they checked, not recorded here.
- Resolved on 2026-10-12: Flutter 3.47.0 (Dart 3.13.0), pinned with FVM (`.fvmrc`). `flutter_riverpod` ^3.4.3, `drift` ^2.35.2, `drift_flutter` ^0.3.1, `shared_preferences` ^2.5.6, `intl` ^0.20.3, `phosphoricons_flutter` ^1.1.1 (see Icons below), dev: `drift_dev` ^2.35.1, `build_runner` ^2.16.2.
- `sqlite3_flutter_libs` resolves to `0.6.0+eol`: checked in its CHANGELOG (2026-10-12). It is an intentionally empty stub because `sqlite3` 3.x bundles SQLite through build hooks. No action needed.
- Riverpod 3.x: verified with a provider smoke test and widget tests (2026-10-12). No API problems found.
- Font: only a variable font exists in google/fonts (`PlusJakartaSans[wght].ttf`, 176 KB, OFL 1.1, downloaded 2026-10-12 into `assets/fonts/`). Whether Flutter maps `FontWeight` to the `wght` axis automatically is unverified. Check in Task 15; if not, use `fontVariations`.
- Icons: the original `phosphor_flutter` 2.1.0 (May 2024, latest) does not compile on Flutter 3.47.0 (`IconData` is a final class). `flutter analyze` did not flag it, a test compile did. Replaced with `phosphoricons_flutter` 1.1.1 (community package, MIT, only imports `flutter/widgets`, same class names). Small third-party package: review again before release. Names in `lib/ui/icons.dart` verified by compiling.
- Holiday data: `assets/holidays/holidays.json` is an empty array. It needs real national holidays and collective leave from the official decree, current and next year.
- Notification reboot behavior, exact alarm permission, and Android 14+ full-screen intent limits: unverified. Check in milestone 2 against the pinned plugin version.
- Generated drift files (`*.g.dart`) are not committed. After a fresh clone run `fvm dart run build_runner build --delete-conflicting-outputs`.

## Where things live

- Branch `milestone-1` on GitHub has everything: code, tests, spec, plan, this file. It is 0 commits ahead of or behind `origin/milestone-1`.
- Default branch `main` still holds the 2026-10-12 docs only: the old plan, the old progress file, the "Design only" README, and no code. No pull request exists yet.
- Plan for `main`: open a PR from `milestone-1` after Task 15 passes on an emulator, so `main` only gets code that has run on Android. Before the PR: grill step, pre-PR review, docs check, then wait for the owner's ok.

## Pending decisions and next steps

| # | Item | Owner | Status |
|---|------|-------|--------|
| 1 | Install the Android SDK and create an emulator in Android Studio (Device Manager), then run Task 15 | Owner | Waiting |
| 2 | After the SDK: real `flutter build apk --debug`, then `flutter run`, then the Task 15 checklist | Claude, with the owner viewing the screen | Blocked by 1 |
| 3 | Merge timing: PR `milestone-1` to `main` after Task 15 (recommended) or earlier | Owner | Open |
| 4 | Author name on the six scaffold-era commits is `Novian Mahardika Putra`, newer commits are `Dika Putra` (same personal email). Fixing it means rewriting public history | Owner | Open, not touched |
| 5 | Delete local branch `milestone-1-old` (holds the commits with `.idea/` and `build/`, never pushed) | Owner | Open, needs the owner's ok |
| 6 | Move dev setup (FVM, `build_runner`, `ANDROID_HOME`) from this file into the README | Owner | Open |
| 7 | Write the milestone 2 plan (notifications, blocking screen, permissions) | Claude | Waiting for the owner to say go |
| 8 | Fill `assets/holidays/holidays.json` from the official decree | Owner and Claude | Not started |

## Deviations from the milestone 1 plan

The plan file was patched where the text was wrong, but these differences from its literal steps remain:

- Font: a single variable font file (`assets/fonts/PlusJakartaSans.ttf`) is declared once, not three static weight files. Google Fonts offers only the variable file.
- Icons: `phosphoricons_flutter` instead of `phosphor_flutter` (plan patched).
- `lib/l10n/l10n.dart`: `AppLocalizations.of(this)!` (the plan had `context`, which does not compile; plan patched).
- `.gitignore`: `flutter create` did not write a full one. The repo now has a standard Flutter one, plus `*.g.dart` and `.fvm/`.
- Extra tests not in the plan: `test/app/providers_test.dart`, `test/app/app_test.dart`, `test/ui/answer_panel_test.dart`, `test/ui/home_screen_test.dart`. Total 48 tests.
- Git history: the scaffold commit once included `.idea/`, `.dart_tool/` and `build/`. The branch was rebuilt before the first push of that code, so the pushed history does not contain them. A local branch `milestone-1-old` still has them (not pushed).

## Blockers

- Android SDK is not installed. `~/Library/Android/sdk` exists but has no platform-tools, build-tools, platforms, or emulator. `flutter doctor` reports "Unable to locate Android SDK". Needed for milestone 1 Task 15, for `flutter build apk`, and for any emulator. Install the SDK and create an emulator in Android Studio (Device Manager). Downloads several GB.
- `ANDROID_HOME` is set in `~/.zshrc` but not loaded in the shell Claude uses. Pass it per command.
- Not yet compiled for Android at all: only `flutter test` and `flutter analyze` ran. A real `flutter build apk --debug` has not been done.

## Environment

- Flutter is managed with FVM. Use `fvm flutter` and `fvm dart`. `flutter` is not on PATH.
- Test on an Android emulator. Firebase Studio is not an option (shutting down 2027-03-22).

## Log

- 2026-10-22: Checked that docs and code are pushed to `milestone-1`. Added the "Where things live" and "Pending decisions and next steps" sections.
- 2026-10-21: Audited the docs against the repo. Fixed the stale README and spec status, the milestone table, the icon package version, and the claim about plan checkboxes. Added the deviations section.
- 2026-10-12: Spec written, repo made public, milestone 1 plan written, then revised for design direction and two languages (now 15 tasks). Branch `milestone-1` created. Checkpoint A done: scaffold, domain logic. Checkpoint B done: database, repositories, settings. Checkpoint C done: strings, theme, providers, UI, 48 tests passing. Task 15 (emulator) blocked: Android SDK not installed.
