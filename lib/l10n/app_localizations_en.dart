// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flexy Day';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabSettings => 'Settings';

  @override
  String get question => 'Going to the office today?';

  @override
  String get answerOffice => 'Office';

  @override
  String get answerMove => 'Move day';

  @override
  String get answerLeave => 'Day off';

  @override
  String get answerSick => 'Sick';

  @override
  String get moveTo => 'Move to';

  @override
  String get noteHint => 'Note (optional)';

  @override
  String get save => 'Save';

  @override
  String get notAnswered => 'Not answered yet';

  @override
  String get changeAnswer => 'Change answer';

  @override
  String get notOfficeDay => 'Today is not an office day.';

  @override
  String get statusOffice => 'At the office';

  @override
  String get statusLeave => 'Day off today';

  @override
  String get statusSick => 'Out sick';

  @override
  String statusMoved(String date) {
    return 'Moved to $date';
  }

  @override
  String unfilledBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days not filled in',
      one: '1 day not filled in',
    );
    return '$_temp0';
  }

  @override
  String nextOffice(String date) {
    return 'Next office day: $date';
  }

  @override
  String get noUpcoming => 'No office days in the next 60 days.';

  @override
  String get quotaWeek => 'Quota this week';

  @override
  String get quotaMonth => 'Quota this month';

  @override
  String quotaProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get quotaGreen => 'On track';

  @override
  String get quotaYellow => 'Act soon';

  @override
  String get quotaRed => 'Quota cannot be met';

  @override
  String quotaStats(int done, int need, int available) {
    return 'Attended $done, $need left, $available days available';
  }

  @override
  String get attendance => 'Attendance';

  @override
  String get statOffice => 'Office';

  @override
  String get statLeave => 'Off';

  @override
  String get statSick => 'Sick';

  @override
  String get legendMissing => 'Not filled in';

  @override
  String get modeFixed => 'Fixed days';

  @override
  String get modeQuota => 'Quota';

  @override
  String get periodWeek => 'Per week';

  @override
  String get periodMonth => 'Per month';

  @override
  String quotaValue(int n) {
    return 'Quota: $n';
  }

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langId => 'Bahasa Indonesia';

  @override
  String get langEn => 'English';
}
