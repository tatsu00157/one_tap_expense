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
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
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

  void _prevMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
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
    final entries = box.toMap().entries.where((e) {
      final date =
          DateTime.parse((e.value as Map)['date'] as String).toLocal();
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.parse((a.value as Map)['date'] as String);
        final db = DateTime.parse((b.value as Map)['date'] as String);
        return db.compareTo(da);
      });

    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_selectedMonth.year}年${_selectedMonth.month}月',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _isCurrentMonth ? Colors.grey.shade300 : null,
                  ),
                  onPressed: _isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'この月の記録はありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final map = entry.value as Map;
                      final amount = map['amount'] as int;
                      final category = map['category'] as String;
                      final memo = (map['memo'] as String?) ?? '';
                      final date =
                          DateTime.parse(map['date'] as String).toLocal();
                      final (icon, color) = _categoryStyle(category);

                      return _SlidableItem(
                        onDelete: () {
                          box.delete(entry.key);
                          setState(() {});
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(date),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              if (memo.isNotEmpty)
                                Text(
                                  memo,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          isThreeLine: memo.isNotEmpty,
                          trailing: Text(
                            '¥${_formatNumber(amount)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

class _SlidableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SlidableItem({required this.child, required this.onDelete});

  @override
  State<_SlidableItem> createState() => _SlidableItemState();
}

class _SlidableItemState extends State<_SlidableItem>
    with SingleTickerProviderStateMixin {
  static const _deleteWidth = 80.0;
  late AnimationController _ctrl;
  late Animation<double> _offsetAnim;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnim = Tween<double>(begin: 0, end: -_deleteWidth).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _showDelete() {
    setState(() => _open = true);
    _ctrl.forward();
  }

  void _hideDelete() {
    setState(() => _open = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200 && !_open) _showDelete();
        if (v > 200 && _open) _hideDelete();
      },
      onTap: () {
        if (_open) _hideDelete();
      },
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _offsetAnim,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: _deleteWidth,
                        color: Colors.red,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete,
                                color: Colors.white, size: 20),
                            SizedBox(height: 2),
                            Text(
                              '削除',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(_offsetAnim.value, 0),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: widget.child,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
