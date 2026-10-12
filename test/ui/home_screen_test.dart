import 'package:flexyday/app/providers.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flexyday/l10n/l10n.dart';
import 'package:flexyday/ui/home_screen.dart';
import 'package:flexyday/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

Future<void> pumpHome(
  WidgetTester t, {
  Map<String, Object> prefsValues = const {},
  List<DayLog> logs = const [],
  String lang = 'en',
}) async {
  SharedPreferences.setMockInitialValues({'trackingSince': '2026-10-01', ...prefsValues});
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)), // Monday
      logsProvider.overrideWith((ref) => Stream.value(logs)),
      holidaysProvider.overrideWith((ref) => Stream.value(const <DateTime>{})),
    ],
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.light),
      home: const Scaffold(body: HomeScreen()),
    ),
  ));
  await t.pump();
}

void main() {
  testWidgets('fixed mode, unanswered office day: hero question and unfilled banner', (t) async {
    await pumpHome(t);
    expect(find.text('Going to the office today?'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    // Office days since 10-01 that are past and empty: Fri 2, Mon 5, Wed 7, Fri 9.
    expect(find.text('4 days not filled in'), findsOneWidget);
  });

  testWidgets('fixed mode, answered today: summary and change action', (t) async {
    await pumpHome(t, logs: [DayLog(date: date('2026-10-12'), status: DayStatus.office)]);
    expect(find.text('At the office'), findsOneWidget);
    expect(find.text('Change answer'), findsOneWidget);
    expect(find.text('Going to the office today?'), findsNothing);
  });

  testWidgets('quota mode shows quota card with status', (t) async {
    await pumpHome(t, prefsValues: {'mode': 'quota'});
    expect(find.text('Quota this week'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.text('Act soon'), findsOneWidget); // slack 2 with buffer 2
    expect(find.text('Attended 0, 3 left, 5 days available'), findsOneWidget);
  });

  testWidgets('Indonesian strings', (t) async {
    await pumpHome(t, lang: 'id');
    expect(find.text('Ngantor hari ini?'), findsOneWidget);
    expect(find.text('Senin'), findsOneWidget);
    expect(find.text('4 hari belum diisi'), findsOneWidget);
  });
}
