import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../core/persian_number.dart';
import '../../core/shamsi_date.dart';
import '../../core/theme.dart';
import '../../widgets/shamsi_date_picker.dart';

// Swiss Minimalist Financial Terminal - Settings & Tehran Converter Screen
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran timezone & legal documentation.

class SettingsScreen extends StatefulWidget {
  final MarketApiClient apiClient;

  const SettingsScreen({super.key, required this.apiClient});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  ShamsiDate _shamsiDate = ShamsiDate.now();
  String _gregorianEquivalent = '';
  String _cacheStatus = 'در حال بررسی...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _updateGregorianEquivalent();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(MarketApiClient.prefKeyBaseUrl) ?? MarketApiClient.defaultBaseUrl;
    final cached = prefs.getString(MarketApiClient.cacheKeyMarket);
    setState(() {
      _urlController.text = url;
      _cacheStatus = cached != null ? 'اطلاعات در حافظه کش محلی موجود است' : 'حافظه کش خالی است';
    });
  }

  void _updateGregorianEquivalent() {
    final dt = _shamsiDate.toDateTime();
    setState(() {
      _gregorianEquivalent = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickDate() async {
    final picked = await ShamsiDatePickerModal.show(
      context,
      initialDate: _shamsiDate,
    );
    if (picked != null) {
      setState(() {
        _shamsiDate = picked;
        _updateGregorianEquivalent();
      });
    }
  }

  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MarketApiClient.prefKeyBaseUrl, _urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('آدرس سرور ذخیره شد', textDirection: TextDirection.rtl),
          backgroundColor: TerminalTheme.cardDark,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(MarketApiClient.cacheKeyMarket);
    await prefs.remove(MarketApiClient.cacheKeyEtag);
    setState(() {
      _cacheStatus = 'حافظه کش با موفقیت پاک شد';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حافظه کش پاک شد', textDirection: TextDirection.rtl),
          backgroundColor: TerminalTheme.cardDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TerminalTheme.carbonBlack,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Converter Section
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
                    const Row(
                      children: [
                        Icon(Icons.transform, color: TerminalTheme.goldAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'مبدل تاریخ شمسی به میلادی (ساعت رسمی تهران)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TerminalTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Shamsi date selector button
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: TerminalTheme.cardLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TerminalTheme.goldAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تاریخ شمسی: ${PersianNumber.toPersianDigits(_shamsiDate.format(includeTime: false))}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: TerminalTheme.goldAccent,
                              ),
                            ),
                            const Icon(Icons.calendar_month, color: TerminalTheme.goldAccent, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gregorian Equivalent Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: TerminalTheme.slateDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: TerminalTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'معادل میلادی (Gregorian):',
                            style: TextStyle(fontSize: 12, color: TerminalTheme.textMuted),
                          ),
                          Text(
                            _gregorianEquivalent,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: TerminalTheme.textPrimary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Server Configuration Section
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
                    const Row(
                      children: [
                        Icon(Icons.dns, color: TerminalTheme.goldAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'تنظیمات ارتباط با سرور نبض بازار',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TerminalTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _urlController,
                      style: const TextStyle(
                        color: TerminalTheme.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'آدرس پایه سرور (API Base URL)',
                        hintText: 'http://127.0.0.1:8080',
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: _saveUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TerminalTheme.goldAccent,
                        foregroundColor: TerminalTheme.carbonBlack,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('ذخیره آدرس سرور', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Offline Cache Management
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
                    const Row(
                      children: [
                        Icon(Icons.storage, color: TerminalTheme.goldAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'مدیریت حافظه کش آفلاین',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TerminalTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _cacheStatus,
                      style: const TextStyle(fontSize: 12, color: TerminalTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _clearCache,
                      icon: const Icon(Icons.delete_outline, size: 16, color: TerminalTheme.signalCoral),
                      label: const Text(
                        'پاکسازی حافظه کش',
                        style: TextStyle(color: TerminalTheme.signalCoral, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TerminalTheme.signalCoral),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Legal Tax Reference Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TerminalTheme.slateDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: TerminalTheme.borderColor),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: TerminalTheme.goldAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'مستندات قانونی مالیات طلا در ایران',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: TerminalTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'بر اساس ماده ۲۶ قانون مالیات بر ارزش افزوده مصوب سال ۱۴۰۰، اصل طلا، جواهر و پلاتین به کار رفته در مصنوعات ساخته شده از پرداخت مالیات و عوارض معاف است. مالیات بر ارزش افزوده صرفا با نرخ ۹ درصد به اجرت ساخت، حق العمل و سود فروشنده تعلق می گیرد و دریافت مالیات بر اصل طلا تخلف قانونی است.',
                      style: TextStyle(
                        fontSize: 11,
                        color: TerminalTheme.textMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
