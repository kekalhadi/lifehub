import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/providers/finance_provider.dart';
import '../../../../data/providers/savings_provider.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../data/providers/tasks_provider.dart';
import '../../../../data/providers/profile_provider.dart';
import '../../../../data/models/task_model.dart';
import 'dart:ui';
import '../../../../core/widgets/glass.dart';
import '../../../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../../../features/finance/presentation/screens/savings_detail_screen.dart';

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

class _DashboardHeader extends ConsumerWidget {
  final String greeting;
  final DateTime now;

  const _DashboardHeader({required this.greeting, required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileStreamProvider);
    final missedCountAsync = ref.watch(missedTasksCountProvider);

    final displayName = profileAsync.whenOrNull(
      data: (p) => (p != null && p.name.isNotEmpty) ? p.name : null,
    );
    final avatarPath = profileAsync.whenOrNull<String?>(
      data: (p) => p?.avatarPath,
    );
    final missedCount = missedCountAsync.whenOrNull(data: (c) => c) ?? 0;

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
                    displayName != null ? 'Halo, $displayName' : greeting,
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
              GestureDetector(
                onTap: () => _showProfileMenu(context, missedCount),
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: avatarPath != null && File(avatarPath).existsSync()
                            ? Image.file(
                                File(avatarPath),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 22,
                              ),
                      ),
                    ),
                    if (missedCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEF4444),
                          ),
                          child: Center(
                            child: Text(
                              missedCount > 9 ? '9+' : '$missedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, int missedCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.person_outline,
              label: 'Profil',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _MenuTile(
              icon: Icons.notifications_outlined,
              label: 'Notifikasi',
              badge: missedCount,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

class _FinanceSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(monthlySummaryProvider(DateRange.thisMonth()));
    final savingsAsync = ref.watch(oldestSavingsCategoriesProvider);

    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
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
                        savingsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (categories) {
                            if (categories.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 18),
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: Colors.white.withOpacity(0.10),
                                ),
                                const SizedBox(height: 16),
                                ...categories.map((cat) => _SavingsProgressCard(category: cat)),
                              ],
                            );
                          },
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
    final budgetsAsync = ref.watch(budgetStatusProvider(DateRange.thisMonth()));

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
    final tasksAsync = ref.watch(allTodayTasksStreamProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: tasksAsync.when(
        loading: () => const _FlatCard(
          child: SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            ),
          ),
        ),
        error: (_, __) => _FlatCard(
          child: Text(
            'Gagal memuat tugas',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const _FlatCard(
              child: _EmptyState(
                icon: Icons.check_circle_outline_rounded,
                message: 'Tidak ada tugas untuk hari ini.',
              ),
            );
          }
          return _TodayTasksCard(tasks: tasks);
        },
      ),
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  final List<Task> tasks;

  const _TodayTasksCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final inProgress = tasks
        .where((t) => !t.isCompleted && t.status == TaskStatus.inProgress)
        .length;
    final todo = tasks
        .where((t) => !t.isCompleted && t.status == TaskStatus.todo)
        .length;
    final percentage = total > 0 ? completed / total : 0.0;

    return _FlatCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tugas Hari Ini',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                ),
                child: Text(
                  'Lihat Semua',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed/$total Selesai',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                '${(percentage * 100).round()}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TaskStatusDot(label: '$inProgress Diproses'),
              const SizedBox(width: 24),
              _TaskStatusDot(label: '$todo Belum Dikerjakan'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskStatusDot extends StatelessWidget {
  final String label;

  const _TaskStatusDot({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
    );
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

class _SavingsProgressCard extends StatelessWidget {
  final SavingsCategory category;

  const _SavingsProgressCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTarget = category.targetAmount != null && category.targetAmount! > 0;
    final percentage = hasTarget
        ? (category.currentAmount / category.targetAmount!).clamp(0.0, 1.0) as double
        : null;
    final isCompleted = percentage != null && percentage >= 1.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SavingsDetailScreen(category: category)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tercapai',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasTarget)
                Text(
                  '${CurrencyFormatter.format(category.currentAmount)} / ${CurrencyFormatter.format(category.targetAmount!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                )
              else
                Text(
                  CurrencyFormatter.format(category.currentAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.primary : AppColors.secondary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
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