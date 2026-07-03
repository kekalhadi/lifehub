import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note_model.dart';
import '../../core/utils/helpers.dart';
import '../theme/app_theme.dart';

/// Widget untuk memilih category dari list atau add new category
/// Mendukung pemilihan category yang sudah ada atau navigate ke add category screen
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
        // Category chips
        ...categories.map((cat) {
          final isSelected = selectedCategory?.id == cat.id;
          final color = ColorHelper.fromHex(cat.colorHex);

          return GestureDetector(
            onTap: enabled ? () => onCategorySelected(cat) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color indicator dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : null,
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

        // Add new category button
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

// Preset color palette untuk category picker
const List<Color> kCategoryColorPresets = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFFEC4899), // Pink
  Color(0xFF14B8A6), // Teal
  Color(0xFF8B5CF6), // Violet
  Color(0xFFF97316), // Orange
  Color(0xFF06B6D4), // Cyan
  Color(0xFF84CC16), // Lime
  Color(0xFF64748B), // Slate
  Color(0xFFEF4444), // Red
  Color(0xFF3B82F6), // Blue
];

/// Color picker widget untuk memilih warna dari preset palette
class CategoryColorPicker extends StatelessWidget {
  final String selectedColorHex;
  final ValueChanged<String> onColorSelected;

  const CategoryColorPicker({
    super.key,
    required this.selectedColorHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kCategoryColorPresets.map((color) {
        final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
        final isSelected = colorHex == selectedColorHex;

        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
