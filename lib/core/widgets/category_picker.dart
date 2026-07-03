import 'package:flutter/material.dart';
import '../../data/models/note_model.dart';
import '../theme/app_theme.dart';

class CategoryPicker extends StatelessWidget {
  final List<NoteCategoryCustom> categories;
  final NoteCategoryCustom? selectedCategory;
  final ValueChanged<NoteCategoryCustom?> onCategorySelected;
  final VoidCallback onAddNewCategory;
  final bool enabled;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddNewCategory,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((cat) {
          final isSelected = selectedCategory?.id == cat.id;

          return GestureDetector(
            onTap: enabled ? () => onCategorySelected(cat) : null,
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
                  Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  if (cat.isDefault) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        if (enabled)
          GestureDetector(
            onTap: onAddNewCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.5),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 18,
                    color: AppColors.primary,
                  ),
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
    );
  }
}
