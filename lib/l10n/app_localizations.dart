import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Flexy Day'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Going to the office today?'**
  String get question;

  /// No description provided for @answerOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get answerOffice;

  /// No description provided for @answerMove.
  ///
  /// In en, this message translates to:
  /// **'Move day'**
  String get answerMove;

  /// No description provided for @answerLeave.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get answerLeave;

  /// No description provided for @answerSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get answerSick;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get moveTo;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @notAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered yet'**
  String get notAnswered;

  /// No description provided for @changeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Change answer'**
  String get changeAnswer;

  /// No description provided for @notOfficeDay.
  ///
  /// In en, this message translates to:
  /// **'Today is not an office day.'**
  String get notOfficeDay;

  /// No description provided for @statusOffice.
  ///
  /// In en, this message translates to:
  /// **'At the office'**
  String get statusOffice;

  /// No description provided for @statusLeave.
  ///
  /// In en, this message translates to:
  /// **'Day off today'**
  String get statusLeave;

  /// No description provided for @statusSick.
  ///
  /// In en, this message translates to:
  /// **'Out sick'**
  String get statusSick;

  /// No description provided for @statusMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {date}'**
  String statusMoved(String date);

  /// No description provided for @unfilledBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day not filled in} other{{count} days not filled in}}'**
  String unfilledBanner(int count);

  /// No description provided for @nextOffice.
  ///
  /// In en, this message translates to:
  /// **'Next office day: {date}'**
  String nextOffice(String date);

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No office days in the next 60 days.'**
  String get noUpcoming;

  /// No description provided for @quotaWeek.
  ///
  /// In en, this message translates to:
  /// **'Quota this week'**
  String get quotaWeek;

  /// No description provided for @quotaMonth.
  ///
  /// In en, this message translates to:
  /// **'Quota this month'**
  String get quotaMonth;

  /// No description provided for @quotaProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String quotaProgress(int done, int total);

  /// No description provided for @quotaGreen.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get quotaGreen;

  /// No description provided for @quotaYellow.
  ///
  /// In en, this message translates to:
  /// **'Act soon'**
  String get quotaYellow;

  /// No description provided for @quotaRed.
  ///
  /// In en, this message translates to:
  /// **'Quota cannot be met'**
  String get quotaRed;

  /// No description provided for @quotaStats.
  ///
  /// In en, this message translates to:
  /// **'Attended {done}, {need} left, {available} days available'**
  String quotaStats(int done, int need, int available);

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @statOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get statOffice;

  /// No description provided for @statLeave.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get statLeave;

  /// No description provided for @statSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get statSick;

  /// No description provided for @legendMissing.
  ///
  /// In en, this message translates to:
  /// **'Not filled in'**
  String get legendMissing;

  /// No description provided for @modeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed days'**
  String get modeFixed;

  /// No description provided for @modeQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get modeQuota;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get periodMonth;

  /// No description provided for @quotaValue.
  ///
  /// In en, this message translates to:
  /// **'Quota: {n}'**
  String quotaValue(int n);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langId.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get langId;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
