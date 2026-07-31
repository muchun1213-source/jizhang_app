import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../database/dao.dart';
import '../providers/category_provider.dart';

class CategoryPicker extends ConsumerWidget {
  final void Function(Category category) onSelected;
  final Category? selectedCategory;

  const CategoryPicker({
    super.key,
    required this.onSelected,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(currentTypeProvider);
    final treeAsync = ref.watch(categoryTreeProvider(type));

    return treeAsync.when(
      data: (tree) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text('分类', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            ...tree.map((node) => _buildCategoryGroup(context, node)),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text('加载分类失败：$e')),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, CategoryWithChildren node) {
    final parentIcon = node.parent.icon ?? '📁';
    return ExpansionTile(
      leading: Text(parentIcon, style: const TextStyle(fontSize: 20)),
      title: Text(node.parent.name),
      initiallyExpanded: selectedCategory != null &&
          node.children.any((c) => c.id == selectedCategory!.id),
      children: node.children.map((child) {
        final isSelected = selectedCategory?.id == child.id;
        return ListTile(
          title: Text(child.name),
          leading: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const SizedBox(width: 20),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () => onSelected(child),
        );
      }).toList(),
    );
  }
}
