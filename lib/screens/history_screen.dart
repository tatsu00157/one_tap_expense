import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// TODO: Replace with your real Ad Unit IDs before release
const _androidBannerAdUnit = 'ca-app-pub-3940256099942544/6300978111';
const _iosBannerAdUnit = 'ca-app-pub-3940256099942544/2934735716';

class HistoryScreen extends StatefulWidget {
  final bool isPro;

  const HistoryScreen({super.key, required this.isPro});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  BannerAd? _bannerAd;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPro) _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? _androidBannerAdUnit : _iosBannerAdUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _adLoaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.month}月${d.day}日  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  (IconData, Color) _categoryStyle(String category) => switch (category) {
        '食費' => (Icons.restaurant, const Color(0xFFFF7043)),
        '日用品' => (Icons.shopping_basket, const Color(0xFF42A5F5)),
        '交際費' => (Icons.people, const Color(0xFF66BB6A)),
        _ => (Icons.receipt_long, const Color(0xFF9E9E9E)),
      };

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('expenses');
    final items = box.values.toList().reversed.toList();

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('履歴'),
            centerTitle: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'まだ記録がありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final map = items[i] as Map;
                      final amount = map['amount'] as int;
                      final category = map['category'] as String;
                      final date =
                          DateTime.parse(map['date'] as String).toLocal();
                      final (icon, color) = _categoryStyle(category);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _formatDate(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          '¥${_formatNumber(amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!widget.isPro && _adLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
