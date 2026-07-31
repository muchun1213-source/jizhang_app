import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../database/database.dart';

/// 数据同步服务：本地 SQLite ↔ 云端 Supabase
class SyncService {
  final AppDatabase _db;
  late final SupabaseClient _supabase;

  SyncService(this._db) {
    _supabase = SupabaseService.client;
  }

  // ─── 单条上传 ───

  /// 上传一条花销/收入记录到云端
  Future<void> uploadExpense(Expense exp) async {
    await _supabase.from('expenses').upsert({
      'id': exp.id,
      'amount': exp.amount,
      'category_id': exp.categoryId,
      'note': exp.note,
      'expense_date': exp.expenseDate.toIso8601String(),
      'created_at': exp.createdAt.toIso8601String(),
    });
  }

  /// 上传一条分类到云端
  Future<void> uploadCategory(Category cat) async {
    await _supabase.from('categories').upsert({
      'id': cat.id,
      'name': cat.name,
      'parent_id': cat.parentId,
      'icon': cat.icon,
      'type': cat.type,
      'sort_order': cat.sortOrder,
    });
  }

  // ─── 云端删除 ───

  /// 从云端删除一条记录
  Future<void> deleteExpenseCloud(int id) async {
    await _supabase.from('expenses').delete().eq('id', id);
  }

  /// 从云端删除一条分类
  Future<void> deleteCategoryCloud(int id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }

  // ─── 批量操作 ───

  /// 从云端下载数据并合并到本地
  Future<void> downloadAll() async {
    // 下载分类
    final remoteCats = await _supabase.from('categories').select();
    for (final row in remoteCats) {
      await _db.into(_db.categories).insertOnConflictUpdate(
        CategoriesCompanion(
          id: Value(row['id'] as int),
          name: Value(row['name'] as String),
          parentId: Value(row['parent_id'] as int?),
          icon: Value(row['icon'] as String?),
          type: Value(row['type'] as String? ?? 'expense'),
          sortOrder: Value(row['sort_order'] as int? ?? 0),
        ),
      );
    }

    // 下载记录
    final remoteExps = await _supabase.from('expenses').select();
    for (final row in remoteExps) {
      await _db.into(_db.expenses).insertOnConflictUpdate(
        ExpensesCompanion(
          id: Value(row['id'] as int),
          amount: Value((row['amount'] as num).toDouble()),
          categoryId: Value(row['category_id'] as int),
          note: Value(row['note'] as String?),
          expenseDate: Value(DateTime.parse(row['expense_date'] as String)),
          createdAt: Value(DateTime.parse(row['created_at'] as String)),
        ),
      );
    }
  }

  /// 完整同步：先上传本地，再下载云端
  Future<void> fullSync() async {
    await _uploadAll();
    await downloadAll();
  }

  /// 上传本地所有数据
  Future<void> _uploadAll() async {
    final allCats = await _db.select(_db.categories).get();
    for (final cat in allCats) {
      await _supabase.from('categories').upsert({
        'id': cat.id,
        'name': cat.name,
        'parent_id': cat.parentId,
        'icon': cat.icon,
        'type': cat.type,
        'sort_order': cat.sortOrder,
      });
    }

    final allExps = await _db.select(_db.expenses).get();
    for (final exp in allExps) {
      await _supabase.from('expenses').upsert({
        'id': exp.id,
        'amount': exp.amount,
        'category_id': exp.categoryId,
        'note': exp.note,
        'expense_date': exp.expenseDate.toIso8601String(),
        'created_at': exp.createdAt.toIso8601String(),
      });
    }
  }
}
