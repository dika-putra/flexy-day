import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('DayLogRow')
class DayLogs extends Table {
  TextColumn get date => text()();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  TextColumn get rescheduledTo => text().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

@DataClassName('HolidayRow')
class Holidays extends Table {
  TextColumn get date => text()();
  TextColumn get name => text()();
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(tables: [DayLogs, Holidays])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
