import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flexyday/app/providers.dart';
import 'package:flexyday/data/database.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  test('ctx reflects logs and locale follows the language setting', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9, 30)),
    ]);
    addTearDown(c.dispose);
    c.listen(logsProvider, (_, _) {});
    c.listen(holidaysProvider, (_, _) {});

    expect(c.read(ctxProvider).today, date('2026-10-12'));
    expect(c.read(localeProvider), isNull);

    await c.read(logRepositoryProvider).upsert(
          DayLog(date: date('2026-10-12'), status: DayStatus.office),
        );
    await pumpEventQueue();
    expect(c.read(ctxProvider).logFor(date('2026-10-12'))?.status, DayStatus.office);

    final s = c.read(settingsProvider);
    await c.read(settingsProvider.notifier).update(s.copyWith(language: AppLanguage.id));
    expect(c.read(localeProvider), const Locale('id'));
  });
}
