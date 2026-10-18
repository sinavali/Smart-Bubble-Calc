import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bubble_calc_mobile/core/api_client.dart';

void main() {
  group('Legal Iranian Jewelry Tax Calculations', () {
    test('Calculates 18k jewelry strictly complying with 9% VAT on labor+profit only', () {
      const req = JewelryCalculationRequest(
        weightGram: 5.0,
        gram18kPrice: 4500000.0,
        laborValue: 15.0, // 15%
        isLaborPercentage: true,
        profitPct: 7.0, // 7%
        vatPct: 9.0, // 9%
      );

      final res = JewelryCalculationResponse.computeLocally(req);

      // Raw gold = 5 * 4,500,000 = 22,500,000
      expect(res.rawGoldPrice, 22500000.0);

      // Labor = 22,500,000 * 0.15 = 3,375,000
      expect(res.laborAmount, 3375000.0);

      // Profit = (22,500,000 + 3,375,000) * 0.07 = 1,811,250
      expect(res.profitAmount, 1811250.0);

      // VAT = (3,375,000 + 1,811,250) * 0.09 = 466,762.5 -> 466,763
      expect(res.vatAmount, 466763.0);

      // Total = 22,500,000 + 3,375,000 + 1,811,250 + 466,763 = 28,153,013
      expect(res.totalPrice, 28153013.0);
    });

    test('Calculates fixed Toman per gram labor correctly', () {
      const req = JewelryCalculationRequest(
        weightGram: 10.0,
        gram18kPrice: 4000000.0,
        laborValue: 300000.0, // 300,000 Toman per gram
        isLaborPercentage: false,
        profitPct: 7.0,
        vatPct: 9.0,
      );

      final res = JewelryCalculationResponse.computeLocally(req);

      // Raw gold = 10 * 4,000,000 = 40,000,000
      expect(res.rawGoldPrice, 40000000.0);

      // Labor = 10 * 300,000 = 3,000,000
      expect(res.laborAmount, 3000000.0);

      // Profit = 43,000,000 * 0.07 = 3,010,000
      expect(res.profitAmount, 3010000.0);

      // VAT = (3,000,000 + 3,010,000) * 0.09 = 540,900
      expect(res.vatAmount, 540900.0);

      // Total = 40,000,000 + 3,000,000 + 3,010,000 + 540,900 = 46,550,900
      expect(res.totalPrice, 46550900.0);
    });
  });
}
