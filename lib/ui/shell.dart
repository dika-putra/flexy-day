import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'icons.dart';
import 'settings_screen.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: const [HomeScreen(), CalendarScreen(), SettingsScreen()],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: FloatingNav(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
                entries: [
                  NavEntry(AppIcons.home, AppIcons.homeActive, l.tabHome),
                  NavEntry(AppIcons.calendar, AppIcons.calendarActive, l.tabCalendar),
                  NavEntry(AppIcons.settings, AppIcons.settingsActive, l.tabSettings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
