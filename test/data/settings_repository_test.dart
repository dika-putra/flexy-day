import 'package:flexyday/data/settings_repository.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults on first load, trackingSince is today', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    final s = repo.load(date('2026-10-12'));
    expect(s.mode, WorkMode.fixed);
    expect(s.fixedWeekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});
    expect(s.quota, 3);
    expect(s.quotaPeriod, QuotaPeriod.week);
    expect(s.buffer, 2);
    expect(s.language, AppLanguage.system);
    expect(s.trackingSince, date('2026-10-12'));
  });

  test('trackingSince is kept on later loads', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    repo.load(date('2026-10-12'));
    expect(repo.load(date('2026-11-20')).trackingSince, date('2026-10-12'));
  });

  test('save then load round trips', () async {
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    final base = repo.load(date('2026-10-12'));
    await repo.save(base.copyWith(
      mode: WorkMode.quota,
      fixedWeekdays: {DateTime.tuesday},
      quota: 12,
      quotaPeriod: QuotaPeriod.month,
      buffer: 1,
      language: AppLanguage.id,
    ));
    final s = repo.load(date('2026-10-13'));
    expect(s.mode, WorkMode.quota);
    expect(s.fixedWeekdays, {DateTime.tuesday});
    expect(s.quota, 12);
    expect(s.quotaPeriod, QuotaPeriod.month);
    expect(s.buffer, 1);
    expect(s.language, AppLanguage.id);
    expect(s.trackingSince, date('2026-10-12'));
  });
}
