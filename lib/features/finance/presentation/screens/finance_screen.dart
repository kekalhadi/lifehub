import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';
import 'add_transaction_screen.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transaksi'),
            Tab(text: 'Anggaran'),
            Tab(text: 'Statistik'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TransactionsTab(selectedMonth: _selectedMonth),
          _BudgetTab(),
          _StatisticsTab(selectedMonth: _selectedMonth),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Transactions Tab ──────────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerStatefulWidget {
  final DateTime selectedMonth;

  const _TransactionsTab({required this.selectedMonth});

  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateRange = DateRange(
      start: DateTime(_month.year, _month.month, 1),
      end: DateTime(_month.year, _month.month + 1, 0, 23, 59, 59),
    );
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final transactionsAsync = ref.watch(transactionsProvider(dateRange));

    return Column(
      children: [
        // Month picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
              ),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_month),
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _month.year == DateTime.now().year &&
                    _month.month == DateTime.now().month
                    ? null
                    : () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
              ),
            ],
          ),
        ),

        // Summary Row
        summaryAsync.when(
          loading: () => const SizedBox(height: 70),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Pemasukan',
                    amount: summary.totalIncome,
                    color: AppColors.income,
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: _SummaryItem(
                    label: 'Pengeluaran',
                    amount: summary.totalExpense,
                    color: AppColors.expense,
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: _SummaryItem(
                    label: 'Saldo',
                    amount: summary.balance,
                    color: summary.balance >= 0
                        ? AppColors.primary
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Transactions list
        Expanded(
          child: transactionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (transactions) {
              if (transactions.isEmpty) {
                return const _EmptyFinance();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TransactionCard(
                  transaction: transactions[i],
                  onDelete: () => ref
                      .read(financeNotifierProvider.notifier)
                      .deleteTransaction(transactions[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const _TransactionCard({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;
    final catColor = ColorHelper.fromHex(transaction.categoryColorHex);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(transaction.categoryIcon,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.categoryName,
                      style: theme.textTheme.labelLarge),
                  if (transaction.note.isNotEmpty)
                    Text(transaction.note,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.walletName} • ${DateHelper.formatDate(transaction.date)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatCompact(transaction.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: amountColor, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Budget Tab ────────────────────────────────────────────────────────────────

class _BudgetTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(budgetStatusProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (budgets) {
        if (budgets.isEmpty) {
          return const Center(child: Text('Belum ada kategori dengan anggaran.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: budgets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BudgetCard(budget: budgets[i]),
        );
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetStatus budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = budget.isOverBudget
        ? AppColors.danger
        : budget.isNearLimit
        ? AppColors.warning
        : AppColors.secondary;
    final catColor = ColorHelper.fromHex(budget.categoryColorHex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(budget.categoryIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.categoryName, style: theme.textTheme.labelLarge),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / ${CurrencyFormatter.format(budget.budget)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(budget.percentage * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color, fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (budget.isOverBudget)
                    Text(
                      'Melebihi!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.danger, fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budget.percentage,
              backgroundColor: catColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sisa: ${CurrencyFormatter.format((budget.budget - budget.spent).abs())}${budget.isOverBudget ? ' (melebihi)' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: budget.isOverBudget ? AppColors.danger : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Statistics Tab ───────────────────────────────────────────────────────────

class _StatisticsTab extends ConsumerWidget {
  final DateTime selectedMonth;

  const _StatisticsTab({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (summary) {
        if (summary.expenseByCategory.isEmpty) {
          return const _EmptyFinance();
        }

        final sortedExpenses = summary.expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengeluaran per Kategori',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: sortedExpenses.asMap().entries.map((e) {
                            final index = e.key;
                            final entry = e.value;
                            final percentage =
                                entry.value / summary.totalExpense * 100;
                            final color = AppColors.chartColors[
                            index % AppColors.chartColors.length];
                            return PieChartSectionData(
                              value: entry.value,
                              title: percentage > 5
                                  ? '${percentage.toInt()}%'
                                  : '',
                              color: color,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: sortedExpenses.asMap().entries.map((e) {
                        final index = e.key;
                        final entry = e.value;
                        final color = AppColors.chartColors[
                        index % AppColors.chartColors.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Category breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rincian Pengeluaran',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...sortedExpenses.asMap().entries.map((e) {
                      final index = e.key;
                      final entry = e.value;
                      final color = AppColors.chartColors[
                      index % AppColors.chartColors.length];
                      final pct = entry.value / summary.totalExpense;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  CurrencyFormatter.formatCompact(entry.value),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700, color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: color.withOpacity(0.1),
                                valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount.abs()),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color, fontWeight: FontWeight.w700, fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyFinance extends StatelessWidget {
  const _EmptyFinance();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi\nTap + untuk tambah transaksi',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}