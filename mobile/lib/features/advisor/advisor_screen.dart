import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/persian_number.dart';
import '../../core/shamsi_date.dart';
import '../../core/theme.dart';
import '../../widgets/status_pill.dart';

// Swiss Minimalist Financial Terminal - DCA Bubble Evaluator & Allocation Advisor
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran gold & coin market investment principles.

class AdvisorScreen extends StatefulWidget {
  final MarketApiClient apiClient;

  const AdvisorScreen({super.key, required this.apiClient});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _capitalController = TextEditingController(text: '100000000'); // 100M Toman
  final Set<int> _completedSteps = {};
  String _timeHorizon = 'medium'; // short, medium, long
  MarketResponse? _market;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _capitalController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiClient.fetchMarket();
      if (mounted) {
        setState(() {
          _market = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _emamiBubblePct {
    if (_market == null) return 18.77;
    for (final a in _market!.assets) {
      if (a.id == 'coin_emami') return a.bubblePct;
    }
    return 18.77;
  }

  double get _quarterBubblePct {
    if (_market == null) return 64.71;
    for (final a in _market!.assets) {
      if (a.id == 'coin_quarter') return a.bubblePct;
    }
    return 64.71;
  }

  String _getMarketVerdict() {
    final b = _emamiBubblePct;
    if (b < 8.0) {
      return 'منطقه طلایی ورود: حباب سکه در کمترین سطح قرار دارد.';
    } else if (b < 16.0) {
      return 'منطقه خرید پله ای: حباب در محدوده متعادل میانگین است.';
    } else if (b < 25.0) {
      return 'احتیاط در خرید سکه: حباب بالاست؛ اولویت با طلای 18 عیار بدون حباب است.';
    } else {
      return 'هشدار حباب شدید: از خرید سکه های کوچک خودداری کرده و طلای آبشده را ترجیح دهید.';
    }
  }

  Color _getVerdictColor() {
    final b = _emamiBubblePct;
    if (b < 8.0) return TerminalTheme.signalEmerald;
    if (b < 16.0) return TerminalTheme.signalAmber;
    return TerminalTheme.signalCoral;
  }

  @override
  Widget build(BuildContext context) {
    final capital = double.tryParse(PersianNumber.toLatinDigits(_capitalController.text)) ?? 0.0;

    // Calculate allocation based on bubble & time horizon
    // If bubble is high, shift heavily towards gold 18k (zero bubble) and cash/Tether
    double gold18kRatio = 0.50;
    double coinRatio = 0.25;
    double cashRatio = 0.25;

    if (_emamiBubblePct > 20.0) {
      gold18kRatio = 0.65;
      coinRatio = 0.10;
      cashRatio = 0.25;
    } else if (_emamiBubblePct < 10.0) {
      gold18kRatio = 0.35;
      coinRatio = 0.50;
      cashRatio = 0.15;
    }

    if (_timeHorizon == 'long') {
      gold18kRatio += 0.05;
      cashRatio -= 0.05;
    }

    final goldToman = capital * gold18kRatio;
    final coinToman = capital * coinRatio;
    final cashToman = capital * cashRatio;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TerminalTheme.carbonBlack,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: TerminalTheme.goldAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Market Verdict Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TerminalTheme.slateDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getVerdictColor().withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.insights, color: _getVerdictColor(), size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'تحلیل هوشمند نبض حباب',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: TerminalTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              StatusPill(
                                label: 'حباب امامی: ${PersianNumber.formatPercent(_emamiBubblePct)}',
                                color: _getVerdictColor(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getMarketVerdict(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getVerdictColor(),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'حباب ربع سکه در حال حاضر ${PersianNumber.formatPercent(_quarterBubblePct)} است که برای خرید مصرفی نامناسب و دارای ریسک تخلیه حباب است.',
                            style: const TextStyle(fontSize: 11, color: TerminalTheme.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Capital Input & Strategy Selection
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
                          const Text(
                            'سرمایه پیشنهادی برای تخصیص پله ای (DCA)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: TerminalTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _capitalController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'مبلغ کل سرمایه (تومان)',
                              suffixText: 'تومان',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),

                          if (capital > 0)
                            Text(
                              'معادل: ${PersianNumber.numberToPersianWords(capital.round())}',
                              style: const TextStyle(fontSize: 11, color: TerminalTheme.goldAccent),
                            ),
                          const SizedBox(height: 14),

                          // Time Horizon Selector
                          const Text(
                            'افق زمانی سرمایه گذاری:',
                            style: TextStyle(fontSize: 12, color: TerminalTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildHorizonChip('کوتاه مدت (1 تا 3 ماه)', 'short'),
                              const SizedBox(width: 8),
                              _buildHorizonChip('میان مدت (6 ماه)', 'medium'),
                              const SizedBox(width: 8),
                              _buildHorizonChip('بلند مدت (1 سال+)', 'long'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Portfolio Allocation Recommendation
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
                              Icon(Icons.pie_chart, color: TerminalTheme.goldAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'پیشنهاد سبد بهینه (مدل بدون حباب)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TerminalTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Visual Split Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 14,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: (gold18kRatio * 100).round(),
                                    child: Container(color: TerminalTheme.goldAccent),
                                  ),
                                  Expanded(
                                    flex: (coinRatio * 100).round(),
                                    child: Container(color: TerminalTheme.signalAmber),
                                  ),
                                  Expanded(
                                    flex: (cashRatio * 100).round(),
                                    child: Container(color: TerminalTheme.signalBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Breakdown rows
                          _buildAllocationRow(
                            'طلای 18 عیار یا آبشده (بدون حباب)',
                            (gold18kRatio * 100).round(),
                            goldToman,
                            TerminalTheme.goldAccent,
                            'مناسب ترین گزینه حفظ ارزش در شرایط حباب بالا',
                          ),
                          const SizedBox(height: 12),
                          _buildAllocationRow(
                            'سکه تمام (بهار آزادی)',
                            (coinRatio * 100).round(),
                            coinToman,
                            TerminalTheme.signalAmber,
                            'حباب کمتر نسبت به سکه های گرمی و ربع',
                          ),
                          const SizedBox(height: 12),
                          _buildAllocationRow(
                            'نقدینگی در گردش / تتر',
                            (cashRatio * 100).round(),
                            cashToman,
                            TerminalTheme.signalBlue,
                            'رزرو برای خرید در پله های اصلاح قیمت و افت حباب',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDcaScheduleSection(capital),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHorizonChip(String label, String value) {
    final isSelected = _timeHorizon == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _timeHorizon = value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? TerminalTheme.goldAccent : TerminalTheme.cardLight,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? TerminalTheme.goldBright : TerminalTheme.borderColor,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? TerminalTheme.carbonBlack : TerminalTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationRow(
    String title,
    int percent,
    double toman,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TerminalTheme.cardLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TerminalTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: TerminalTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${PersianNumber.toPersianDigits(percent.toString())}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                description,
                style: const TextStyle(fontSize: 10, color: TerminalTheme.textMuted),
              ),
              Text(
                PersianNumber.formatToman(toman),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: TerminalTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDcaScheduleSection(double capital) {
    if (capital <= 0) return const SizedBox.shrink();

    final now = ShamsiDate.now();
    final stepAmount = capital / 4.0;
    final progress = _completedSteps.length / 4.0;

    final steps = [
      {
        'title': 'پله اول (ورود اولیه)',
        'date': now,
        'action': 'خرید طلای 18 عیار بدون حباب یا آبشده',
        'rationale': 'ایجاد پایه امن سبد دارایی بدون ریسک حباب سکه',
      },
      {
        'title': 'پله دوم (2 هفته بعد)',
        'date': now.addDays(14),
        'action': 'بررسی نسبت حباب سکه بهار آزادی و خرید پله ای',
        'rationale': 'ورود به سکه در صورت آرامش بازار یا ادامه خرید طلای 18 عیار',
      },
      {
        'title': 'پله سوم (1 ماه بعد)',
        'date': now.addDays(30),
        'action': 'تکمیل میانگین وزنی خرید در اصلاح های قیمتی',
        'rationale': 'استفاده از نوسانات ماهانه بازار برای کاهش قیمت تمام شده',
      },
      {
        'title': 'پله چهارم (2 ماه بعد)',
        'date': now.addDays(60),
        'action': 'تثبیت سبد سرمایه گذاری و نگهداری نقدینگی رزرو',
        'rationale': 'تکمیل فرایند خرید پله ای با حداقل استرس روانی',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TerminalTheme.cardDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TerminalTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today, color: TerminalTheme.goldAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'جدول زمانبندی هوشمند خرید پله ای',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TerminalTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusPill(
                label: 'پیشرفت: ${PersianNumber.toPersianDigits((progress * 100).round().toString())}%',
                color: progress == 1.0 ? TerminalTheme.signalEmerald : TerminalTheme.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: TerminalTheme.cardLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? TerminalTheme.signalEmerald : TerminalTheme.goldAccent,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final stepDate = step['date'] as ShamsiDate;
            final isCompleted = _completedSteps.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? TerminalTheme.signalEmerald.withOpacity(0.08)
                    : TerminalTheme.cardLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCompleted
                      ? TerminalTheme.signalEmerald.withOpacity(0.4)
                      : TerminalTheme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isCompleted) {
                                  _completedSteps.remove(index);
                                } else {
                                  _completedSteps.add(index);
                                }
                              });
                            },
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isCompleted
                                  ? TerminalTheme.signalEmerald
                                  : TerminalTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? TerminalTheme.signalEmerald
                                  : TerminalTheme.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        PersianNumber.formatToman(stepAmount),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TerminalTheme.goldAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step['action'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TerminalTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        PersianNumber.toPersianDigits(
                          stepDate.format(includeTime: false),
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: TerminalTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['rationale'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: TerminalTheme.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
