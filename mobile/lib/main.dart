import 'dart:async';
import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/persian_number.dart';
import 'core/shamsi_date.dart';
import 'core/theme.dart';
import 'features/market/market_screen.dart';
import 'features/jewelry/jewelry_screen.dart';
import 'features/advisor/advisor_screen.dart';
import 'features/settings/settings_screen.dart';

// Swiss Minimalist Financial Terminal - Main Application Entrypoint
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Culture: fa-IR, Tehran dialect & timezone.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartBubbleCalcApp());
}

class SmartBubbleCalcApp extends StatelessWidget {
  const SmartBubbleCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حباب سنج و نبض بازار',
      debugShowCheckedModeBanner: false,
      theme: TerminalTheme.darkTheme,
      home: const TerminalHomeScreen(),
    );
  }
}

class TerminalHomeScreen extends StatefulWidget {
  const TerminalHomeScreen({super.key});

  @override
  State<TerminalHomeScreen> createState() => _TerminalHomeScreenState();
}

class _TerminalHomeScreenState extends State<TerminalHomeScreen> {
  int _selectedTab = 0;
  final MarketApiClient _apiClient = MarketApiClient();
  late ShamsiDate _currentTehranShamsi;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTehranShamsi = ShamsiDate.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {
          _currentTehranShamsi = ShamsiDate.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MarketScreen(apiClient: _apiClient),
      JewelryScreen(apiClient: _apiClient),
      AdvisorScreen(apiClient: _apiClient),
      SettingsScreen(apiClient: _apiClient),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: TerminalTheme.goldAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SMART BUBBLE CALC // حباب سنج',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TerminalTheme.cardDark,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TerminalTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: TerminalTheme.goldAccent),
                const SizedBox(width: 6),
                Text(
                  PersianNumber.toPersianDigits(
                    '${_currentTehranShamsi.hour.toString().padLeft(2, '0')}:${_currentTehranShamsi.minute.toString().padLeft(2, '0')}',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: TerminalTheme.goldAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: screens,
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) => setState(() => _selectedTab = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'بازار و حباب',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate),
              label: 'طلافروشی',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'تحلیلگر هوشمند',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}
