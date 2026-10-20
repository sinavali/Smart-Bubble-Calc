import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/persian_number.dart';
import '../../core/theme.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/sparkline.dart';

// Swiss Minimalist Financial Terminal - Market & Bubble Screen
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran dialect, 10 core Iranian financial assets.

class MarketScreen extends StatefulWidget {
  final MarketApiClient apiClient;

  const MarketScreen({super.key, required this.apiClient});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  MarketResponse? _data;
  List<HistoricalPoint> _history = [];
  bool _isLoading = true;
  String _activeFilter = 'all'; // all, coins, gold
  String _searchQuery = '';
  String _sortBy = 'default'; // default, bubble_desc, bubble_asc, price_desc
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiClient.fetchMarket(forceRefresh: force);
      final hist = await widget.apiClient.fetchHistorical();
      if (mounted) {
        setState(() {
          _data = res;
          _history = hist;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return TerminalTheme.signalCoral;
      case 'high':
        return TerminalTheme.signalCoral;
      case 'medium':
        return TerminalTheme.signalAmber;
      case 'low':
        return TerminalTheme.signalEmerald;
      case 'zero':
      default:
        return TerminalTheme.signalBlue;
    }
  }

  List<MarketAsset> get _filteredAssets {
    if (_data == null) return [];
    var list = _data!.assets;
    if (_activeFilter == 'coins') {
      list = list.where((a) => a.id.startsWith('coin_')).toList();
    } else if (_activeFilter == 'gold') {
      list = list.where((a) => !a.id.startsWith('coin_')).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((a) => a.nameFa.toLowerCase().contains(q) || a.id.toLowerCase().contains(q)).toList();
    }

    final sorted = List<MarketAsset>.from(list);
    switch (_sortBy) {
      case 'bubble_desc':
        sorted.sort((a, b) => b.bubblePct.compareTo(a.bubblePct));
        break;
      case 'bubble_asc':
        sorted.sort((a, b) => a.bubblePct.compareTo(b.bubblePct));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'default':
      default:
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TerminalTheme.carbonBlack,
        body: RefreshIndicator(
          color: TerminalTheme.goldAccent,
          backgroundColor: TerminalTheme.slateDark,
          onRefresh: () => _loadMarketData(force: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Terminal Status & Datetime Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: TerminalTheme.slateDark,
                    border: Border(
                      bottom: BorderSide(color: TerminalTheme.borderColor),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              StatusPill(
                                label: (_data?.isOffline ?? false)
                                    ? 'حالت آفلاین (کش)'
                                    : 'نبض زنده بازار',
                                color: (_data?.isOffline ?? false)
                                    ? TerminalTheme.signalAmber
                                    : TerminalTheme.signalEmerald,
                                isLive: !(_data?.isOffline ?? false),
                              ),
                              const SizedBox(width: 8),
                              const StatusPill(
                                label: 'تهران +3:30',
                                color: TerminalTheme.goldAccent,
                                icon: Icons.schedule,
                              ),
                            ],
                          ),
                          Text(
                            _data != null
                                ? PersianNumber.toPersianDigits(_data!.shamsiDate)
                                : 'در حال بارگذاری...',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TerminalTheme.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      if (_data != null && _data!.emergencyNotice.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: TerminalTheme.signalCoral.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: TerminalTheme.signalCoral.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, size: 16, color: TerminalTheme.signalCoral),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _data!.emergencyNotice,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TerminalTheme.signalCoral,
                                    fontWeight: FontWeight.bold,
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

              // Search and Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    children: [
                      // Search input
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: TerminalTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'جستجو در نام یا نماد دارایی...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: TerminalTheme.goldAccent),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: TerminalTheme.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 10),
                      // Filter Chips & Sort Dropdown Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildFilterChip('همه', 'all'),
                              const SizedBox(width: 6),
                              _buildFilterChip('سکه ها', 'coins'),
                              const SizedBox(width: 6),
                              _buildFilterChip('طلا و ارز', 'gold'),
                            ],
                          ),
                          // Sort Menu
                          PopupMenuButton<String>(
                            initialValue: _sortBy,
                            tooltip: 'مرتب سازی',
                            color: TerminalTheme.cardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: TerminalTheme.borderColor),
                            ),
                            icon: const Icon(Icons.sort, color: TerminalTheme.goldAccent, size: 20),
                            onSelected: (val) => setState(() => _sortBy = val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'default',
                                child: Text('ترتیب پیش فرض', style: TextStyle(fontSize: 12, color: TerminalTheme.textPrimary)),
                              ),
                              const PopupMenuItem(
                                value: 'bubble_desc',
                                child: Text('بیشترین حباب', style: TextStyle(fontSize: 12, color: TerminalTheme.signalCoral)),
                              ),
                              const PopupMenuItem(
                                value: 'bubble_asc',
                                child: Text('کمترین حباب', style: TextStyle(fontSize: 12, color: TerminalTheme.signalEmerald)),
                              ),
                              const PopupMenuItem(
                                value: 'price_desc',
                                child: Text('بالاترین قیمت', style: TextStyle(fontSize: 12, color: TerminalTheme.goldBright)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Asset Cards List
              _isLoading && _data == null
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: TerminalTheme.goldAccent),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final asset = _filteredAssets[index];
                            return _buildAssetCard(asset);
                          },
                          childCount: _filteredAssets.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TerminalTheme.goldAccent : TerminalTheme.cardDark,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? TerminalTheme.goldBright : TerminalTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? TerminalTheme.carbonBlack : TerminalTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(MarketAsset asset) {
    final riskColor = _getRiskColor(asset.riskLevel);
    final hasBubble = asset.bubble > 0;
    final isCoin = asset.id.startsWith('coin_');

    return InkWell(
      onTap: () => _showAssetDetailsModal(asset),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TerminalTheme.cardDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: TerminalTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Title and Risk Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: riskColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        asset.nameFa,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: TerminalTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusPill(
                    label: asset.riskLabelFa,
                    color: riskColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Market Price & Intrinsic Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'قیمت بازار',
                        style: TextStyle(fontSize: 11, color: TerminalTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        asset.id == 'gold_ounce'
                            ? '\$${PersianNumber.toPersianDigits(asset.price.toStringAsFixed(1))}'
                            : PersianNumber.formatToman(asset.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TerminalTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (hasBubble)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'ارزش ذاتی (طلای خالص)',
                          style: TextStyle(fontSize: 11, color: TerminalTheme.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          PersianNumber.formatToman(asset.intrinsic),
                          style: const TextStyle(
                            fontSize: 13,
                            color: TerminalTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              if (hasBubble) ...[
                const SizedBox(height: 10),
                const Divider(color: TerminalTheme.borderColor, height: 1),
                const SizedBox(height: 10),

                // Row 3: Bubble Metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'میزان حباب: ',
                          style: TextStyle(fontSize: 12, color: TerminalTheme.textMuted),
                        ),
                        Text(
                          PersianNumber.formatToman(asset.bubble),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: riskColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'درصد حباب: ${PersianNumber.formatPercent(asset.bubblePct)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Mini Sparkline for coins
              if (isCoin && _history.isNotEmpty) ...[
                const SizedBox(height: 8),
                SparklineGraph(
                  points: _history.map((h) => h.bubblePct).toList(),
                  lineColor: riskColor,
                  height: 24,
                  showArea: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetDetailsModal(MarketAsset asset) {
    final riskColor = _getRiskColor(asset.riskLevel);
    final hasBubble = asset.bubble > 0;

    String weightStr = '-';
    String purityStr = '-';
    String advice = 'معامله با نرخ روز بازار.';

    switch (asset.id) {
      case 'coin_emami':
        weightStr = '8.133 گرم';
        purityStr = '900 در هزار (21.6 عیار)';
        advice = asset.bubblePct > 20.0
            ? 'حباب بالاتر از میانگین تاریخی است؛ در خریدهای مصرفی احتیاط کنید.'
            : 'حباب در محدوده متعادل میانگین فصلی قرار دارد.';
        break;
      case 'coin_bahar':
        weightStr = '8.133 گرم';
        purityStr = '900 در هزار (21.6 عیار)';
        advice = 'سکه طرح قدیم معمولا حباب کمتری نسبت به امامی دارد و گزینه مطمئن تری برای پس انداز است.';
        break;
      case 'coin_half':
        weightStr = '4.066 گرم';
        purityStr = '900 در هزار (21.6 عیار)';
        advice = asset.bubblePct > 25.0
            ? 'حباب نیم سکه سنگین است؛ ورود پله ای ترجیح داده می شود.'
            : 'ریسک حباب در سطح نرمال است.';
        break;
      case 'coin_quarter':
        weightStr = '2.033 گرم';
        purityStr = '900 در هزار (21.6 عیار)';
        advice = 'ربع سکه بیشترین تقاضای خرد و بیشترین نوسان حباب را دارد؛ خرید در اوج حباب توصیه نمی شود.';
        break;
      case 'coin_gram':
        weightStr = '1.010 گرم';
        purityStr = '900 در هزار (21.6 عیار)';
        advice = 'به علت تقاضای هدیه، بخش عمده قیمت سکه گرمی حباب است؛ برای سرمایه گذاری طلای 18 عیار برتر است.';
        break;
      case 'gold_18k':
        weightStr = '1.000 گرم';
        purityStr = '750 در هزار (18 عیار)';
        advice = 'فاقد هرگونه حباب قیمتی بوده و مبنای اصلی ارزش گذاری بازار طلا در ایران است.';
        break;
      case 'gold_24k':
        weightStr = '1.000 گرم';
        purityStr = '999 در هزار (24 عیار / شمش)';
        advice = 'طلای خالص بدون ناخالصی؛ مناسب سرمایه گذاری کلان و شمش های استاندارد.';
        break;
      case 'gold_mithqal':
        weightStr = '4.608 گرم';
        purityStr = '705 در هزار (مبنای مظنه بازار)';
        advice = 'واحد سنتی معاملات بنکداری بازار تهران برای تسویه طلافروشان.';
        break;
      case 'gold_ounce':
        weightStr = '31.1035 گرم';
        purityStr = 'طلای خالص جهانی';
        advice = 'نرخ مرجع بین المللی بازارهای جهانی در نیویورک و لندن.';
        break;
      case 'usd_tether':
        weightStr = '-';
        purityStr = 'ارز دیجیتال با پشتوانه دلار';
        advice = 'نرخ نقدینگی سریع و ابزار مبادله بین بازار طلا و رمزارز.';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TerminalTheme.slateDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: riskColor, width: 2),
              left: const BorderSide(color: TerminalTheme.borderColor, width: 1),
              right: const BorderSide(color: TerminalTheme.borderColor, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        asset.nameFa,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TerminalTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusPill(label: asset.riskLabelFa, color: riskColor),
                ],
              ),
              const SizedBox(height: 16),

              // Price and Intrinsic Details Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TerminalTheme.cardDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: TerminalTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildModalRow('قیمت فعلی بازار:', PersianNumber.formatToman(asset.price)),
                    if (hasBubble) ...[
                      const SizedBox(height: 8),
                      _buildModalRow('ارزش ذاتی طلا:', PersianNumber.formatToman(asset.intrinsic)),
                      const SizedBox(height: 8),
                      _buildModalRow('مبلغ حباب قیمتی:', PersianNumber.formatToman(asset.bubble), highlightColor: riskColor),
                      const SizedBox(height: 8),
                      _buildModalRow('درصد حباب از کل:', PersianNumber.formatPercent(asset.bubblePct), highlightColor: riskColor),
                    ],
                    const Divider(color: TerminalTheme.borderColor, height: 20),
                    _buildModalRow('وزن رسمی استاندارد:', PersianNumber.toPersianDigits(weightStr)),
                    const SizedBox(height: 8),
                    _buildModalRow('عیار و خلوص:', PersianNumber.toPersianDigits(purityStr)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tactical Advice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TerminalTheme.cardLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: riskColor),
                        const SizedBox(width: 6),
                        const Text(
                          'توصیه تحلیلی بازار:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TerminalTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      advice,
                      style: const TextStyle(fontSize: 12, color: TerminalTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TerminalTheme.cardDark,
                  foregroundColor: TerminalTheme.textPrimary,
                  side: const BorderSide(color: TerminalTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('بستن', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: TerminalTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: highlightColor ?? TerminalTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
