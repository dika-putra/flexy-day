import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/holiday_repository.dart';
import '../data/log_repository.dart';
import '../data/settings_repository.dart';
import '../domain/dates.dart';
import '../domain/models.dart';

final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('override in main'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'flexy_day'));
  ref.onDispose(db.close);
  return db;
});

final logRepositoryProvider =
    Provider((ref) => LogRepository(ref.watch(databaseProvider)));

final holidayRepositoryProvider =
    Provider((ref) => HolidayRepository(ref.watch(databaseProvider)));

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => ref
      .read(settingsRepositoryProvider)
      .load(dateOnly(ref.read(clockProvider)()));

  Future<void> update(Settings s) async {
    state = s;
    await ref.read(settingsRepositoryProvider).save(s);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

final localeProvider = Provider<Locale?>((ref) => switch (ref.watch(settingsProvider).language) {
      AppLanguage.system => null,
      AppLanguage.id => const Locale('id'),
      AppLanguage.en => const Locale('en'),
    });

final logsProvider =
    StreamProvider<List<DayLog>>((ref) => ref.watch(logRepositoryProvider).watchAll());

final holidaysProvider = StreamProvider<Set<DateTime>>(
    (ref) => ref.watch(holidayRepositoryProvider).watchDates());

class Ctx {
  const Ctx({
    required this.today,
    required this.settings,
    required this.logs,
    required this.holidays,
  });

  final DateTime today;
  final Settings settings;
  final List<DayLog> logs;
  final Set<DateTime> holidays;

  DayLog? logFor(DateTime d) {
    final k = dateOnly(d);
    for (final l in logs) {
      if (dateOnly(l.date) == k) return l;
    }
    return null;
  }
}

final ctxProvider = Provider<Ctx>((ref) => Ctx(
      today: dateOnly(ref.watch(clockProvider)()),
      settings: ref.watch(settingsProvider),
      logs: ref.watch(logsProvider).value ?? const [],
      holidays: ref.watch(holidaysProvider).value ?? const {},
    ));
