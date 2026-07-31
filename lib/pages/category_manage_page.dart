import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../database/tables.dart';

class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key});

  @override
  ConsumerState<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage> {
  String _selectedType = 'expense';

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider(_selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理分类'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('支出'),
                selected: _selectedType == 'expense',
                onSelected: (_) => setState(() => _selectedType = 'expense'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('收入'),
                selected: _selectedType == 'income',
                onSelected: (_) => setState(() => _selectedType = 'income'),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle),
                tooltip: '添加分类',
                onPressed: () => _showAddDialog(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: treeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (tree) => tree.isEmpty
            ? const Center(child: Text('暂无分类，点击右上角添加'))
            : ListView(
                children: tree.expand((node) => [
                  _buildCategoryItem(node.parent, isParent: true),
                  ...node.children.map((c) => _buildCategoryItem(c, isParent: false)),
                ]).toList(),
              ),
      ),
    );
  }

  Widget _buildCategoryItem(Category cat, {required bool isParent}) {
    final icon = cat.icon ?? (isParent ? '📁' : '📌');
    return ListTile(
      contentPadding: EdgeInsets.only(left: isParent ? 16 : 56, right: 8),
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(cat.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _confirmDelete(cat),
      ),
    );
  }

  void _showAddDialog({int? parentId}) {
    final nameCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: '📌');
    String type = _selectedType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(parentId != null ? '添加子分类' : '添加分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '分类名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(labelText: '图标 (emoji)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('类型: '),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('支出'), selected: type == 'expense',
                    onSelected: (_) => setDialogState(() => type = 'expense')),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('收入'), selected: type == 'income',
                    onSelected: (_) => setDialogState(() => type = 'income')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                ref.read(categoryManagerProvider).insertCategory(
                  name: name,
                  icon: iconCtrl.text.trim().isEmpty ? '📌' : iconCtrl.text.trim(),
                  type: type,
                  parentId: parentId,
                );
                Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定删除「${cat.name}」吗？如果该分类下有记账记录，删除后记录会失去分类关联。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(categoryManagerProvider).deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
