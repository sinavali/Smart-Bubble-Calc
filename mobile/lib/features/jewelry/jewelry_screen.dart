import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../core/persian_number.dart';
import '../../core/shamsi_date.dart';
import '../../core/theme.dart';
import '../../widgets/shamsi_date_picker.dart';
import '../../widgets/status_pill.dart';

// Swiss Minimalist Financial Terminal - Legal Iranian Jewelry Calculator
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran gold bazaar regulations (9% VAT strictly on Labor + Profit).

class JewelryScreen extends StatefulWidget {
  final MarketApiClient apiClient;

  const JewelryScreen({super.key, required this.apiClient});

  @override
  State<JewelryScreen> createState() => _JewelryScreenState();
}

class _JewelryScreenState extends State<JewelryScreen> {
  final _weightController = TextEditingController(text: '5.0');
  final _priceController = TextEditingController(text: '4500000');
  final _laborController = TextEditingController(text: '15.0');
  final _profitController = TextEditingController(text: '7.0');
  final _vatController = TextEditingController(text: '9.0');

  int _selectedCarat = 750;
  bool _isLaborPercentage = true;
  ShamsiDate _invoiceDate = ShamsiDate.now();
  JewelryCalculationResponse? _result;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _laborController.dispose();
    _profitController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveGoldPrice() async {
    try {
      final market = await widget.apiClient.fetchMarket();
      for (final a in market.assets) {
        if (a.id == 'gold_18k' && a.price > 0) {
          final adjusted = (a.price * (_selectedCarat / 750.0)).round();
          setState(() {
            _priceController.text = adjusted.toString();
          });
          _recalculate();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'نرخ ${_caratLabel(_selectedCarat)} از نبض بازار به روز رسانی شد',
                  textDirection: TextDirection.rtl,
                ),
                backgroundColor: TerminalTheme.cardDark,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          break;
        }
      }
    } catch (_) {}
  }

  void _onCaratChanged(int newCarat) {
    final currentPrice = double.tryParse(PersianNumber.toLatinDigits(_priceController.text)) ?? 4500000.0;
    final base18k = currentPrice / (_selectedCarat / 750.0);
    final adjusted = (base18k * (newCarat / 750.0)).round();
    setState(() {
      _selectedCarat = newCarat;
      _priceController.text = adjusted.toString();
    });
    _recalculate();
  }

  String _caratLabel(int carat) {
    switch (carat) {
      case 999:
        return '24 عیار (999 / شمش خالص)';
      case 875:
        return '21 عیار (875 / استاندارد یزدی)';
      case 740:
        return 'متفرقه (740)';
      case 750:
      default:
        return '18 عیار (750 / استاندارد بازار)';
    }
  }

  void _recalculate() {
    final weight = double.tryParse(PersianNumber.toLatinDigits(_weightController.text)) ?? 0.0;
    final price = double.tryParse(PersianNumber.toLatinDigits(_priceController.text)) ?? 0.0;
    final labor = double.tryParse(PersianNumber.toLatinDigits(_laborController.text)) ?? 0.0;
    final profit = double.tryParse(PersianNumber.toLatinDigits(_profitController.text)) ?? 7.0;
    final vat = double.tryParse(PersianNumber.toLatinDigits(_vatController.text)) ?? 9.0;

    if (weight <= 0 || price <= 0) return;

    final req = JewelryCalculationRequest(
      weightGram: weight,
      gram18kPrice: price,
      laborValue: labor,
      isLaborPercentage: _isLaborPercentage,
      profitPct: profit,
      vatPct: vat,
    );

    setState(() {
      _result = JewelryCalculationResponse.computeLocally(req);
    });
  }

  Future<void> _pickDate() async {
    final picked = await ShamsiDatePickerModal.show(
      context,
      initialDate: _invoiceDate,
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  void _copyReceiptToClipboard() {
    if (_result == null) return;
    final weight = _weightController.text;
    final price = _priceController.text;
    final dateStr = _invoiceDate.format(includeTime: false);

    final sb = StringBuffer();
    sb.writeln('صورتحساب خرید طلا - سامانه حباب سنج');
    sb.writeln('تاریخ: $dateStr');
    sb.writeln('عیار طلا: ${_caratLabel(_selectedCarat)}');
    sb.writeln('وزن طلا: $weight گرم');
    sb.writeln('نرخ هر گرم: ${PersianNumber.formatToman(double.tryParse(price) ?? 0)}');
    sb.writeln('قیمت طلای خام: ${PersianNumber.formatToman(_result!.rawGoldPrice)}');
    sb.writeln('اجرت ساخت: ${PersianNumber.formatToman(_result!.laborAmount)}');
    sb.writeln('سود طلافروش: ${PersianNumber.formatToman(_result!.profitAmount)}');
    sb.writeln('مالیات ارزش افزوده (9% اجرت و سود): ${PersianNumber.formatToman(_result!.vatAmount)}');
    sb.writeln('----------------------------------------');
    sb.writeln('مبلغ نهایی قابل پرداخت: ${PersianNumber.formatToman(_result!.totalPrice)}');
    sb.writeln('مبلغ به حروف: ${PersianNumber.numberToPersianWords(_result!.totalPrice.round())}');

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'صورتحساب در حافظه کپی شد',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: TerminalTheme.cardDark,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TerminalTheme.carbonBlack,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with Shamsi Date Picker Trigger
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TerminalTheme.slateDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: TerminalTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'محاسبه قانونی قیمت طلا',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TerminalTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'مالیات 9% صرفا روی اجرت و سود طبق قانون',
                          style: TextStyle(fontSize: 11, color: TerminalTheme.textMuted),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TerminalTheme.cardDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TerminalTheme.goldAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: TerminalTheme.goldAccent),
                            const SizedBox(width: 6),
                            Text(
                              PersianNumber.toPersianDigits(_invoiceDate.format(includeTime: false)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: TerminalTheme.goldAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TerminalTheme.cardDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: TerminalTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Weight Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              labelText: 'وزن طلا (گرم)',
                              suffixText: 'گرم',
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick weight chips
                        _buildWeightChip('2.5'),
                        const SizedBox(width: 6),
                        _buildWeightChip('5.0'),
                        const SizedBox(width: 6),
                        _buildWeightChip('10.0'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Carat Selector Row
                    Row(
                      children: [
                        const Text(
                          'عیار:',
                          style: TextStyle(fontSize: 12, color: TerminalTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        _buildCaratChip('18 عیار', 750),
                        const SizedBox(width: 6),
                        _buildCaratChip('24 عیار', 999),
                        const SizedBox(width: 6),
                        _buildCaratChip('21 عیار', 875),
                        const SizedBox(width: 6),
                        _buildCaratChip('740', 740),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Price per gram Input & Live Sync Button
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'قیمت هر گرم طلا (تومان)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.sync, color: TerminalTheme.goldAccent),
                          tooltip: 'دریافت از نبض بازار',
                          onPressed: _fetchLiveGoldPrice,
                        ),
                      ),
                      onChanged: (_) => _recalculate(),
                    ),
                    const SizedBox(height: 14),

                    // Labor Value & Mode Selector
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _laborController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              labelText: _isLaborPercentage
                                  ? 'اجرت ساخت (درصد)'
                                  : 'اجرت ساخت (تومان بر گرم)',
                              suffixText: _isLaborPercentage ? '%' : 'تومان',
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Toggle Button Percentage vs Fixed
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isLaborPercentage = !_isLaborPercentage;
                              _laborController.text = _isLaborPercentage ? '15.0' : '400000';
                            });
                            _recalculate();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: TerminalTheme.cardLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: TerminalTheme.borderColor),
                            ),
                            child: Text(
                              _isLaborPercentage ? 'نوع: درصدی' : 'نوع: مبلغی',
                              style: const TextStyle(
                                fontSize: 12,
                                color: TerminalTheme.goldAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Profit and VAT row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _profitController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              labelText: 'سود طلافروش (%)',
                              suffixText: '%',
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _vatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              labelText: 'مالیات بر ارزش افزوده (%)',
                              suffixText: '%',
                            ),
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Breakdown Card
              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TerminalTheme.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: TerminalTheme.goldAccent.withOpacity(0.6), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Receipt Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.receipt_long, color: TerminalTheme.goldAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'ریز صورتحساب قانونی طلا',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TerminalTheme.goldAccent,
                                ),
                              ),
                            ],
                          ),
                          StatusPill(
                            label: PersianNumber.toPersianDigits(_invoiceDate.toNumericString()),
                            color: TerminalTheme.textSecondary,
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: TerminalTheme.borderColor, height: 1),
                      const SizedBox(height: 12),

                      // Breakdown Items
                      _buildReceiptRow('قیمت طلای خام (بدون مالیات):', _result!.rawGoldPrice),
                      _buildReceiptRow('اجرت ساخت:', _result!.laborAmount),
                      _buildReceiptRow('سود طلافروش:', _result!.profitAmount),
                      _buildReceiptRow(
                        'مالیات ارزش افزوده (9% اجرت و سود):',
                        _result!.vatAmount,
                        highlightColor: TerminalTheme.signalAmber,
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: TerminalTheme.goldAccent, height: 1.5),
                      const SizedBox(height: 12),

                      // Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'مبلغ کل پرداختی:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: TerminalTheme.textPrimary,
                            ),
                          ),
                          Text(
                            PersianNumber.formatToman(_result!.totalPrice),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: TerminalTheme.goldBright,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // In Words Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: TerminalTheme.cardLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: TerminalTheme.borderColor),
                        ),
                        child: Text(
                          'به حروف: ${PersianNumber.numberToPersianWords(_result!.totalPrice.round())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TerminalTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Copy Receipt Action
                      OutlinedButton.icon(
                        onPressed: _copyReceiptToClipboard,
                        icon: const Icon(Icons.copy, size: 16, color: TerminalTheme.goldAccent),
                        label: const Text(
                          'کپی صورتحساب برای مشتری',
                          style: TextStyle(color: TerminalTheme.goldAccent, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: TerminalTheme.goldAccent),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCaratChip(String label, int carat) {
    final isSelected = _selectedCarat == carat;
    return InkWell(
      onTap: () => _onCaratChanged(carat),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TerminalTheme.goldAccent : TerminalTheme.cardLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? TerminalTheme.goldBright : TerminalTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? TerminalTheme.carbonBlack : TerminalTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChip(String weight) {
    return InkWell(
      onTap: () {
        setState(() => _weightController.text = weight);
        _recalculate();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: TerminalTheme.cardLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TerminalTheme.borderColor),
        ),
        child: Text(
          '${PersianNumber.toPersianDigits(weight)}g',
          style: const TextStyle(fontSize: 12, color: TerminalTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String title, double amount, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: highlightColor ?? TerminalTheme.textSecondary,
            ),
          ),
          Text(
            PersianNumber.formatToman(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? TerminalTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
