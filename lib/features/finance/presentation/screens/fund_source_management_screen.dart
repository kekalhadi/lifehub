import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';
import 'add_finance_category_screen.dart';

class FundSourceManagementScreen extends ConsumerWidget {
  const FundSourceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sourcesAsync = ref.watch(fundSourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumber Dana'),
      ),
      body: sourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat')),
        data: (sources) {
          if (sources.isEmpty) {
            return EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              message: 'Belum ada sumber dana.\nTambahkan sumber dana pertama Anda.',
              actionLabel: 'Tambah Sumber Dana',
              onAction: () => _addFundSource(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _FundSourceTile(
              source: sources[i],
              onEdit: () => _addFundSource(context, source: sources[i]),
              onDelete: () => _confirmDelete(context, ref, sources[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFundSource(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addFundSource(BuildContext context, {Wallet? source}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AddFundSourceScreen(source: source),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Wallet source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Sumber Dana?'),
        content: Text(
          '"${source.name}" akan dihapus permanen. Transaksi lama tetap menampilkan nama sumber dana sebagai catatan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(financeNotifierProvider.notifier).deleteFundSource(source.id);
    }
  }
}

class _FundSourceTile extends StatelessWidget {
  final Wallet source;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FundSourceTile({
    required this.source,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBox(
            icon: tryParseIconData(source.icon) ?? Icons.account_balance_wallet,
            size: 44,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(source.name, style: theme.textTheme.labelLarge),
                Text(
                  CurrencyFormatter.format(source.balance),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit'),
                        onTap: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_outline, color: AppColors.danger),
                        title: Text('Hapus', style: TextStyle(color: AppColors.danger)),
                        onTap: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                      ),
                    ],
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

class _AddFundSourceScreen extends ConsumerStatefulWidget {
  final Wallet? source;

  const _AddFundSourceScreen({this.source});

  @override
  ConsumerState<_AddFundSourceScreen> createState() => _AddFundSourceScreenState();
}

class _AddFundSourceScreenState extends ConsumerState<_AddFundSourceScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'account_balance_wallet';
  final _balanceController = TextEditingController();

  bool get _isEditing => widget.source != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.source!.name;
      _selectedIcon = widget.source!.icon;
      _balanceController.text = widget.source!.balance.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sumber Dana' : 'Tambah Sumber Dana'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                ref.read(financeNotifierProvider.notifier).deleteFundSource(widget.source!.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Sumber Dana', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'mis. BCA, GoPay, Tunai'),
            ),
            const SizedBox(height: 20),
            Text('Ikon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            IconPickerGrid(
              selectedIcon: _selectedIcon,
              onIconSelected: (key) => setState(() => _selectedIcon = key),
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text('Saldo Awal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 32),
            GlowButton(
              label: _isEditing ? 'Simpan' : 'Tambah',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await AppAlert.show(context, title: 'Nama Kosong', message: 'Masukkan nama sumber dana.');
      return;
    }

    final balance = double.tryParse(_balanceController.text.replaceAll('.', '')) ?? 0;
    final fundSource = Wallet()
      ..name = name
      ..icon = _selectedIcon
      ..balance = balance;

    if (_isEditing) {
      fundSource.id = widget.source!.id;
    }

    await ref.read(financeNotifierProvider.notifier).saveFundSource(fundSource);
    if (mounted) Navigator.of(context).pop();
  }
}
