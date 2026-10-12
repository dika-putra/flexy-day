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
