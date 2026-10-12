import 'package:flexyday/app/providers.dart';
import 'package:flexyday/domain/models.dart';
import 'package:flexyday/l10n/l10n.dart';
import 'package:flexyday/ui/answer_panel.dart';
import 'package:flexyday/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpPanel(WidgetTester t, Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
      logsProvider.overrideWith((ref) => Stream.value(const <DayLog>[])),
      holidaysProvider.overrideWith((ref) => Stream.value(const <DateTime>{})),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: SingleChildScrollView(child: AnswerPanel(date: DateTime(2026, 10, 12))),
      ),
    ),
  ));
  await t.pump();
}

void main() {
  testWidgets('fixed mode: move day needs a target date before Save is active', (t) async {
    await pumpPanel(t, {'trackingSince': '2026-10-01'}); // default fixed Mon/Wed/Fri
    expect(find.text('Move day'), findsOneWidget);

    await t.tap(find.text('Move day'));
    await t.pumpAndSettle();
    FilledButton save() => t.widget<FilledButton>(find.byType(FilledButton));
    expect(save().onPressed, isNull);

    await t.tap(find.text('13')); // Tuesday, the first selectable date
    await t.pump();
    expect(save().onPressed, isNotNull);
  });

  testWidgets('office needs no target date', (t) async {
    await pumpPanel(t, {'trackingSince': '2026-10-01'});
    await t.tap(find.text('Office'));
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('quota mode has no move day option', (t) async {
    await pumpPanel(t, {'trackingSince': '2026-10-01', 'mode': 'quota'});
    expect(find.text('Move day'), findsNothing);
    expect(find.text('Office'), findsOneWidget);
  });
}
