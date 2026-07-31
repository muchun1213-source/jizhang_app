import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'dao.g.dart';

/// 分类相关操作
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 获取指定类型的所有一级大类
  Future<List<Category>> getParentCategoriesByType(String type) {
    return (select(categories)
      ..where((t) => t.parentId.isNull() & t.type.equals(type))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
      .get();
  }

  /// 获取某个大类下的所有小类
  Future<List<Category>> getChildCategories(int parentId) {
    return (select(categories)
      ..where((t) => t.parentId.equals(parentId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
      .get();
  }

  /// 根据 ID 获取分类
  Future<Category?> getCategoryById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 获取完整分类树（按类型过滤）
  Stream<List<CategoryWithChildren>> watchCategoryTreeByType(String type) {
    final parentQuery = select(categories)
      ..where((t) => t.parentId.isNull() & t.type.equals(type));
    return parentQuery.watch().asyncMap((parents) async {
      final result = <CategoryWithChildren>[];
      for (final p in parents) {
        final children = await getChildCategories(p.id);
        result.add(CategoryWithChildren(parent: p, children: children));
      }
      return result;
    });
  }
}

/// 分类管理操作（不依赖 .g 生成，直接使用内部 db）
class CategoryManager {
  final AppDatabase _db;
  CategoryManager(this._db);

  Future<int> insertCategory({
    required String name,
    required String icon,
    required String type,
    int? parentId,
  }) async {
    final maxRow = await (_db
        .selectOnly(_db.categories)
        ..addColumns([_db.categories.sortOrder.max()])).getSingle();
    final maxSort = maxRow.read(_db.categories.sortOrder.max()) ?? 0;

    return _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: name,
        icon: Value(icon),
        type: Value(type),
        parentId: Value(parentId),
        sortOrder: Value(maxSort + 1),
      ),
    );
  }

  Future<void> deleteCategory(int id) async {
    // 删除子分类
    final children = await (_db.select(_db.categories)
      ..where((t) => t.parentId.equals(id))).get();
    for (final child in children) {
      await (_db.delete(_db.categories)
        ..where((t) => t.id.equals(child.id))).go();
    }
    // 删除自身
    await (_db.delete(_db.categories)
      ..where((t) => t.id.equals(id))).go();
  }
}

/// 花销/收入记录相关操作
@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  /// 插入一条记录
  Future<int> addExpense({
    required double amount,
    required int categoryId,
    String? note,
    required DateTime expenseDate,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        amount: amount,
        categoryId: categoryId,
        note: Value(note),
        expenseDate: expenseDate,
      ),
    );
  }

  /// 删除一条记录
  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((t) => t.id.equals(id))).go();
  }

  /// 按类型获取所有记录（按日期倒序）
  Future<List<ExpenseWithCategory>> getRecordsByType(String type) {
    final query = select(expenses).join([
      leftOuterJoin(categories, categories.id.equalsExp(expenses.categoryId)),
    ])
      ..where(categories.type.equals(type))
      ..orderBy([OrderingTerm(expression: expenses.expenseDate, mode: OrderingMode.desc)]);
    return query.map((row) {
      return ExpenseWithCategory(
        expense: row.readTable(expenses),
        category: row.readTable(categories),
      );
    }).get();
  }

  /// 按类型+年月筛选记录
  Future<List<ExpenseWithCategory>> getRecordsByMonth(String type, int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final query = select(expenses).join([
      leftOuterJoin(categories, categories.id.equalsExp(expenses.categoryId)),
    ])
      ..where(
        categories.type.equals(type) &
        expenses.expenseDate.isBetweenValues(startDate, endDate.subtract(const Duration(seconds: 1)))
      )
      ..orderBy([OrderingTerm(expression: expenses.expenseDate, mode: OrderingMode.desc)]);

    return query.map((row) {
      return ExpenseWithCategory(
        expense: row.readTable(expenses),
        category: row.readTable(categories),
      );
    }).get();
  }

  /// 按类型+年月统计各一级大类的总额
  Future<Map<String, double>> getMonthlyStatsByParent(String type, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final rows = await (select(expenses).join([
      leftOuterJoin(categories, categories.id.equalsExp(expenses.categoryId)),
    ])
      ..where(
        categories.type.equals(type) &
        expenses.expenseDate.isBetweenValues(startDate, endDate.subtract(const Duration(seconds: 1)))
      ))
      .get();

    final stats = <String, double>{};
    for (final row in rows) {
      final cat = row.readTable(categories);
      String parentName = cat.name;
      if (cat.parentId != null) {
        final q = select(categories)..where((t) => t.id.equals(cat.parentId!));
        final parent = await q.getSingleOrNull();
        if (parent != null) {
          parentName = parent.name;
        }
      }
      final amount = row.readTable(expenses).amount;
      stats[parentName] = (stats[parentName] ?? 0) + amount;
    }
    return stats;
  }
}

/// 辅助数据类
class CategoryWithChildren {
  final Category parent;
  final List<Category> children;
  CategoryWithChildren({required this.parent, required this.children});
}

class ExpenseWithCategory {
  final Expense expense;
  final Category category;
  ExpenseWithCategory({required this.expense, required this.category});
}
