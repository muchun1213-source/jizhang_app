import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);
    final type = ref.watch(currentTypeProvider);
    final stats = ref.watch(monthlyStatsProvider);
    final total = ref.watch(monthlyTotalProvider);
    final currencyFormat = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    final isExpense = type == 'expense';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(isExpense ? '📊' : '💰', style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '$year年${month}月 ${isExpense ? "支出" : "收入"}统计',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  total.when(
                    data: (t) => Text(
                      '合计 ${currencyFormat.format(t)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isExpense ? Theme.of(context).colorScheme.primary : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 类型切换
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
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
            const Divider(height: 24),
            Expanded(
              child: stats.when(
                data: (data) {
                  if (data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isExpense ? '📭' : '💸', style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            isExpense ? '本月暂无支出' : '本月暂无收入',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  final sorted = data.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final maxAmount = sorted.first.value;
                  final barColor = isExpense
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final entry = sorted[i];
                      final ratio = maxAmount > 0 ? entry.value / maxAmount : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 15)),
                                Text(currencyFormat.format(entry.value),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                color: barColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
