import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/savings_provider.dart';

class SavingsDetailScreen extends ConsumerWidget {
  final SavingsCategory category;

  const SavingsDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catAsync = ref.watch(savingsCategoryProvider(category.id));
    final ledgerAsync = ref.watch(savingsLedgerProvider(category.id));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: catAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat')),
        data: (cat) {
          if (cat == null) return const Center(child: Text('Kategori tidak ditemukan'));
          final hasTarget = cat.targetAmount != null && cat.targetAmount! > 0;
          final percentage = hasTarget
              ? (cat.currentAmount / cat.targetAmount!).clamp(0.0, 1.0) as double
              : null;
          final isCompleted = percentage != null && percentage >= 1.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCardPro(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBox(
                            icon: tryParseIconData(cat.icon) ?? Icons.savings,
                            size: 48,
                            radius: 14,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(cat.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(color: Colors.white)),
                                    ),
                                    if (isCompleted) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Tercapai',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            )),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(cat.currentAmount),
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 24,
                                  ),
                                ),
                                if (hasTarget) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Target: ${CurrencyFormatter.format(cat.targetAmount!)} (${(percentage! * 100).toInt()}%)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasTarget) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 10,
                          ),
                        ),
                      ],
                      if (cat.targetDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event_outlined, size: 14, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${DateHelper.formatDate(cat.targetDate!)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Histori', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ledgerAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Gagal memuat histori'),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Belum ada histori',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: entries.map((entry) => _LedgerTile(entry: entry)).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final SavingsLedger entry;

  const _LedgerTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIn = entry.type == 'allocation';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isIn
                    ? AppColors.income.withOpacity(0.1)
                    : AppColors.expense.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 18,
                color: isIn ? AppColors.income : AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIn ? 'Alokasi' : 'Penarikan',
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    DateHelper.formatDate(entry.createdAt),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isIn ? '+' : '-'} ${CurrencyFormatter.format(entry.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isIn ? AppColors.income : AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
