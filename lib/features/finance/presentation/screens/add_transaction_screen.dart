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
  DateTime _date = DateTime.now();
  FinanceCategory? _selectedCategory;
  Wallet? _selectedWallet;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(financeCategoriesProvider(_type));
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type switcher
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
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount
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

            // Category
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
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                            CategoryIcon(
                              icon: cat.icon,
                              size: 18,
                              color: isSelected ? AppColors.primary : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Tombol tambah kategori baru
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddFinanceCategoryScreen(type: _type),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Baru',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Wallet
            Text('Dompet / Rekening', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            walletsAsync.when(
              loading: () =>
              const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => const Text('Gagal memuat dompet'),
              data: (wallets) => Row(
                children: wallets.map((wallet) {
                  final isSelected = _selectedWallet?.id == wallet.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedWallet = wallet),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                            isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            CategoryIcon(
                              icon: wallet.icon,
                              size: 22,
                              color: isSelected ? AppColors.primary : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              wallet.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(
                                  wallet.balance),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Date
            Text('Tanggal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateHelper.formatDate(_date),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Note
            Text('Catatan (opsional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Tambah catatan...',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Save button
            GlowButton(
              label: 'Simpan Transaksi',
              onPressed: _save,
            ),
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
      await AppAlert.show(
        context,
        title: 'Jumlah Tidak Valid',
        message: 'Masukkan jumlah transaksi yang valid.',
      );
      return;
    }
    if (_selectedCategory == null) {
      await AppAlert.show(
        context,
        title: 'Kategori Belum Dipilih',
        message: 'Silakan pilih kategori transaksi.',
      );
      return;
    }
    if (_selectedWallet == null) {
      await AppAlert.show(
        context,
        title: 'Dompet Belum Dipilih',
        message: 'Silakan pilih dompet atau rekening.',
      );
      return;
    }

    final amount = double.parse(rawAmount);
    if (_type == TransactionType.expense) {
      final wallets = ref.read(walletsProvider).value ?? [];
      final wallet = wallets.firstWhere(
        (w) => w.name == _selectedWallet!.name,
        orElse: () => wallets.first,
      );
      if (amount > wallet.balance) {
        await AppAlert.show(
          context,
          title: 'Saldo Tidak Cukup',
          message:
              'Saldo ${_selectedWallet!.name} hanya Rp ${CurrencyFormatter.format(wallet.balance)}. Nominal yang diinput melebihi saldo yang tersedia.',
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
      ..walletName = _selectedWallet!.name
      ..note = _noteController.text.trim()
      ..date = _date;

    await ref
        .read(financeNotifierProvider.notifier)
        .addTransaction(transaction);

    if (mounted) Navigator.of(context).pop();
  }
}

class _ThousandSeparatorFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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