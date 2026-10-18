import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'shamsi_date.dart';

// Swiss Minimalist Financial Terminal - API Client & Offline Cache
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Iranian financial assets & Tehran timezone.

class MarketAsset {
  final String id;
  final String nameFa;
  final double price;
  final double intrinsic;
  final double bubble;
  final double bubblePct;
  final String riskLevel;
  final String riskLabelFa;

  const MarketAsset({
    required this.id,
    required this.nameFa,
    required this.price,
    required this.intrinsic,
    required this.bubble,
    required this.bubblePct,
    required this.riskLevel,
    required this.riskLabelFa,
  });

  factory MarketAsset.fromJson(Map<String, dynamic> json) {
    return MarketAsset(
      id: json['id'] as String? ?? '',
      nameFa: json['name_fa'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      intrinsic: (json['intrinsic'] as num?)?.toDouble() ?? 0.0,
      bubble: (json['bubble'] as num?)?.toDouble() ?? 0.0,
      bubblePct: (json['bubble_pct'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] as String? ?? 'low',
      riskLabelFa: json['risk_label_fa'] as String? ?? 'منطقی',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_fa': nameFa,
    'price': price,
    'intrinsic': intrinsic,
    'bubble': bubble,
    'bubble_pct': bubblePct,
    'risk_level': riskLevel,
    'risk_label_fa': riskLabelFa,
  };
}

class MarketResponse {
  final int updatedAt;
  final String updatedAtIso;
  final String shamsiDate;
  final bool isStale;
  final String emergencyNotice;
  final List<MarketAsset> assets;
  final bool isOffline;

  const MarketResponse({
    required this.updatedAt,
    required this.updatedAtIso,
    required this.shamsiDate,
    required this.isStale,
    required this.emergencyNotice,
    required this.assets,
    this.isOffline = false,
  });

  factory MarketResponse.fromJson(Map<String, dynamic> json, {bool isOffline = false}) {
    final list = (json['assets'] as List<dynamic>?) ?? [];
    return MarketResponse(
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      updatedAtIso: json['updated_at_iso'] as String? ?? '',
      shamsiDate: json['shamsi_date'] as String? ?? '',
      isStale: json['is_stale'] as bool? ?? false,
      emergencyNotice: json['emergency_notice'] as String? ?? '',
      assets: list.map((e) => MarketAsset.fromJson(e as Map<String, dynamic>)).toList(),
      isOffline: isOffline,
    );
  }

  Map<String, dynamic> toJson() => {
    'updated_at': updatedAt,
    'updated_at_iso': updatedAtIso,
    'shamsi_date': shamsiDate,
    'is_stale': isStale,
    'emergency_notice': emergencyNotice,
    'assets': assets.map((a) => a.toJson()).toList(),
  };
}

class JewelryCalculationRequest {
  final double weightGram;
  final double gram18kPrice;
  final double laborValue;
  final bool isLaborPercentage;
  final double profitPct;
  final double vatPct;

  const JewelryCalculationRequest({
    required this.weightGram,
    required this.gram18kPrice,
    required this.laborValue,
    required this.isLaborPercentage,
    this.profitPct = 7.0,
    this.vatPct = 9.0,
  });

  Map<String, dynamic> toJson() => {
    'weight_gram': weightGram,
    'gram_18k_price': gram18kPrice,
    'labor_value': laborValue,
    'is_labor_percentage': isLaborPercentage,
    'profit_pct': profitPct,
    'vat_pct': vatPct,
  };
}

class JewelryCalculationResponse {
  final double rawGoldPrice;
  final double laborAmount;
  final double profitAmount;
  final double vatAmount;
  final double totalPrice;

  const JewelryCalculationResponse({
    required this.rawGoldPrice,
    required this.laborAmount,
    required this.profitAmount,
    required this.vatAmount,
    required this.totalPrice,
  });

  factory JewelryCalculationResponse.fromJson(Map<String, dynamic> json) {
    return JewelryCalculationResponse(
      rawGoldPrice: (json['raw_gold_price'] as num?)?.toDouble() ?? 0.0,
      laborAmount: (json['labor_amount'] as num?)?.toDouble() ?? 0.0,
      profitAmount: (json['profit_amount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Exact on-device calculation complying with Iranian tax law
  /// (9% VAT applies strictly to Labor + Profit; raw gold is exempt)
  static JewelryCalculationResponse computeLocally(JewelryCalculationRequest req) {
    final rawGold = req.weightGram * req.gram18kPrice;
    final labor = req.isLaborPercentage
        ? rawGold * (req.laborValue / 100.0)
        : req.weightGram * req.laborValue;
    final profit = (rawGold + labor) * (req.profitPct / 100.0);
    final vat = (labor + profit) * (req.vatPct / 100.0);
    final total = rawGold + labor + profit + vat;

    return JewelryCalculationResponse(
      rawGoldPrice: rawGold.roundToDouble(),
      laborAmount: labor.roundToDouble(),
      profitAmount: profit.roundToDouble(),
      vatAmount: vat.roundToDouble(),
      totalPrice: total.roundToDouble(),
    );
  }
}

class HistoricalPoint {
  final int timestamp;
  final String shamsi;
  final double price;
  final double intrinsic;
  final double bubblePct;

  const HistoricalPoint({
    required this.timestamp,
    required this.shamsi,
    required this.price,
    required this.intrinsic,
    required this.bubblePct,
  });

  factory HistoricalPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalPoint(
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      shamsi: json['shamsi'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      intrinsic: (json['intrinsic'] as num?)?.toDouble() ?? 0.0,
      bubblePct: (json['bubble_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MarketApiClient {
  static const String defaultBaseUrl = 'http://127.0.0.1:8080';
  static const String cacheKeyMarket = 'cached_market_json';
  static const String cacheKeyEtag = 'cached_market_etag';
  static const String prefKeyBaseUrl = 'custom_base_url';

  final http.Client _client;

  MarketApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefKeyBaseUrl) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyBaseUrl, url);
  }

  Future<MarketResponse> fetchMarket({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(prefKeyBaseUrl) ?? defaultBaseUrl;
    final cachedEtag = prefs.getString(cacheKeyEtag) ?? '';

    try {
      final uri = Uri.parse('$baseUrl/api/v1/market');
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (!forceRefresh && cachedEtag.isNotEmpty) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await _client.get(uri, headers: headers).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 304) {
        // Cache is fresh
        final cachedData = prefs.getString(cacheKeyMarket);
        if (cachedData != null) {
          final decoded = json.decode(cachedData) as Map<String, dynamic>;
          return MarketResponse.fromJson(decoded, isOffline: false);
        }
      }

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = json.decode(body) as Map<String, dynamic>;

        // Update cache
        await prefs.setString(cacheKeyMarket, body);
        final etag = response.headers['etag'];
        if (etag != null) {
          await prefs.setString(cacheKeyEtag, etag);
        }

        return MarketResponse.fromJson(decoded, isOffline: false);
      }
    } catch (_) {
      // Network failure or timeout -> fallback to offline cache
    }

    // Attempt to load from offline cache
    final cachedData = prefs.getString(cacheKeyMarket);
    if (cachedData != null) {
      try {
        final decoded = json.decode(cachedData) as Map<String, dynamic>;
        return MarketResponse.fromJson(decoded, isOffline: true);
      } catch (_) {}
    }

    // Default Seed Data if fresh install and offline
    return getOfflineSeedResponse();
  }

  Future<JewelryCalculationResponse> calculateJewelry(JewelryCalculationRequest req) async {
    final baseUrl = await getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/v1/calculate/jewelry');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(req.toJson()),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        return JewelryCalculationResponse.fromJson(
          json.decode(body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fallback to strict on-device legal tax engine
    }

    return JewelryCalculationResponse.computeLocally(req);
  }

  Future<List<HistoricalPoint>> fetchHistorical() async {
    final baseUrl = await getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/v1/historical');
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final pointsJson = decoded['points'] as List<dynamic>? ?? [];
        return pointsJson
            .map((p) => HistoricalPoint.fromJson(p as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // Generate on-device simulated 24h trend if offline
    final now = DateTime.now().toUtc();
    final points = <HistoricalPoint>[];
    const basePrice = 52500000.0;
    const baseIntrinsic = 44200000.0;

    for (int i = 23; i >= 0; i--) {
      final t = now.subtract(Duration(hours: i));
      final tehran = t.add(const Duration(hours: 3, minutes: 30));
      final shamsi = ShamsiDate.fromDateTime(tehran);
      final factor = 1.0 + (i % 5 - 2) * 0.004;
      final price = (basePrice * factor).roundToDouble();
      final bubbleAmt = price - baseIntrinsic;
      final bubblePct = ((bubbleAmt / baseIntrinsic) * 10000).round() / 100.0;

      points.add(
        HistoricalPoint(
          timestamp: t.millisecondsSinceEpoch ~/ 1000,
          shamsi: '${shamsi.hour.toString().padLeft(2, '0')}:${shamsi.minute.toString().padLeft(2, '0')}',
          price: price,
          intrinsic: baseIntrinsic,
          bubblePct: bubblePct,
        ),
      );
    }
    return points;
  }

  static MarketResponse getOfflineSeedResponse() {
    final shamsiNow = ShamsiDate.now();
    return MarketResponse(
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      updatedAtIso: DateTime.now().toIso8601String(),
      shamsiDate: shamsiNow.format(),
      isStale: false,
      emergencyNotice: '',
      isOffline: true,
      assets: const [
        MarketAsset(
          id: 'coin_emami',
          nameFa: 'سکه امامی',
          price: 52500000.0,
          intrinsic: 44200000.0,
          bubble: 8300000.0,
          bubblePct: 18.77,
          riskLevel: 'high',
          riskLabelFa: 'هشدار حباب',
        ),
        MarketAsset(
          id: 'coin_bahar',
          nameFa: 'سکه بهار آزادی',
          price: 47200000.0,
          intrinsic: 44200000.0,
          bubble: 3000000.0,
          bubblePct: 6.78,
          riskLevel: 'low',
          riskLabelFa: 'منطقی',
        ),
        MarketAsset(
          id: 'coin_half',
          nameFa: 'نیم سکه',
          price: 28100000.0,
          intrinsic: 22100000.0,
          bubble: 6000000.0,
          bubblePct: 27.14,
          riskLevel: 'high',
          riskLabelFa: 'هشدار حباب',
        ),
        MarketAsset(
          id: 'coin_quarter',
          nameFa: 'ربع سکه',
          price: 18200000.0,
          intrinsic: 11050000.0,
          bubble: 7150000.0,
          bubblePct: 64.71,
          riskLevel: 'critical',
          riskLabelFa: 'حباب بحرانی',
        ),
        MarketAsset(
          id: 'coin_gram',
          nameFa: 'سکه گرمی',
          price: 8600000.0,
          intrinsic: 5460000.0,
          bubble: 3140000.0,
          bubblePct: 57.51,
          riskLevel: 'critical',
          riskLabelFa: 'حباب بحرانی',
        ),
        MarketAsset(
          id: 'gold_18k',
          nameFa: 'طلای 18 عیار',
          price: 4500000.0,
          intrinsic: 4500000.0,
          bubble: 0.0,
          bubblePct: 0.0,
          riskLevel: 'zero',
          riskLabelFa: 'بدون حباب',
        ),
        MarketAsset(
          id: 'gold_24k',
          nameFa: 'طلای 24 عیار',
          price: 6000000.0,
          intrinsic: 6000000.0,
          bubble: 0.0,
          bubblePct: 0.0,
          riskLevel: 'zero',
          riskLabelFa: 'بدون حباب',
        ),
        MarketAsset(
          id: 'gold_mithqal',
          nameFa: 'مثقال طلا',
          price: 19493000.0,
          intrinsic: 19493000.0,
          bubble: 0.0,
          bubblePct: 0.0,
          riskLevel: 'zero',
          riskLabelFa: 'بدون حباب',
        ),
        MarketAsset(
          id: 'gold_ounce',
          nameFa: 'انس جهانی طلا',
          price: 2720.0,
          intrinsic: 2720.0,
          bubble: 0.0,
          bubblePct: 0.0,
          riskLevel: 'zero',
          riskLabelFa: 'بازار جهانی',
        ),
        MarketAsset(
          id: 'usd_tether',
          nameFa: 'تتر / دلار آزاد',
          price: 65200.0,
          intrinsic: 65200.0,
          bubble: 0.0,
          bubblePct: 0.0,
          riskLevel: 'zero',
          riskLabelFa: 'نرخ پایه',
        ),
      ],
    );
  }
}
