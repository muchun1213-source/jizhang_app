import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dao.dart';

class ExpenseCardItem extends StatelessWidget {
  final ExpenseWithCategory expense;
  final bool isExpense;
  final VoidCallback onDelete;

  const ExpenseCardItem({
    super.key,
    required this.expense,
    required this.isExpense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '¥', decimalDigits: 2);
    final dateStr = DateFormat('MM-dd HH:mm').format(expense.expense.expenseDate);
    final amountColor = isExpense ? null : Colors.green;

    final catIcon = expense.category.icon;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.green[50],
          radius: 22,
          child: Text(
            catIcon ?? (expense.category.name.isNotEmpty ? expense.category.name[0] : '?'),
            style: TextStyle(
              fontSize: catIcon != null ? 18 : 14,
              color: isExpense
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.green[800],
            ),
          ),
        ),
        title: Text(expense.category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          dateStr + (expense.expense.note != null ? ' · ${expense.expense.note}' : ''),
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Text(
          currencyFormat.format(expense.expense.amount),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: amountColor),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('删除记录'),
              content: Text('确定删除「${expense.category.name} ${currencyFormat.format(expense.expense.amount)}」？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    onDelete();
                    Navigator.pop(context);
                  },
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
