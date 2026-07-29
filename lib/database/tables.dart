import 'package:drift/drift.dart';

/// 消费/收入分类表
/// 支持两级分类：parent_id 为 null 是一级大类，非 null 是二级小类
/// type: 'expense'=支出, 'income'=收入
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get icon => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// 花销/收入记录表
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();                          // 金额（元）
  IntColumn get categoryId => integer().references(Categories, #id)();  // 关联二级小类
  TextColumn get note => text().nullable()();                  // 备注
  DateTimeColumn get expenseDate => dateTime()();              // 日期
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)(); // 记录创建时间
}
