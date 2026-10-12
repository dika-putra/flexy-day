import 'package:drift/native.dart';
import 'package:flexyday/data/database.dart';
import 'package:flexyday/data/holiday_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late HolidayRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HolidayRepository(db);
  });
  tearDown(() => db.close());

  const seed = '[{"date":"2099-01-01","name":"Test A"},{"date":"2099-01-02","name":"Test B"}]';

  test('seed inserts holidays', () async {
    await repo.seedBundled(seed);
    expect(await repo.watchDates().first, {date('2099-01-01'), date('2099-01-02')});
  });

  test('seeding twice does not duplicate or overwrite user entries', () async {
    await db.into(db.holidays).insert(
          HolidaysCompanion.insert(date: '2099-01-02', name: 'Mine', source: 'user'),
        );
    await repo.seedBundled(seed);
    await repo.seedBundled(seed);
    final rows = await db.select(db.holidays).get();
    expect(rows, hasLength(2));
    expect(rows.firstWhere((r) => r.date == '2099-01-02').name, 'Mine');
  });

  test('an empty seed is fine', () async {
    await repo.seedBundled('[]');
    expect(await repo.watchDates().first, isEmpty);
  });
}
