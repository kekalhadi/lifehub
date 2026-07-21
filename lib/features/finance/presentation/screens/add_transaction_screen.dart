import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';
import '../../../../data/providers/savings_provider.dart';
import 'add_finance_category_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _allocationController = TextEditingController();
  DateTime _date = DateTime.now();
  FinanceCategory? _selectedCategory;
  Wallet? _selectedFundSource;
  String _sourceType = 'balance';
  SavingsCategory? _selectedSavingsCategory;
  bool _allocateToSavings = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _allocationController.dispose();
    super.dispose();
  }

  double get _rawAmount {
    final raw = _amountController.text.replaceAll('.', '');
    return double.tryParse(raw) ?? 0;
  }

  double get _allocationAmount {
    final raw = _allocationController.text.replaceAll('.', '');
    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(financeCategoriesProvider(_type));
    final fundSourcesAsync = ref.watch(fundSourcesProvider);
    final savingsCatsAsync = ref.watch(savingsCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TypeButton(
                    icon: Icons.south_west,
                    label: 'Pemasukan',
                    isSelected: _type == TransactionType.income,
                    color: AppColors.income,
                    onTap: () => setState(() {
                      _type = TransactionType.income;
                      _selectedCategory = null;
                      _sourceType = 'balance';
                      _allocateToSavings = false;
                      _selectedSavingsCategory = null;
                      _allocationController.clear();
                    }),
                  ),
                  _TypeButton(
                    icon: Icons.north_east,
                    label: 'Pengeluaran',
                    isSelected: _type == TransactionType.expense,
                    color: AppColors.expense,
                    onTap: () => setState(() {
                      _type = TransactionType.expense;
                      _selectedCategory = null;
                      _sourceType = 'balance';
                      _selectedSavingsCategory = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Jumlah', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandSeparatorFormatter(),
              ],
              style: theme.textTheme.displayMedium?.copyWith(
                color: _type == TransactionType.income
                    ? AppColors.income
                    : AppColors.expense,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
                hintText: '0',
              ),
            ),
            const SizedBox(height: 20),

            Text('Kategori', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => const Text('Gagal memuat kategori'),
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...categories.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryIcon(icon: cat.icon, size: 18, color: isSelected ? AppColors.primary : null),
                            const SizedBox(width: 6),
                            Text(cat.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.primary : null,
                                )),
                          ],
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddFinanceCategoryScreen(type: _type)),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Baru',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Sumber Dana', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            fundSourcesAsync.when(
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => const Text('Gagal memuat sumber dana'),
              data: (sources) {
                if (sources.isEmpty) {
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _FundSourceManagementNav(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Tambah Sumber Dana',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...sources.map((s) {
                      final isSelected = _selectedFundSource?.id == s.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFundSource = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.15)
                                : theme.inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent, width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryIcon(icon: s.icon, size: 18, color: isSelected ? AppColors.primary : null),
                              const SizedBox(width: 6),
                              Text(s.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? AppColors.primary : null,
                                  )),
                              const SizedBox(width: 4),
                              Text(CurrencyFormatter.formatCompact(s.balance),
                                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const _FundSourceManagementNav()),
                        );
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('Baru',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // === EXPENSE: Source type (Saldo / Tabungan) ===
            if (_type == TransactionType.expense) ...[
              Text('Tipe Dana', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _TypeButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Saldo',
                      isSelected: _sourceType == 'balance',
                      color: AppColors.gray400,
                      onTap: () => setState(() {
                        _sourceType = 'balance';
                        _selectedSavingsCategory = null;
                      }),
                    ),
                    _TypeButton(
                      icon: Icons.savings_outlined,
                      label: 'Tabungan',
                      isSelected: _sourceType == 'savings',
                      color: AppColors.primary,
                      onTap: () => setState(() => _sourceType = 'savings'),
                    ),
                  ],
                ),
              ),
              if (_sourceType == 'savings') ...[
                const SizedBox(height: 16),
                Text('Kategori Tabungan', style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                savingsCatsAsync.when(
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (_, __) => const Text('Gagal memuat'),
                  data: (cats) {
                    if (cats.isEmpty) {
                      return Text('Belum ada kategori tabungan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger, fontSize: 12));
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.map((cat) {
                        final isSelected = _selectedSavingsCategory?.id == cat.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSavingsCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : theme.inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent, width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CategoryIcon(icon: cat.icon, size: 18, color: isSelected ? AppColors.primary : null),
                                const SizedBox(width: 6),
                                Text(cat.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? AppColors.primary : null,
                                    )),
                                const SizedBox(width: 4),
                                Text(CurrencyFormatter.formatCompact(cat.currentAmount),
                                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],

            // === INCOME: Savings allocation toggle ===
            if (_type == TransactionType.income) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() {
                  _allocateToSavings = !_allocateToSavings;
                  if (!_allocateToSavings) {
                    _selectedSavingsCategory = null;
                    _allocationController.clear();
                  }
                }),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _allocateToSavings ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: _allocateToSavings ? AppColors.primary : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: _allocateToSavings
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text('Alokasikan ke Tabungan',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (_allocateToSavings) ...[
                const SizedBox(height: 16),
                Text('Kategori Tabungan', style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                savingsCatsAsync.when(
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (_, __) => const Text('Gagal memuat'),
                  data: (cats) {
                    if (cats.isEmpty) {
                      return Text('Belum ada kategori tabungan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger, fontSize: 12));
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.map((cat) {
                        final isSelected = _selectedSavingsCategory?.id == cat.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSavingsCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : theme.inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent, width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CategoryIcon(icon: cat.icon, size: 18, color: isSelected ? AppColors.primary : null),
                                const SizedBox(width: 6),
                                Text(cat.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? AppColors.primary : null,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Nominal Alokasi', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _allocationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandSeparatorFormatter(),
                  ],
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: theme.textTheme.titleLarge?.copyWith(color: theme.textTheme.bodyMedium?.color),
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
            ],

            Text('Tanggal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(DateHelper.formatDate(_date), style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Catatan (opsional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'Tambah catatan...'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            GlowButton(label: 'Simpan Transaksi', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final rawAmount = _amountController.text.replaceAll('.', '');
    if (rawAmount.isEmpty || rawAmount == '0') {
      await AppAlert.show(context, title: 'Jumlah Tidak Valid', message: 'Masukkan jumlah transaksi yang valid.');
      return;
    }
    if (_selectedCategory == null) {
      await AppAlert.show(context, title: 'Kategori Belum Dipilih', message: 'Silakan pilih kategori transaksi.');
      return;
    }
    if (_selectedFundSource == null) {
      await AppAlert.show(context, title: 'Sumber Dana Belum Dipilih', message: 'Silakan pilih sumber dana.');
      return;
    }

    final amount = _rawAmount;

    if (_type == TransactionType.expense) {
      if (_sourceType == 'balance') {
        if (amount > _selectedFundSource!.balance) {
          await AppAlert.show(
            context,
            title: 'Saldo Tidak Cukup',
            message: 'Saldo ${_selectedFundSource!.name} hanya Rp ${CurrencyFormatter.format(_selectedFundSource!.balance)}.',
            type: AppAlertType.warning,
          );
          return;
        }
      } else {
        if (_selectedSavingsCategory == null) {
          await AppAlert.show(context, title: 'Tabungan Belum Dipilih', message: 'Pilih kategori tabungan untuk penarikan.');
          return;
        }
        if (amount > _selectedSavingsCategory!.currentAmount) {
          await AppAlert.show(
            context,
            title: 'Saldo Tabungan Tidak Cukup',
            message: 'Saldo "${_selectedSavingsCategory!.name}" hanya Rp ${CurrencyFormatter.format(_selectedSavingsCategory!.currentAmount)}.',
            type: AppAlertType.warning,
          );
          return;
        }
      }
    }

    if (_type == TransactionType.income && _allocateToSavings) {
      if (_selectedSavingsCategory == null) {
        await AppAlert.show(context, title: 'Tabungan Belum Dipilih', message: 'Pilih kategori tabungan untuk alokasi.');
        return;
      }
      if (_allocationAmount <= 0) {
        await AppAlert.show(context, title: 'Alokasi Tidak Valid', message: 'Masukkan nominal alokasi yang valid.');
        return;
      }
      if (_allocationAmount > amount) {
        await AppAlert.show(
          context,
          title: 'Alokasi Melebihi Pemasukan',
          message: 'Nominal alokasi tidak boleh melebihi nominal pemasukan.',
          type: AppAlertType.warning,
        );
        return;
      }
    }

    final transaction = Transaction()
      ..amount = amount
      ..type = _type
      ..categoryName = _selectedCategory!.name
      ..categoryIcon = _selectedCategory!.icon
      ..walletName = _selectedFundSource!.name
      ..fundSourceId = _selectedFundSource!.id
      ..fundSourceName = _selectedFundSource!.name
      ..sourceType = _sourceType
      ..note = _noteController.text.trim()
      ..date = _date;

    if (_type == TransactionType.income && _allocateToSavings && _selectedSavingsCategory != null) {
      transaction.savingsCategoryId = _selectedSavingsCategory!.id;
      transaction.savingsCategoryName = _selectedSavingsCategory!.name;
      transaction.savingsAllocationAmount = _allocationAmount;
    }

    if (_type == TransactionType.expense && _sourceType == 'savings' && _selectedSavingsCategory != null) {
      transaction.savingsCategoryId = _selectedSavingsCategory!.id;
      transaction.savingsCategoryName = _selectedSavingsCategory!.name;
    }

    await ref.read(financeNotifierProvider.notifier).addTransaction(transaction);
    if (mounted) Navigator.of(context).pop();
  }
}

class _FundSourceManagementNav extends StatelessWidget {
  const _FundSourceManagementNav();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Sumber Dana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _QuickAddFundSourceScreen()),
            ),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final sourcesAsync = ref.watch(fundSourcesProvider);
          return sourcesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (sources) {
              if (sources.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.gray500),
                      const SizedBox(height: 12),
                      Text('Belum ada sumber dana', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sources.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final s = sources[i];
                  return Dismissible(
                    key: ValueKey(s.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref.read(financeNotifierProvider.notifier).deleteFundSource(s.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                    child: ListTile(
                      leading: CategoryIcon(icon: s.icon, size: 22),
                      title: Text(s.name),
                      subtitle: Text(CurrencyFormatter.format(s.balance)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => _QuickAddFundSourceScreen(source: s)),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _QuickAddFundSourceScreen extends ConsumerStatefulWidget {
  final Wallet? source;
  const _QuickAddFundSourceScreen({this.source});

  @override
  ConsumerState<_QuickAddFundSourceScreen> createState() => _QuickAddFundSourceScreenState();
}

class _QuickAddFundSourceScreenState extends ConsumerState<_QuickAddFundSourceScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'account_balance_wallet';
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.source != null) {
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
      appBar: AppBar(title: Text(widget.source != null ? 'Edit Sumber Dana' : 'Tambah Sumber Dana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'mis. BCA, GoPay')),
            const SizedBox(height: 20),
            Text('Ikon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            IconPickerGrid(selectedIcon: _selectedIcon, onIconSelected: (k) => setState(() => _selectedIcon = k), color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Saldo Awal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
            ),
            const SizedBox(height: 32),
            GlowButton(label: 'Simpan', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    final fs = Wallet()
      ..name = _nameController.text.trim()
      ..icon = _selectedIcon
      ..balance = double.tryParse(_balanceController.text.replaceAll('.', '')) ?? 0;
    if (widget.source != null) fs.id = widget.source!.id;
    await ref.read(financeNotifierProvider.notifier).saveFundSource(fs);
    if (mounted) Navigator.of(context).pop();
  }
}

class _ThousandSeparatorFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('.', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final num = int.tryParse(raw) ?? 0;
    final formatted = _formatter.format(num);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
