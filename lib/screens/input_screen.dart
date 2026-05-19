import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  String _input = '';
  int _monthlyTotal = 0;
  DateTime _selectedDate = DateTime.now();
  final _memoController = TextEditingController();

  static const _categories = [
    ('食費', Icons.restaurant, Color(0xFFFF7043)),
    ('日用品', Icons.shopping_basket, Color(0xFF42A5F5)),
    ('交際費', Icons.people, Color(0xFF66BB6A)),
    ('その他', Icons.receipt_long, Color(0xFF9E9E9E)),
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthlyTotal();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _loadMonthlyTotal() {
    final box = Hive.box('expenses');
    final now = DateTime.now();
    int total = 0;
    for (final item in box.values) {
      final map = item as Map;
      final date = DateTime.parse(map['date'] as String);
      if (date.year == now.year && date.month == now.month) {
        total += map['amount'] as int;
      }
    }
    setState(() => _monthlyTotal = total);
  }

  void _onKey(String key) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (key == 'C') {
        _input = '';
      } else if (key == '00') {
        if (_input.isNotEmpty && _input != '0') _input += '00';
      } else {
        if (_input.length < 7) _input += key;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _save(String category) async {
    final amount = int.tryParse(_input);
    if (amount == null || amount == 0) return;

    final now = DateTime.now();
    final dateToSave = _isToday
        ? now
        : DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day, 12);

    final box = Hive.box('expenses');
    await box.add({
      'amount': amount,
      'category': category,
      'date': dateToSave.toIso8601String(),
      'memo': _memoController.text.trim(),
    });

    _memoController.clear();
    setState(() {
      _input = '';
      _selectedDate = DateTime.now();
    });
    _loadMonthlyTotal();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$category  ¥${_formatNumber(amount)} を記録しました'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final displayAmount =
        _input.isEmpty ? '0' : _formatNumber(int.parse(_input));

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildAmountDisplay(displayAmount),
          _buildDateRow(),
          Expanded(child: _buildNumpad()),
          _buildMemoInput(),
          _buildCategoryRow(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今月の支出合計',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${_formatNumber(_monthlyTotal)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(String displayAmount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '¥$displayAmount',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _input.isEmpty ? Colors.grey.shade400 : Colors.black87,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isToday
                      ? Colors.grey.shade700
                      : Colors.blue.shade600,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_drop_down,
                  size: 22, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _memoController,
          decoration: InputDecoration(
            hintText: 'メモ（任意）',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 15),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: Icon(Icons.edit_note,
                size: 22, color: Colors.grey.shade500),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 40, minHeight: 0),
          ),
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['00', '0', 'C'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) {
                final isC = key == 'C';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color:
                          isC ? Colors.red.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _onKey(key),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: isC
                                  ? Colors.red.shade400
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: _categories.map((cat) {
          final (label, _, color) = cat;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => _save(label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
