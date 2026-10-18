import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bubble_calc_mobile/core/shamsi_date.dart';

void main() {
  group('ShamsiDate Conversions', () {
    test('Converts benchmark 2026-10-19 to 1405-07-27 (27 Mehr 1405)', () {
      final dt = DateTime.utc(2026, 10, 19);
      final shamsi = ShamsiDate.fromDateTime(dt);

      expect(shamsi.year, 1405);
      expect(shamsi.month, 7);
      expect(shamsi.day, 27);
      expect(shamsi.monthName, 'مهر');
    });

    test('Converts Nowruz 2024-03-20 to 1403-01-01', () {
      final dt = DateTime.utc(2024, 3, 20);
      final shamsi = ShamsiDate.fromDateTime(dt);

      expect(shamsi.year, 1403);
      expect(shamsi.month, 1);
      expect(shamsi.day, 1);
      expect(shamsi.monthName, 'فروردین');
    });

    test('Round-trip Gregorian <-> Shamsi preserves dates', () {
      final original = DateTime.utc(2026, 10, 19, 14, 30, 0);
      final shamsi = ShamsiDate.fromDateTime(original);
      final back = shamsi.toDateTime();

      expect(back.year, original.year);
      expect(back.month, original.month);
      expect(back.day, original.day);
    });

    test('Identifies leap years correctly', () {
      // 1403 was a Jalali leap year (366 days)
      expect(ShamsiDate.isLeapYear(1403), isTrue);
      expect(ShamsiDate.daysInMonth(1403, 12), 30);

      // 1404 is a regular year (365 days)
      expect(ShamsiDate.isLeapYear(1404), isFalse);
      expect(ShamsiDate.daysInMonth(1404, 12), 29);
    });

    test('Days in first 6 months is always 31', () {
      for (int m = 1; m <= 6; m++) {
        expect(ShamsiDate.daysInMonth(1405, m), 31);
      }
    });

    test('Days in months 7 to 11 is always 30', () {
      for (int m = 7; m <= 11; m++) {
        expect(ShamsiDate.daysInMonth(1405, m), 30);
      }
    });
  });
}
