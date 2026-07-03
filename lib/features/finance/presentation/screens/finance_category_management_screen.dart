import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';
import 'add_finance_category_screen.dart';

/// Layar kelola kategori finance: list semua kategori + tambah/edit/hapus.
class FinanceCategoryManagementScreen extends ConsumerWidget {
  const FinanceCategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Kategori'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Pemasukan'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: TransactionType.expense),
            _CategoryList(type: TransactionType.income),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return FloatingActionButton(
              onPressed: () {
                final type = tabController.index == 0
                    ? TransactionType.expense
                    : TransactionType.income;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddFinanceCategoryScreen(type: type),
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final TransactionType type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(allFinanceCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat: $e')),
      data: (all) {
        final categories =
            all.where((c) => c.type == type).toList()
              ..sort((a, b) {
                if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
                return a.name.compareTo(b.name);
              });

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined,
                    size: 64, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  'Belum ada kategori\nTap + untuk buat kategori',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final cat = categories[index];
            final color = ColorHelper.fromHex(cat.colorHex);
            return _CategoryTile(category: cat, color: color);
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FinanceCategory category;
  final Color color;

  const _CategoryTile({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: CategoryIcon(icon: category.icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: theme.textTheme.titleMedium),
                if (category.isDefault)
                  Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 11, color: Colors.grey.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        'Bawaan',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Budget badge
          if (category.type == TransactionType.expense &&
              category.budgetLimit != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                CurrencyFormatter.formatCompact(category.budgetLimit!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddFinanceCategoryScreen(
                    categoryToEdit: category,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
