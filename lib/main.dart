import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'database/database.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase 云端
  await SupabaseService.initialize();

  // 初始化数据库并预置分类
  final db = AppDatabase();
  await db.seedCategories();

  // 上传本地分类到云端（修复外键约束导致记账上传静默失败的问题）
  try {
    final syncService = SyncService(db);
    final allCats = await db.select(db.categories).get();
    for (final cat in allCats) {
      await syncService.uploadCategory(cat);
    }
    // 下载云端数据合并到本地
    await syncService.downloadAll();
  } catch (_) {
    // 云端操作失败不阻塞启动
  }

  // 加载用户偏好主题色
  final themeColor = await SettingsService.loadThemeColor();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeColorProvider.overrideWithValue(themeColor),
      ],
      child: const JiZhangApp(),
    ),
  );
}
