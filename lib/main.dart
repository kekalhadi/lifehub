import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tugas',
          ),
        ],
      ),
    );
  }
}