// Swiss Minimalist Financial Terminal - Persian Number Formatting and Words
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran dialect, comma separator (،) and natural Persian numerals.

class PersianNumber {
  static const Map<String, String> _englishToPersian = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };

  static const Map<String, String> _persianToEnglish = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  /// Converts any Latin digits in string to Persian digits (۰-۹)
  static String toPersianDigits(dynamic input) {
    if (input == null) return '';
    final str = input.toString();
    final sb = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      sb.write(_englishToPersian[char] ?? char);
    }
    return sb.toString();
  }

  /// Converts Persian digits to Latin digits
  static String toLatinDigits(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      sb.write(_persianToEnglish[char] ?? char);
    }
    return sb.toString();
  }

  /// Formats currency amounts in Toman with Persian comma separator (،)
  static String formatToman(num amount, {bool showUnit = true, bool persianDigits = true}) {
    final rounded = amount.round();
    final isNegative = rounded < 0;
    final absStr = rounded.abs().toString();

    final buffer = StringBuffer();
    int count = 0;
    for (int i = absStr.length - 1; i >= 0; i--) {
      buffer.write(absStr[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    String result = buffer.toString().split('').reversed.join('');
    if (isNegative) {
      result = '-$result';
    }

    if (persianDigits) {
      result = toPersianDigits(result).replaceAll(',', '،');
    }

    if (showUnit) {
      return '$result تومان';
    }
    return result;
  }

  /// Formats percentage with sign and Persian numerals, e.g. "+۱۸.۷۷%"
  static String formatPercent(double percent, {bool persianDigits = true, int decimals = 2}) {
    final sign = percent > 0 ? '+' : '';
    final formatted = '$sign${percent.toStringAsFixed(decimals)}%';
    return persianDigits ? toPersianDigits(formatted) : formatted;
  }

  /// Formats weight in grams, e.g. "۵.۲۵ گرم"
  static String formatWeight(double grams, {bool persianDigits = true}) {
    final str = grams.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    final val = persianDigits ? toPersianDigits(str) : str;
    return '$val گرم';
  }

  // Persian Number Words Data (Strictly ZERO half-space)
  static const List<String> _ones = [
    '',
    'یک',
    'دو',
    'سه',
    'چهار',
    'پنج',
    'شش',
    'هفت',
    'هشت',
    'نه',
    'ده',
    'یازده',
    'دوازده',
    'سیزده',
    'چهارده',
    'پانزده',
    'شانزده',
    'هفده',
    'هجده',
    'نوزده',
  ];

  static const List<String> _tens = [
    '',
    '',
    'بیست',
    'سی',
    'چهل',
    'پنجاه',
    'شصت',
    'هفتاد',
    'هشتاد',
    'نود',
  ];

  static const List<String> _hundreds = [
    '',
    'یکصد',
    'دویست',
    'سیصد',
    'چهارصد',
    'پانصد',
    'ششصد',
    'هفتصد',
    'هشتصد',
    'نهصد',
  ];

  static const List<String> _scales = [
    '',
    'هزار',
    'میلیون',
    'میلیارد',
    'تریلیون',
  ];

  /// Converts integer amount (e.g. 28153013) to Persian words (حروف) for invoices
  /// Example: "بیست و هشت میلیون و یکصد و پنجاه و سه هزار و سیزده تومان"
  static String numberToPersianWords(int number, {bool appendToman = true}) {
    if (number == 0) {
      return appendToman ? 'صفر تومان' : 'صفر';
    }

    final isNegative = number < 0;
    int n = number.abs();

    final List<String> groups = [];
    int scaleIndex = 0;

    while (n > 0) {
      final rem = n % 1000;
      if (rem > 0) {
        final groupWords = _threeDigitsToWords(rem);
        if (scaleIndex > 0) {
          groups.add('$groupWords ${_scales[scaleIndex]}');
        } else {
          groups.add(groupWords);
        }
      }
      n ~/= 1000;
      scaleIndex++;
    }

    final reversedGroups = groups.reversed.toList();
    var result = reversedGroups.join(' و ');

    if (isNegative) {
      result = 'منفی $result';
    }

    if (appendToman) {
      result = '$result تومان';
    }

    return result;
  }

  static String _threeDigitsToWords(int num) {
    final h = num ~/ 100;
    final rem = num % 100;
    final parts = <String>[];

    if (h > 0) {
      parts.add(_hundreds[h]);
    }

    if (rem > 0) {
      if (rem < 20) {
        parts.add(_ones[rem]);
      } else {
        final t = rem ~/ 10;
        final o = rem % 10;
        parts.add(_tens[t]);
        if (o > 0) {
          parts.add(_ones[o]);
        }
      }
    }

    return parts.join(' و ');
  }
}
