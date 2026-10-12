import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.tint,
    required this.ink,
    required this.ink2,
    required this.office,
    required this.onOffice,
    required this.leave,
    required this.onLeave,
    required this.sick,
    required this.onSick,
    required this.moved,
    required this.onMoved,
    required this.qGreen,
    required this.qYellow,
    required this.qRed,
  });

  final Color bg, card, tint, ink, ink2;
  final Color office, onOffice, leave, onLeave, sick, onSick, moved, onMoved;
  final Color qGreen, qYellow, qRed;

  static const light = AppColors(
    bg: Color(0xFFF7F6FB),
    card: Color(0xFFFFFFFF),
    tint: Color(0xFFEFEDFA),
    ink: Color(0xFF1B1A2E),
    ink2: Color(0xFF6B6A80),
    office: Color(0xFFCFF5E7),
    onOffice: Color(0xFF0B8F6A),
    leave: Color(0xFFD6EAFF),
    onLeave: Color(0xFF2F7DE1),
    sick: Color(0xFFFFD9E0),
    onSick: Color(0xFFD6336C),
    moved: Color(0xFFFFF0C2),
    onMoved: Color(0xFFA8710F),
    qGreen: Color(0xFF1FB57A),
    qYellow: Color(0xFFF5B301),
    qRed: Color(0xFFF0476A),
  );

  static const dark = AppColors(
    bg: Color(0xFF121120),
    card: Color(0xFF1C1B2E),
    tint: Color(0xFF25233B),
    ink: Color(0xFFF2F1FA),
    ink2: Color(0xFFA09FB8),
    office: Color(0xFF1D4D3F),
    onOffice: Color(0xFF6FE3B6),
    leave: Color(0xFF1B3A66),
    onLeave: Color(0xFF8DBBFF),
    sick: Color(0xFF4A1F2E),
    onSick: Color(0xFFFF8FB0),
    moved: Color(0xFF4A3A12),
    onMoved: Color(0xFFFFD36B),
    qGreen: Color(0xFF1FB57A),
    qYellow: Color(0xFFF5B301),
    qRed: Color(0xFFF0476A),
  );

  @override
  AppColors copyWith() => this;

  // ponytail: no animated theme switch, so lerp just snaps to the target.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => other is AppColors ? (t < 0.5 ? this : other) : this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const _primaryLight = Color(0xFF6E56F8);
const _primaryDark = Color(0xFF9A87FF);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: _primaryLight,
    brightness: brightness,
  ).copyWith(
    primary: dark ? _primaryDark : _primaryLight,
    onPrimary: dark ? const Color(0xFF1B1A2E) : Colors.white,
    primaryContainer: dark ? const Color(0xFF3A3170) : const Color(0xFFE4DFFF),
    onSurface: c.ink,
    surface: c.card,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    extensions: [c],
  );
}
