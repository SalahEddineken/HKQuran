class HijriDate {
  final int day;
  final int month;
  final int year;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  static const List<String> _monthsEn = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const List<String> _monthsAr = [
    'المحرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get monthNameEn =>
      (month >= 1 && month <= 12) ? _monthsEn[month - 1] : '';

  String get monthNameAr =>
      (month >= 1 && month <= 12) ? _monthsAr[month - 1] : '';

  String format(bool ar) {
    if (ar) {
      return '$day $monthNameAr $year هـ';
    }
    return '$day $monthNameEn $year AH';
  }

  /// Kuweit / Julian Day astronomical conversion algorithm.
  factory HijriDate.fromGregorian(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    final jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;

    final z = jd - 1948439.5;
    final cyc = (z / 10631).floor();
    final rem = z - cyc * 10631;

    final j = ((rem + 0.5) / 354.36667).floor();
    final hYear = cyc * 30 + j + 1;

    final daysInYear = (rem - j * 354.36667).round();
    var hMonth = ((daysInYear + 1) / 29.5).ceil().clamp(1, 12);

    var hDay = (daysInYear - ((hMonth - 1) * 29.5).floor()).round().clamp(1, 30);

    return HijriDate(day: hDay, month: hMonth, year: hYear);
  }
}
