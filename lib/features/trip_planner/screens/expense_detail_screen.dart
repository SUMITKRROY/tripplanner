import 'package:flutter/material.dart';

import '../../../core/utils/navigation_utils.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => NavigationUtils.pop(context),
        ),
        title: const Text('Expense breakdown'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Per-person and total costs by category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            _ExpenseTable(
              rows: const [
                _ExpenseRow(category: 'Hotel', perPerson: 320, total: 640),
                _ExpenseRow(category: 'Food', perPerson: 180, total: 360),
                _ExpenseRow(category: 'Travel', perPerson: 120, total: 240),
                _ExpenseRow(category: 'Entry Fees', perPerson: 20, total: 40),
              ],
              totalPerPerson: 640,
              grandTotal: 1280,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => NavigationUtils.pop(context),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow {
  const _ExpenseRow({
    required this.category,
    required this.perPerson,
    required this.total,
  });

  final String category;
  final double perPerson;
  final double total;
}

class _ExpenseTable extends StatelessWidget {
  const _ExpenseTable({
    required this.rows,
    required this.totalPerPerson,
    required this.grandTotal,
  });

  final List<_ExpenseRow> rows;
  final double totalPerPerson;
  final double grandTotal;

  static String _money(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.2),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              children: [
                _tableCell(context, 'Category', isHeader: true),
                _tableCell(context, 'Per person', isHeader: true),
                _tableCell(context, 'Total', isHeader: true),
              ],
            ),
            ...rows.map((r) => TableRow(
                  children: [
                    _tableCell(context, r.category),
                    _tableCell(context, _money(r.perPerson)),
                    _tableCell(context, _money(r.total)),
                  ],
                )),
            // Total row
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              children: [
                _tableCell(context, 'Total', isHeader: true),
                _tableCell(context, _money(totalPerPerson), isHeader: true),
                _tableCell(context, _money(grandTotal), isHeader: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCell(BuildContext context, String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: isHeader
            ? Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
