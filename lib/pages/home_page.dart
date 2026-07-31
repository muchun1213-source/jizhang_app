import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/expense_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.refresh(expenseByMonthProvider));
  }

  void _changeMonth(int delta) {
    int year = ref.read(selectedYearProvider);
    int month = ref.read(selectedMonthProvider) + delta;

    if (month > 12) {
      year++;
      month = 1;
    } else if (month < 1) {
      year--;
      month = 12;
    }

    ref.read(selectedYearProvider.notifier).state = year;
    ref.read(selectedMonthProvider.notifier).state = month;
  }

  @override
  Widget build(BuildContext context) {
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);
    final type = ref.watch(currentTypeProvider);
    final expenses = ref.watch(expenseByMonthProvider);
    final total = ref.watch(monthlyTotalProvider);

    final isExpense = type == 'expense';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, year, month, total, isExpense),
            // 类型切换
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('支出'), icon: Text('📤')),
                  ButtonSegment(value: 'income', label: Text('收入'), icon: Text('💰')),
                ],
                selected: {type},
                onSelectionChanged: (v) {
                  ref.read(currentTypeProvider.notifier).state = v.first;
                },
              ),
            ),
            // 记录列表
            Expanded(
              child: expenses.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        isExpense ? '暂无支出记录' : '暂无收入记录',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(expenseByMonthProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ExpenseCardItem(
                        expense: list[i],
                        isExpense: isExpense,
                        onDelete: () async {
                          final dao = ref.read(expenseDaoProvider);
                          final syncService = ref.read(syncServiceProvider);
                          final expenseId = list[i].expense.id;
                          await dao.deleteExpense(expenseId);
                          try {
                            await syncService.deleteExpenseCloud(expenseId);
                          } catch (_) {}
                          ref.invalidate(expenseByMonthProvider);
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add').then((_) => ref.invalidate(expenseByMonthProvider));
        },
        icon: const Text('✏️', style: TextStyle(fontSize: 18)),
        label: const Text('记一笔'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int year, int month, AsyncValue<double> total, bool isExpense) {
    final currencyFormat = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    final label = isExpense ? '月支出' : '月收入';
    final color = isExpense ? Theme.of(context).colorScheme.primary : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 设置入口
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: '设置',
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '$year年${month}月',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          total.when(
            data: (t) => Text(
              '$label ${currencyFormat.format(t)}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: color),
            ),
            loading: () => const Text('...', style: TextStyle(fontSize: 28)),
            error: (_, __) => const Text('--', style: TextStyle(fontSize: 28)),
          ),
        ],
      ),
    );
  }
}
