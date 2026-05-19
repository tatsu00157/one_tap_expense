import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'screens/input_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

// TODO: Replace with your actual RevenueCat API keys
const _rcAndroidKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';
const _rcIosKey = 'YOUR_REVENUECAT_IOS_API_KEY';

// TODO: Replace with your entitlement identifier in RevenueCat dashboard
const kProEntitlementId = 'pro';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('expenses');
  await MobileAds.instance.initialize();
  await Purchases.configure(
    PurchasesConfiguration(Platform.isAndroid ? _rcAndroidKey : _rcIosKey),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1タップ支出管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      if (mounted) {
        setState(() {
          _isPro = info.entitlements.active.containsKey(kProEntitlementId);
        });
      }
    } catch (_) {}
  }

  void _onPurchaseComplete() {
    setState(() => _isPro = true);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const InputScreen(),
      HistoryScreen(isPro: _isPro),
      SettingsScreen(isPro: _isPro, onPurchaseComplete: _onPurchaseComplete),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '入力',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
