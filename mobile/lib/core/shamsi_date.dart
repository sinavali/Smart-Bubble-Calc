// Swiss Minimalist Financial Terminal - Shamsi (Jalali) Calendar Math
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran timezone, natural Tehran Persian phrasing.

class ShamsiDate {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;

  const ShamsiDate({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
  });

  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> weekdayNames = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  String get monthName => monthNames[month - 1];

  String get weekdayName {
    final dt = toDateTime();
    // In DateTime: 1 is Monday, 7 is Sunday.
    // In Iranian week: 0 is Saturday (شنبه), 6 is Friday (جمعه).
    final int idx = (dt.weekday + 1) % 7;
    return weekdayNames[idx];
  }

  /// Formatted Shamsi date string, e.g. "27 مهر 1405 - ساعت 02:55"
  String format({bool includeTime = true}) {
    final base = '$day $monthName $year';
    if (!includeTime) return base;
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$base - ساعت $h:$m';
  }

  /// Formatted numerical Shamsi string, e.g. "1405/07/27"
  String toNumericString() {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year/$m/$d';
  }

  /// Current Shamsi date in Tehran timezone (+3:30 offset)
  static ShamsiDate now() {
    final utc = DateTime.now().toUtc();
    final tehranTime = utc.add(const Duration(hours: 3, minutes: 30));
    return fromDateTime(tehranTime);
  }

  /// Converts a Gregorian DateTime to ShamsiDate
  static ShamsiDate fromDateTime(DateTime dt) {
    final parts = gregorianToShamsi(dt.year, dt.month, dt.day);
    return ShamsiDate(
      year: parts[0],
      month: parts[1],
      day: parts[2],
      hour: dt.hour,
      minute: dt.minute,
      second: dt.second,
    );
  }

  /// Converts this ShamsiDate to a Gregorian DateTime
  DateTime toDateTime() {
    final parts = shamsiToGregorian(year, month, day);
    return DateTime(parts[0], parts[1], parts[2], hour, minute, second);
  }

  /// True if given Shamsi year is a leap year (366 days)
  static bool isLeapYear(int jy) {
    final gyParts = shamsiToGregorian(jy, 1, 1);
    final nextGyParts = shamsiToGregorian(jy + 1, 1, 1);
    final d1 = DateTime.utc(gyParts[0], gyParts[1], gyParts[2]);
    final d2 = DateTime.utc(nextGyParts[0], nextGyParts[1], nextGyParts[2]);
    return d2.difference(d1).inDays == 366;
  }

  /// Days in a given Shamsi month
  static int daysInMonth(int jy, int jm) {
    if (jm <= 6) return 31;
    if (jm <= 11) return 30;
    return isLeapYear(jy) ? 30 : 29;
  }

  /// Adds days to this ShamsiDate
  ShamsiDate addDays(int days) {
    final dt = toDateTime().add(Duration(days: days));
    return fromDateTime(dt);
  }

  ShamsiDate copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) {
    return ShamsiDate(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      second: second ?? this.second,
    );
  }

  /// Pure Gregorian to Shamsi algorithm
  static List<int> gregorianToShamsi(int gy, int gm, int gd) {
    const gDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const jDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

    final gy2 = gy - 1600;
    final gm2 = gm - 1;
    final gd2 = gd - 1;

    int gDayNo = 365 * gy2 + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400);

    for (int i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }
    if (gm2 > 1 && ((gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0))) {
      gDayNo++;
    }
    gDayNo += gd2;

    int jDayNo = gDayNo - 79;
    final jNp = jDayNo ~/ 12053;
    jDayNo %= 12053;

    int jy = 979 + 33 * jNp + 4 * (jDayNo ~/ 1461);
    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy += (jDayNo - 1) ~/ 365;
      jDayNo = (jDayNo - 1) % 365;
    }

    int jm = 0;
    for (int i = 0; i < 11 && jDayNo >= jDaysInMonth[i]; i++) {
      jDayNo -= jDaysInMonth[i];
      jm = i + 1;
    }
    jm++;
    final jd = jDayNo + 1;
    return [jy, jm, jd];
  }

  /// Pure Shamsi to Gregorian algorithm
  static List<int> shamsiToGregorian(int jy, int jm, int jd) {
    const gDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const jDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

    final jy2 = jy - 979;
    final jm2 = jm - 1;
    final jd2 = jd - 1;

    int jDayNo = 365 * jy2 + (jy2 ~/ 33) * 8 + (((jy2 % 33) + 3) ~/ 4);
    for (int i = 0; i < jm2; i++) {
      jDayNo += jDaysInMonth[i];
    }
    jDayNo += jd2;

    int gDayNo = jDayNo + 79;

    int gy = 1600 + 400 * (gDayNo ~/ 146097);
    gDayNo %= 146097;

    bool leap = true;
    if (gDayNo >= 36525) {
      gDayNo--;
      gy += 100 * (gDayNo ~/ 36524);
      gDayNo %= 36524;

      if (gDayNo >= 365) {
        gDayNo++;
      } else {
        leap = false;
      }
    }

    gy += 4 * (gDayNo ~/ 1461);
    gDayNo %= 1461;

    if (gDayNo >= 366) {
      leap = false;
      gDayNo--;
      gy += gDayNo ~/ 365;
      gDayNo %= 365;
    }

    int gm = 0;
    for (int i = 0; gDayNo >= gDaysInMonth[i] + ((i == 1 && leap) ? 1 : 0); i++) {
      gDayNo -= gDaysInMonth[i] + ((i == 1 && leap) ? 1 : 0);
      gm = i + 1;
    }
    gm++;
    final gd = gDayNo + 1;
    return [gy, gm, gd];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShamsiDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          hour == other.hour &&
          minute == other.minute &&
          second == other.second;

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      day.hashCode ^
      hour.hashCode ^
      minute.hashCode ^
      second.hashCode;

  @override
  String toString() => format();
}
