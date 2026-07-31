import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('主题色', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: presetColors.map((color) {
              final isSelected = currentColor.value == color.value;
              return GestureDetector(
                onTap: () {
                  ref.read(themeColorProvider.notifier).state = color;
                  SettingsService.saveThemeColor(color);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('管理分类'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
        ],
      ),
    );
  }
}
