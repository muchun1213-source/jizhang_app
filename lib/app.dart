import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/add_expense_page.dart';
import 'pages/stats_page.dart';
import 'services/update_service.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(state.uri.path),
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '账单'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
            ],
          ),
        );
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/stats', builder: (_, __) => const StatsPage()),
      ],
    ),
    GoRoute(path: '/add', builder: (_, __) => const AddExpensePage()),
  ],
);

class JiZhangApp extends StatefulWidget {
  const JiZhangApp({super.key});

  @override
  State<JiZhangApp> createState() => _JiZhangAppState();
}

class _JiZhangAppState extends State<JiZhangApp> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final (hasUpdate, downloadUrl, version) = await UpdateService.checkUpdate();
    if (hasUpdate && mounted) {
      UpdateService.showUpdateDialog(context, version!, () async {
        final path = await UpdateService.downloadApk(downloadUrl!);
        await UpdateService.installApk(path);
      });
    }
  }

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

int _calculateSelectedIndex(String path) {
  if (path.startsWith('/stats')) return 1;
  return 0;
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go('/');
    case 1:
      context.go('/stats');
  }
}
