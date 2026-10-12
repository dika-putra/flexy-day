// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Flexy Day';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabSettings => 'Pengaturan';

  @override
  String get question => 'Ngantor hari ini?';

  @override
  String get answerOffice => 'Ngantor';

  @override
  String get answerMove => 'Pindah hari';

  @override
  String get answerLeave => 'Libur';

  @override
  String get answerSick => 'Sakit';

  @override
  String get moveTo => 'Pindah ke tanggal';

  @override
  String get noteHint => 'Catatan (opsional)';

  @override
  String get save => 'Simpan';

  @override
  String get notAnswered => 'Belum dijawab';

  @override
  String get changeAnswer => 'Ubah jawaban';

  @override
  String get notOfficeDay => 'Hari ini bukan jadwal ke kantor.';

  @override
  String get statusOffice => 'Udah ngantor';

  @override
  String get statusLeave => 'Libur hari ini';

  @override
  String get statusSick => 'Lagi sakit';

  @override
  String statusMoved(String date) {
    return 'Dipindah ke $date';
  }

  @override
  String unfilledBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari belum diisi',
    );
    return '$_temp0';
  }

  @override
  String nextOffice(String date) {
    return 'Jadwal ke kantor berikutnya: $date';
  }

  @override
  String get noUpcoming => 'Belum ada jadwal ke kantor dalam 60 hari ke depan.';

  @override
  String get quotaWeek => 'Kuota minggu ini';

  @override
  String get quotaMonth => 'Kuota bulan ini';

  @override
  String quotaProgress(int done, int total) {
    return '$done dari $total';
  }

  @override
  String get quotaGreen => 'Aman';

  @override
  String get quotaYellow => 'Segera penuhi';

  @override
  String get quotaRed => 'Kuota tidak akan terpenuhi';

  @override
  String quotaStats(int done, int need, int available) {
    return 'Hadir $done, kurang $need, tersedia $available hari';
  }

  @override
  String get attendance => 'Kehadiran';

  @override
  String get statOffice => 'Hadir';

  @override
  String get statLeave => 'Libur';

  @override
  String get statSick => 'Sakit';

  @override
  String get legendMissing => 'Belum diisi';

  @override
  String get modeFixed => 'Hari tetap';

  @override
  String get modeQuota => 'Kuota';

  @override
  String get periodWeek => 'Per minggu';

  @override
  String get periodMonth => 'Per bulan';

  @override
  String quotaValue(int n) {
    return 'Kuota: $n';
  }

  @override
  String get language => 'Bahasa';

  @override
  String get langSystem => 'Ikuti sistem';

  @override
  String get langId => 'Bahasa Indonesia';

  @override
  String get langEn => 'English';
}
