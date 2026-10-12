enum DayStatus { office, leave, sick, rescheduled }

enum WorkMode { fixed, quota }

enum QuotaPeriod { week, month }

enum QuotaLevel { green, yellow, red }

enum AppLanguage { system, id, en }

class DayLog {
  const DayLog({
    required this.date,
    required this.status,
    this.note,
    this.rescheduledTo,
  });

  final DateTime date;
  final DayStatus status;
  final String? note;
  final DateTime? rescheduledTo;
}

class Settings {
  const Settings({
    required this.trackingSince,
    this.mode = WorkMode.fixed,
    this.fixedWeekdays = const {DateTime.monday, DateTime.wednesday, DateTime.friday},
    this.quota = 3,
    this.quotaPeriod = QuotaPeriod.week,
    this.buffer = 2,
    this.language = AppLanguage.system,
  });

  final WorkMode mode;
  final Set<int> fixedWeekdays;
  final int quota;
  final QuotaPeriod quotaPeriod;
  final int buffer;
  final DateTime trackingSince;
  final AppLanguage language;

  Settings copyWith({
    WorkMode? mode,
    Set<int>? fixedWeekdays,
    int? quota,
    QuotaPeriod? quotaPeriod,
    int? buffer,
    AppLanguage? language,
  }) =>
      Settings(
        trackingSince: trackingSince,
        mode: mode ?? this.mode,
        fixedWeekdays: fixedWeekdays ?? this.fixedWeekdays,
        quota: quota ?? this.quota,
        quotaPeriod: quotaPeriod ?? this.quotaPeriod,
        buffer: buffer ?? this.buffer,
        language: language ?? this.language,
      );
}
