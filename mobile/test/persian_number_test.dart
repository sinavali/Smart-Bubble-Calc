import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bubble_calc_mobile/core/persian_number.dart';

void main() {
  group('PersianNumber Formatting and Conversion', () {
    test('Converts Latin digits to Persian digits', () {
      expect(PersianNumber.toPersianDigits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
      expect(PersianNumber.toPersianDigits(1405), '۱۴۰۵');
    });

    test('Converts Persian digits to Latin digits', () {
      expect(PersianNumber.toLatinDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('Formats currency in Toman with Persian comma separator (،)', () {
      final formatted = PersianNumber.formatToman(28153013);
      expect(formatted, '۲۸،۱۵۳،۰۱۳ تومان');
    });

    test('Formats percentages with sign and decimals', () {
      expect(PersianNumber.formatPercent(18.77), '+۱۸.۷۷%');
      expect(PersianNumber.formatPercent(-3.5), '-۳.۵۰%');
    });

    test('Converts numbers to Persian words (حروف) correctly', () {
      expect(PersianNumber.numberToPersianWords(0), 'صفر تومان');
      expect(PersianNumber.numberToPersianWords(1), 'یک تومان');
      expect(PersianNumber.numberToPersianWords(100), 'یکصد تومان');
      expect(PersianNumber.numberToPersianWords(1000), 'یک هزار تومان');
      expect(PersianNumber.numberToPersianWords(1000000), 'یک میلیون تومان');
      expect(
        PersianNumber.numberToPersianWords(28153013),
        'بیست و هشت میلیون و یکصد و پنجاه و سه هزار و سیزده تومان',
      );
    });
  });
}
