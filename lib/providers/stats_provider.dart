import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_provider.dart';
import 'expense_provider.dart';

/// 当月各一级大类汇总统计（按当前类型）
final monthlyStatsProvider = FutureProvider<Map<String, double>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final month = ref.watch(selectedMonthProvider);
  final type = ref.watch(currentTypeProvider);
  final dao = ref.watch(expenseDaoProvider);
  return dao.getMonthlyStatsByParent(type, year, month);
});

/// 当月总金额（按当前类型）
final monthlyTotalProvider = Provider<AsyncValue<double>>((ref) {
  final stats = ref.watch(monthlyStatsProvider);
  return stats.when(
    data: (data) => AsyncValue.data(data.values.fold(0.0, (a, b) => a + b)),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
