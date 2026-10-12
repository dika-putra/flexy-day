import 'package:shared_preferences/shared_preferences.dart';

import '../domain/dates.dart';
import '../domain/models.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  Settings load(DateTime today) {
    var since = _prefs.getString('trackingSince');
    if (since == null) {
      since = dateKey(dateOnly(today));
      _prefs.setString('trackingSince', since);
    }
    return Settings(
      trackingSince: parseDateKey(since),
      mode: WorkMode.values.byName(_prefs.getString('mode') ?? 'fixed'),
      fixedWeekdays: (_prefs.getStringList('fixedWeekdays') ?? ['1', '3', '5'])
          .map(int.parse)
          .toSet(),
      quota: _prefs.getInt('quota') ?? 3,
      quotaPeriod: QuotaPeriod.values.byName(_prefs.getString('quotaPeriod') ?? 'week'),
      buffer: _prefs.getInt('buffer') ?? 2,
      language: AppLanguage.values.byName(_prefs.getString('language') ?? 'system'),
    );
  }

  Future<void> save(Settings s) async {
    await _prefs.setString('mode', s.mode.name);
    await _prefs.setStringList('fixedWeekdays', [for (final d in s.fixedWeekdays) '$d']);
    await _prefs.setInt('quota', s.quota);
    await _prefs.setString('quotaPeriod', s.quotaPeriod.name);
    await _prefs.setInt('buffer', s.buffer);
    await _prefs.setString('language', s.language.name);
  }
}
