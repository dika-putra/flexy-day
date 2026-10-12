import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../ui/shell.dart';
import '../ui/theme.dart';
import 'providers.dart';

class FlexyDayApp extends ConsumerWidget {
  const FlexyDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        onGenerateTitle: (c) => c.l10n.appName,
        locale: ref.watch(localeProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Shell(),
      );
}
