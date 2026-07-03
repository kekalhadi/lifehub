import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/providers/finance_provider.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../data/providers/tasks_provider.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/models/task_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _DashboardHeader(greeting: greeting, now: now),
          ),

          // Financial Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _FinanceSummaryCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Budget Alerts
          SliverToBoxAdapter(
            child: _BudgetAlertSection(),
          ),

          // Today's Tasks
          SliverToBoxAdapter(
            child: _TodayTasksSection(),
          ),

          // Recent Notes
          SliverToBoxAdapter(
            child: _RecentNotesSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final DateTime now;

  const _DashboardHeader({required this.greeting, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 20, 20, 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            const Color(0xFF818CF8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: summaryAsync.when(
          loading: () => const Center(
            child: SizedBox(
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => const Text('Gagal memuat data'),
          data: (summary) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Ringkasan Bulan Ini',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Text(
                      DateFormat('MMM yyyy', 'id_ID').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _FinanceStat(
                      label: 'Pemasukan',
                      amount: summary.totalIncome,
                      color: AppColors.income,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Container(
                    width: 1, height: 48,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _FinanceStat(
                      label: 'Pengeluaran',
                      amount: summary.totalExpense,
                      color: AppColors.expense,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  Container(
                    width: 1, height: 48,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _FinanceStat(
                      label: 'Saldo',
                      amount: summary.balance,
                      color: summary.balance >= 0
                          ? AppColors.primary
                          : AppColors.danger,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _FinanceStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatCompact(amount.abs()),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _BudgetAlertSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetStatusProvider);

    return budgetsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (budgets) {
        final alerts = budgets.where((b) => b.isNearLimit || b.isOverBudget).toList();
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Peringatan Anggaran',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
              ),
              const SizedBox(height: 12),
              ...alerts.map((budget) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BudgetAlertCard(budget: budget),
              )),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetAlertCard extends StatelessWidget {
  final BudgetStatus budget;

  const _BudgetAlertCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = budget.isOverBudget ? AppColors.danger : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(budget.categoryIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(budget.categoryName,
                        style: theme.textTheme.labelLarge),
                    Text(
                      budget.isOverBudget ? 'Melebihi batas!' : 'Hampir limit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color, fontWeight: FontWeight.w600, fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budget.percentage,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.formatCompact(budget.spent)} / ${CurrencyFormatter.formatCompact(budget.budget)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayTasksSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(todayTasksStreamProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Tugas Hari Ini',
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Text('Gagal memuat tugas'),
            data: (tasks) {
              if (tasks.isEmpty) {
                return _EmptyState(
                  emoji: '✅',
                  message: 'Tidak ada tugas untuk hari ini.',
                );
              }
              final displayTasks = tasks.take(4).toList();
              return Column(
                children: [
                  ...displayTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DashboardTaskCard(task: task, ref: ref),
                  )),
                  if (tasks.length > 4)
                    Text(
                      '+${tasks.length - 4} tugas lainnya',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardTaskCard extends StatelessWidget {
  final Task task;
  final WidgetRef ref;

  const _DashboardTaskCard({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(task.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(tasksNotifierProvider.notifier).toggleComplete(task),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppColors.secondary : priorityColor,
                  width: 2,
                ),
                color: task.isCompleted
                    ? AppColors.secondary
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? theme.textTheme.bodyMedium?.color
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateHelper.formatDate(task.dueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: DateHelper.isOverdue(task.dueDate!)
                          ? AppColors.danger
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: priorityColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }
}

class _RecentNotesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(recentNotesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Catatan Terbaru',
            icon: Icons.sticky_note_2_outlined,
            iconColor: AppColors.noteIdea,
          ),
          const SizedBox(height: 12),
          notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Text('Gagal memuat catatan'),
            data: (notes) {
              if (notes.isEmpty) {
                return _EmptyState(
                  emoji: '📝',
                  message: 'Belum ada catatan. Mulai tulis sekarang!',
                );
              }
              return SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => _NoteCard(note: notes[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryMap = ref.watch(categoryMapProvider).valueOrNull ?? {};
    final category = resolveCategory(note.categoryId, categoryMap);
    final color = ColorHelper.fromHex(category.colorHex);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.isJournal && note.mood != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(moodEmoji(note.mood), style: const TextStyle(fontSize: 18)),
            ),
          Text(
            note.title.isEmpty ? 'Tanpa Judul' : note.title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color, fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              note.content,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            DateHelper.relativeTime(note.updatedAt),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;

  const _EmptyState({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}