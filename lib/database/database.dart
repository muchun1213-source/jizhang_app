import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables.dart';
part 'database.g.dart';

@DriftDatabase(tables: [Categories, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _updateCategoryIcons();
      }
      if (from < 3) {
        await _seedIncomeCategories();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 插入收入分类（v2→v3 迁移 / 首次创建）
  Future<void> _seedIncomeCategories() async {
    final hasIncome = await (select(categories)
      ..where((t) => t.parentId.isNull() & t.type.equals('income')))
      .get();
    if (hasIncome.isNotEmpty) return;

    final incomeSeed = [
      ('收入', '💰', 'income', ['工资', '奖金', '兼职', '理财收益', '退款', '红包收入', '报销', '其他收入']),
    ];

    // 获取当前最大 sortOrder
    final maxRow = await (selectOnly(categories)..addColumns([categories.sortOrder.max()])).getSingle();
    final maxSort = maxRow.read(categories.sortOrder.max()) ?? 0;
    int sortIndex = (maxSort ?? 0) + 1;
    for (final (parent, icon, type, children) in incomeSeed) {
      final parentId = await into(categories).insert(
        CategoriesCompanion.insert(name: parent, icon: Value(icon), type: Value(type), sortOrder: Value(sortIndex++)),
      );
      for (final child in children) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: child,
            parentId: Value(parentId),
            type: Value(type),
            sortOrder: Value(sortIndex++),
          ),
        );
      }
    }
  }

  /// 为已有分类补上 emoji 图标（v1→v2 迁移）
  Future<void> _updateCategoryIcons() async {
    const iconMap = {
      '餐饮': '🍽️',
      '交通': '🚗',
      '购物': '🛍️',
      '娱乐': '🎮',
      '住房': '🏠',
      '通讯': '📱',
      '医疗': '💊',
      '教育': '📚',
      '人情': '🎁',
      '其他': '📦',
    };
    for (final entry in iconMap.entries) {
      await (update(categories)..where((t) => t.name.equals(entry.key)))
          .write(CategoriesCompanion(icon: Value(entry.value)));
    }
  }

  /// 预置默认分类数据（带 emoji 图标）
  Future<void> _seedCategories() async {
    final seedData = [
      ('餐饮', '🍽️', ['早餐', '午餐', '晚餐', '零食', '饮品', '水果']),
      ('交通', '🚗', ['公交地铁', '打车', '加油', '停车', '火车票', '飞机票']),
      ('购物', '🛍️', ['服饰', '数码', '日用', '美妆', '母婴', '家居']),
      ('娱乐', '🎮', ['电影', 'K歌', '游戏', '运动', '旅游', '聚会']),
      ('住房', '🏠', ['房租', '物业', '水费', '电费', '燃气', '维修']),
      ('通讯', '📱', ['话费', '宽带', '快递']),
      ('医疗', '💊', ['药品', '门诊', '住院', '体检']),
      ('教育', '📚', ['学费', '书籍', '培训', '文具']),
      ('人情', '🎁', ['红包', '送礼', '请客']),
      ('其他', '📦', ['其他支出']),
    ];

    int sortIndex = 0;
    for (final (parent, icon, children) in seedData) {
      final parentId = await into(categories).insert(
        CategoriesCompanion.insert(name: parent, icon: Value(icon), sortOrder: Value(sortIndex++)),
      );
      for (final child in children) {
        await into(categories).insert(
          CategoriesCompanion.insert(
            name: child,
            parentId: Value(parentId),
            sortOrder: Value(sortIndex++),
          ),
        );
      }
    }
  }

  /// 兼容旧版无 migration 策略的调用方式
  Future<void> seedCategories() async {
    final count = await (select(categories)..where((t) => t.parentId.isNull())).get();
    if (count.isNotEmpty) {
      await _updateCategoryIcons();
      return;
    }
    await _seedCategories();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'ji_zhang.db');
    return NativeDatabase.createInBackground(File(dbPath));
  });
}
