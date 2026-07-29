import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../database/database.dart';
import '../widgets/category_picker.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String _type = 'expense';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('金额不合法')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    final dao = ref.read(expenseDaoProvider);
    await dao.addExpense(
      amount: amount,
      categoryId: _selectedCategory!.id,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      expenseDate: _selectedDate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已记录')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isExpense = _type == 'expense';

    return Scaffold(
      appBar: AppBar(title: const Text('✏️ 记一笔'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 支出/收入切换
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出'), icon: Text('📤')),
                ButtonSegment(value: 'income', label: Text('收入'), icon: Text('💰')),
              ],
              selected: {_type},
              onSelectionChanged: (v) {
                setState(() {
                  _type = v.first;
                  _selectedCategory = null;
                });
                ref.read(currentTypeProvider.notifier).state = v.first;
              },
            ),
            const SizedBox(height: 16),
            // 金额输入
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: isExpense ? null : Colors.green,
              ),
              decoration: const InputDecoration(
                prefixText: '¥ ',
                hintText: '0.00',
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 32),
            // 日期选择
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(isExpense ? '消费日期' : '收入日期'),
              trailing: Text(dateStr, style: const TextStyle(fontSize: 16)),
              onTap: _pickDate,
            ),
            const Divider(height: 1),
            // 分类选择
            CategoryPicker(
              onSelected: (cat) => setState(() => _selectedCategory = cat),
              selectedCategory: _selectedCategory,
            ),
            const Divider(height: 1),
            // 备注
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: '备注（选填）',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 40),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                child: const Text('保存', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
