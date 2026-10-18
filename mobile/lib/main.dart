import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartBubbleCalcApp());
}

class SmartBubbleCalcApp extends StatelessWidget {
  const SmartBubbleCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حباب‌سنج و نبض بازار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        primaryColor: const Color(0xFFD4AF37), // Metallic Gold
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          surface: Color(0xFF161920),
          error: Color(0xFFEF5350),
        ),
        fontFamily: 'IRANSans',
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161920),
        elevation: 0,
        title: const Text(
          'SMART BUBBLE CALC // حباب‌سنج',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'monospace',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232F),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2C3242)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                SizedBox(width: 6),
                Text(
                  'FEED: LIVE',
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 48, color: Color(0xFFD4AF37)),
            const SizedBox(height: 16),
            const Text(
              'Swiss Minimalist Terminal UI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '10 Core Assets Ticker • Legal Jewelry Tax Engine • Neural DCA Isolate',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        backgroundColor: const Color(0xFF161920),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'بازار و حباب'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'طلافروشی'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'تحلیلگر هوشمند'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'تنظیمات'),
        ],
      ),
    );
  }
}
