import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/theme/app_theme.dart';
import 'core/widgets/radial_add_button.dart';
import 'data/providers/settings_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/notes/presentation/screens/notes_screen.dart';
import 'features/finance/presentation/screens/finance_screen.dart';
import 'features/tasks/presentation/screens/tasks_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeDateFormatting('id');
  runApp(const ProviderScope(child: LifeHubApp()));
}

class LifeHubApp extends ConsumerWidget {
  const LifeHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'LifeHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    NotesScreen(),
    FinanceScreen(),
    TasksScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.home_outlined, Icons.home, 'Beranda'),
    _NavItem(Icons.sticky_note_2_outlined, Icons.sticky_note_2, 'Catatan'),
    _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Keuangan'),
    _NavItem(Icons.task_alt_outlined, Icons.task_alt, 'Tugas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          _CustomNavBar(
            currentIndex: _currentIndex,
            items: _navItems,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
          Positioned(
            top: -28,
            child: RadialAddButton(currentIndex: _currentIndex),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _CustomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.navigationBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final fgColor = isSelected
                ? (theme.brightness == Brightness.dark ? AppColors.white : AppColors.black)
                : AppColors.gray500;

            final bool isNearButton = index == 1 || index == 2;
            final double hMargin = isNearButton ? 14.0 : 6.0;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (theme.brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFE8E8E8))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 22,
                        color: fgColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: fgColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
