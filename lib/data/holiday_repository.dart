import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/dates.dart';
import 'database.dart';

class HolidayRepository {
  HolidayRepository(this._db);

  final AppDatabase _db;

  Stream<Set<DateTime>> watchDates() => _db
      .select(_db.holidays)
      .watch()
      .map((rows) => {for (final r in rows) parseDateKey(r.date)});

  Future<void> seedBundled(String json) async {
    final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    await _db.batch((b) => b.insertAll(
          _db.holidays,
          [
            for (final h in list)
              HolidaysCompanion.insert(
                date: h['date'] as String,
                name: h['name'] as String,
                source: 'bundled',
              ),
          ],
          mode: InsertMode.insertOrIgnore,
        ));
  }
}
