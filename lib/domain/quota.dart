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
