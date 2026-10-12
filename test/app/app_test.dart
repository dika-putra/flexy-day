import 'package:flexyday/app/app.dart';
import 'package:flexyday/app/providers.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flexyday/ui/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('navigate, open the answer sheet from the calendar, switch language', (t) async {
    SharedPreferences.setMockInitialValues({'trackingSince': '2026-10-01'});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
        logsProvider.overrideWith((ref) => Stream.value(const <DayLog>[])),
        holidaysProvider.overrideWith((ref) => Stream.value(const <DateTime>{})),
      ],
      child: const FlexyDayApp(),
    ));
    await t.pumpAndSettle();

    // Home, English (test device locale).
    expect(find.text('Going to the office today?'), findsOneWidget);

    // Calendar: October 2026, tap Tuesday the 13th.
    await t.tap(find.byIcon(AppIcons.calendar));
    await t.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    await t.tap(find.text('13'));
    await t.pumpAndSettle();
    expect(find.text('Tuesday, October 13, 2026'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    await t.tapAt(const Offset(10, 10)); // dismiss the sheet via the barrier
    await t.pumpAndSettle();

    // Settings: switch to Indonesian, strings change everywhere.
    await t.tap(find.byIcon(AppIcons.settings));
    await t.pumpAndSettle();
    await t.tap(find.text('Bahasa Indonesia'));
    await t.pumpAndSettle();
    expect(find.text('Pengaturan'), findsWidgets);
    await t.tap(find.byIcon(AppIcons.home));
    await t.pumpAndSettle();
    expect(find.text('Ngantor hari ini?'), findsOneWidget);
    expect(prefs.getString('language'), 'id');
  });
}
