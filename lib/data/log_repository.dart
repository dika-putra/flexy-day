import 'package:drift/drift.dart';

import '../domain/dates.dart';
import '../domain/models.dart';
import 'database.dart';

class LogRepository {
  LogRepository(this._db);

  final AppDatabase _db;

  Stream<List<DayLog>> watchAll() =>
      _db.select(_db.dayLogs).watch().map((rows) => rows.map(_toDomain).toList());

  Future<void> upsert(DayLog log) => _db.into(_db.dayLogs).insertOnConflictUpdate(
        DayLogsCompanion.insert(
          date: dateKey(log.date),
          status: log.status.name,
          note: Value(log.note),
          rescheduledTo: Value(log.rescheduledTo == null ? null : dateKey(log.rescheduledTo!)),
        ),
      );

  DayLog _toDomain(DayLogRow r) => DayLog(
        date: parseDateKey(r.date),
        status: DayStatus.values.byName(r.status),
        note: r.note,
        rescheduledTo: r.rescheduledTo == null ? null : parseDateKey(r.rescheduledTo!),
      );
}
