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
