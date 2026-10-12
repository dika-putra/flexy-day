import 'package:drift/native.dart';
import 'package:flexyday/data/database.dart';
import 'package:flexyday/data/log_repository.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late LogRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LogRepository(db);
  });
  tearDown(() => db.close());

  test('upsert stores and watchAll returns the log', () async {
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office, note: 'in'));
    final logs = await repo.watchAll().first;
    expect(logs, hasLength(1));
    expect(logs.single.date, date('2026-10-12'));
    expect(logs.single.status, DayStatus.office);
    expect(logs.single.note, 'in');
  });

  test('upsert on the same date amends the answer', () async {
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office));
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.sick, note: 'flu'));
    final logs = await repo.watchAll().first;
    expect(logs, hasLength(1));
    expect(logs.single.status, DayStatus.sick);
    expect(logs.single.note, 'flu');
  });

  test('reschedule target round trips and clears on amend', () async {
    await repo.upsert(DayLog(
      date: date('2026-10-12'),
      status: DayStatus.rescheduled,
      rescheduledTo: date('2026-10-14'),
    ));
    expect((await repo.watchAll().first).single.rescheduledTo, date('2026-10-14'));
    await repo.upsert(DayLog(date: date('2026-10-12'), status: DayStatus.office));
    expect((await repo.watchAll().first).single.rescheduledTo, isNull);
  });
}
