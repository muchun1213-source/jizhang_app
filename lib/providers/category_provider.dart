import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../database/dao.dart';

/// 数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// 分类 DAO Provider
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryDao(db);
});

/// 花销 DAO Provider
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseDao(db);
});

/// 当前记录类型：expense（支出）或 income（收入）
final currentTypeProvider = StateProvider<String>((ref) => 'expense');

/// 分类树（按当前类型过滤）
final categoryTreeProvider = StreamProvider<List<CategoryWithChildren>>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  final type = ref.watch(currentTypeProvider);
  return dao.watchCategoryTreeByType(type);
});
