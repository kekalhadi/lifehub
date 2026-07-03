import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';

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
                    label: '📥 Pemasukan',
                    isSelected: _type == TransactionType.income,
                    color: AppColors.income,
                    onTap: () => setState(() {
                      _type = TransactionType.income;
                      _selectedCategory = null;
                    }),
                  ),
                  _TypeButton(
                    label: '📤 Pengeluaran',
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                children: categories.map((cat) {
                  final isSelected = _selectedCategory?.id == cat.id;
                  final catColor = ColorHelper.fromHex(cat.colorHex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withOpacity(0.15)
                            : theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? catColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? catColor : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                  final walletColor =
                  ColorHelper.fromHex(wallet.colorHex);
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
                              ? walletColor.withOpacity(0.15)
                              : theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                            isSelected ? walletColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(wallet.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              wallet.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? walletColor : null,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                ),
                child: Text(
                  'Simpan Transaksi',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
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
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || amountText == '0') {
      _showSnack('Masukkan jumlah transaksi');
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('Pilih kategori transaksi');
      return;
    }
    if (_selectedWallet == null) {
      _showSnack('Pilih dompet/rekening');
      return;
    }

    final transaction = Transaction()
      ..amount = double.parse(amountText)
      ..type = _type
      ..categoryName = _selectedCategory!.name
      ..categoryIcon = _selectedCategory!.icon
      ..categoryColorHex = _selectedCategory!.colorHex
      ..walletName = _selectedWallet!.name
      ..note = _noteController.text.trim()
      ..date = _date;

    await ref
        .read(financeNotifierProvider.notifier)
        .addTransaction(transaction);

    if (mounted) Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
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
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}