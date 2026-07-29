import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'database/database.dart';
import 'providers/category_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase 云端
  await SupabaseService.initialize();

  // 初始化数据库并预置分类
  final db = AppDatabase();
  await db.seedCategories();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const JiZhangApp(),
    ),
  );
}

class JiZhangApp extends StatelessWidget {
  const JiZhangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
