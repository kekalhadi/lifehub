import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note_model.dart';
import '../../data/providers/notes_provider.dart';
import '../theme/app_theme.dart';

/// Widget untuk input tag dengan fitur autocomplete
/// Menampilkan suggestion tag yang sudah ada berdasarkan input user
class TagAutocompleteField extends ConsumerStatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final bool enabled;

  const TagAutocompleteField({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.enabled = true,
  });

  @override
  ConsumerState<TagAutocompleteField> createState() => _TagAutocompleteFieldState();
}

class _TagAutocompleteFieldState extends ConsumerState<TagAutocompleteField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<NoteTag> _filteredTags = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showSuggestions) {
      setState(() => _showSuggestions = false);
    }
  }

  void _onTextChanged(String value) {
    final query = value.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredTags = [];
        _showSuggestions = false;
      });
      return;
    }

    // Get all tags and filter
    ref.read(allTagsProvider).when(
      data: (tags) {
        final filtered = tags
          .where((t) =>
              t.name.contains(query) && !widget.selectedTags.contains(t.name))
          .take(5)
          .toList();

        setState(() {
          _filteredTags = filtered;
          _showSuggestions = filtered.isNotEmpty;
        });
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _selectTag(NoteTag tag) {
    if (!widget.selectedTags.contains(tag.name)) {
      widget.onTagsChanged([...widget.selectedTags, tag.name]);
      // Increment tag usage
      ref.read(notesNotifierProvider.notifier).incrementTagUsage(tag.name);
    }
    _controller.clear();
    setState(() {
      _filteredTags = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  void _addNewTag(String tagName) {
    final cleaned = tagName.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    if (widget.selectedTags.contains(cleaned)) {
      _controller.clear();
      return;
    }

    // Add to NoteTag collection
    ref.read(notesNotifierProvider.notifier).addTag(cleaned);
    ref.read(notesNotifierProvider.notifier).incrementTagUsage(cleaned);

    widget.onTagsChanged([...widget.selectedTags, cleaned]);
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.selectedTags.where((t) => t != tag).toList());
    // Decrement usage
    ref.read(notesNotifierProvider.notifier).decrementTagUsage(tag);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected tags display
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: widget.enabled ? () => _removeTag(tag) : null,
                backgroundColor: AppColors.primaryLight,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: _onTextChanged,
          onSubmitted: widget.enabled ? _addNewTag : null,
          decoration: InputDecoration(
            hintText: 'Ketik tag untuk cari atau tambah baru...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            prefixIcon: const Icon(Icons.tag_outlined),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _filteredTags = [];
                        _showSuggestions = false;
                      });
                    },
                  )
                : null,
          ),
        ),

        // Suggestions overlay
        if (_showSuggestions && _filteredTags.isNotEmpty) ...[
          const SizedBox(height: 4),
          _TagSuggestionsOverlay(
            tags: _filteredTags,
            onSelectTag: _selectTag,
            onAddNew: () => _addNewTag(_controller.text),
          ),
        ],
      ],
    );
  }
}

/// Overlay suggestions widget
class _TagSuggestionsOverlay extends StatelessWidget {
  final List<NoteTag> tags;
  final ValueChanged<NoteTag> onSelectTag;
  final VoidCallback onAddNew;

  const _TagSuggestionsOverlay({
    required this.tags,
    required this.onSelectTag,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Existing tags suggestions
          ...tags.map((tag) => _SuggestionTile(
                label: '#${tag.name}',
                onTap: () => onSelectTag(tag),
                trailing: Text(
                  '${tag.usageCount}x',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )),

          // Divider and "Add as new" option
          const Divider(height: 1),
          _SuggestionTile(
            label: 'Tambah sebagai tag baru',
            onTap: onAddNew,
            icon: Icons.add_circle_outline,
            iconColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Single suggestion tile
class _SuggestionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const _SuggestionTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

