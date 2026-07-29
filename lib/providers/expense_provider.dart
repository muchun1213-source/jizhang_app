import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/dao.dart';
import 'category_provider.dart';

/// 花销记录列表 Provider
final expenseListProvider = FutureProvider<List<ExpenseWithCategory>>((ref) {
  final dao = ref.watch(expenseDaoProvider);
  final type = ref.watch(currentTypeProvider);
  return dao.getRecordsByType(type);
});

/// 当前选中的年月
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

/// 按类型+年月筛选的记录列表
final expenseByMonthProvider = FutureProvider<List<ExpenseWithCategory>>((ref) {
  final year = ref.watch(selectedYearProvider);
  final month = ref.watch(selectedMonthProvider);
  final type = ref.watch(currentTypeProvider);
  final dao = ref.watch(expenseDaoProvider);
  return dao.getRecordsByMonth(type, year, month);
});
