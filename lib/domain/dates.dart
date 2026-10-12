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
