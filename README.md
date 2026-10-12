# Flexy Day

Android app to plan and track office days (WFO) for hybrid and full-WFO workers.

- Pick fixed weekdays or a quota (for example 3 days per week, or 12 per month).
- Evening reminder the day before.
- On the day, a persistent notification and a blocking screen ask: went to the office, reschedule, day off, or sick (with a note). Answers can be amended later.
- Monthly summary: days attended, day off, sick, and the attendance percentage. National holidays, leave, and sick days are excluded from the percentage.
- Quota mode shows a green, yellow, or red status so you know if the quota is still reachable.

Everything runs locally on the device. No account and no backend.

## Status

Design only, no code yet. The full spec is in [design spec](docs/superpowers/specs/2026-10-12-flexy-day-design.md).

## Stack

Flutter, Android only.
