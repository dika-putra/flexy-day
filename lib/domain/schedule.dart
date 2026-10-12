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
