import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/providers/finance_provider.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../data/providers/tasks_provider.dart';
import '../../../../data/models/task_model.dart';
import 'dart:ui';
import '../../../../core/widgets/glass.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background paling belakang
          Positioned.fill(
            child: Image.asset(
              'lib/resources/bg-1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay gelap di atas gambar
          Positioned.fill(
            child: Container(
              color: AppColors.nearBlack.withOpacity(0.6),
            ),
          ),
          // Konten asli
          CustomScrollView(
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
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

/// Card flat gelap solid — pengganti glass/blur, dipakai konsisten di semua
/// section supaya tampilannya senada dengan referensi (Proton Pass / fitness app).
class _FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _FlatCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1F), // solid, tidak transparan/blur
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: child,
    );
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
                      color: Colors.white.withOpacity(0.6),
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
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white70, size: 22),
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

    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              // Transparan dengan sedikit tint putih agar terasa "kaca"
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                // Outer glow lembut
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner glow: gradient tipis dari tepi ke dalam
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.05),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Inner glow tambahan di edge atas (highlight kaca)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Konten asli
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: summaryAsync.when(
                    loading: () => const Center(
                      child: SizedBox(
                        height: 60,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Gagal memuat data',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    data: (summary) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan Bulan Ini',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat('MMM yyyy', 'id_ID').format(DateTime.now()),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
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
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            Container(
                              width: 1, height: 48,
                              color: Colors.white.withOpacity(0.15),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: _FinanceStat(
                                label: 'Pengeluaran',
                                amount: summary.totalExpense,
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                            Container(
                              width: 1, height: 48,
                              color: Colors.white.withOpacity(0.15),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            Expanded(
                              child: _FinanceStat(
                                label: 'Saldo',
                                amount: summary.balance,
                                icon: Icons.account_balance_wallet_outlined,
                                isAccent: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
  final IconData icon;
  final bool isAccent;

  const _FinanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = isAccent ? AppColors.primary : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white70, size: 12),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.formatCompact(amount.abs()),
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
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
              const _SectionHeader(
                title: 'Peringatan Anggaran',
                icon: Icons.warning_amber_rounded,
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
    final isOver = budget.isOverBudget;

    return _FlatCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CategoryIcon(icon: budget.categoryIcon, size: 20, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget.categoryName,
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      isOver ? 'Melebihi batas!' : 'Hampir limit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budget.percentage,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.formatCompact(budget.spent)} / ${CurrencyFormatter.formatCompact(budget.budget)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
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
          const _SectionHeader(
            title: 'Tugas Hari Ini',
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
            error: (_, __) => Text('Gagal memuat tugas', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            data: (tasks) {
              if (tasks.isEmpty) {
                return const _EmptyState(
                  icon: Icons.check_circle_outline_rounded,
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

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 16,
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
                  color: task.isCompleted ? AppColors.primary : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
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
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.tags.map((t) => '#$t').join(' '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateHelper.formatDate(task.dueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: DateHelper.isOverdue(task.dueDate!)
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.5),
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
      case TaskPriority.high: return AppColors.primary;
      case TaskPriority.medium: return Colors.white.withOpacity(0.5);
      case TaskPriority.low: return Colors.white.withOpacity(0.25);
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
          const _SectionHeader(
            title: 'Catatan Terbaru',
            icon: Icons.sticky_note_2_outlined,
          ),
          const SizedBox(height: 12),
          notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
            error: (_, __) => Text('Gagal memuat catatan', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            data: (notes) {
              if (notes.isEmpty) {
                return const _EmptyState(
                  icon: Icons.sticky_note_2_outlined,
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

class _NoteCard extends StatelessWidget {
  final note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isJournal && note.mood != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(moodIcon(note.mood), size: 18, color: AppColors.primary),
              ),
            Text(
              note.title.isEmpty ? 'Tanpa Judul' : note.title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                note.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11, color: Colors.white.withOpacity(0.6),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              DateHelper.relativeTime(note.updatedAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 10, color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.4), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}