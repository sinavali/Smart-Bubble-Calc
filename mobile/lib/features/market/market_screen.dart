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

  @override
  void initState() {
    super.initState();
    _loadMarketData();
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
    final all = _data!.assets;
    if (_activeFilter == 'coins') {
      return all.where((a) => a.id.startsWith('coin_')).toList();
    } else if (_activeFilter == 'gold') {
      return all.where((a) => !a.id.startsWith('coin_')).toList();
    }
    return all;
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

              // Filter Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _buildFilterChip('همه دارایی ها', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('انواع سکه', 'coins'),
                      const SizedBox(width: 8),
                      _buildFilterChip('طلا و ارز', 'gold'),
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

    return Container(
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
    );
  }
}
