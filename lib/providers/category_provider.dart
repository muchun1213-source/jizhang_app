import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../database/dao.dart';
import '../services/sync_service.dart';

/// 数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// 同步服务 Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db);
});

/// 分类管理 Provider（增删）
final categoryManagerProvider = Provider<CategoryManager>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryManager(db);
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
final categoryTreeProvider = StreamProvider.family<List<CategoryWithChildren>, String>((ref, type) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchCategoryTreeByType(type);
});
