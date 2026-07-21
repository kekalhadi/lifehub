import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late UserProfile _profile;
  String? _localAvatarPath;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _hasChanges = true);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked != null) {
      final appPath = await ref.read(profileNotifierProvider.notifier).copyAvatarToAppDir(picked.path);
      if (appPath != null) {
        setState(() {
          _localAvatarPath = appPath;
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _save() async {
    _profile.name = _nameController.text.trim();
    _profile.bio = _bioController.text.trim();
    if (_localAvatarPath != null) {
      _profile.avatarPath = _localAvatarPath;
    }
    await ref.read(profileNotifierProvider.notifier).updateProfile(_profile);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileStreamProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(child: Text('Gagal memuat profil: $e')),
      ),
      data: (profile) {
        if (!_isEditing) {
          _profile = profile ?? UserProfile();
          _nameController.text = _profile.name;
          _bioController.text = _profile.bio;
          _localAvatarPath = _profile.avatarPath;
          _hasChanges = false;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Profil'),
            actions: [
              if (!_isEditing)
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = true);
                  },
                  child: const Text('Edit'),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _profile.name;
                          _bioController.text = _profile.bio;
                          _localAvatarPath = _profile.avatarPath;
                        });
                      },
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: _hasChanges ? _save : null,
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 2,
                            ),
                          ),
                          child: _localAvatarPath != null && File(_localAvatarPath!).existsSync()
                              ? ClipOval(
                                  child: Image.file(
                                    File(_localAvatarPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 48,
                                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
                                ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: theme.colorScheme.primary == AppColors.white
                                    ? AppColors.black
                                    : AppColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Text(
                    'Ketuk untuk ganti foto',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 32),
                _ProfileField(
                  label: 'Nama',
                  controller: _nameController,
                  enabled: _isEditing,
                  onChanged: _onChanged,
                  hint: 'Masukkan nama',
                ),
                const SizedBox(height: 16),
                _ProfileField(
                  label: 'Bio',
                  controller: _bioController,
                  enabled: _isEditing,
                  onChanged: _onChanged,
                  hint: 'Tulis bio singkat...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final String hint;
  final int maxLines;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: (_) => onChanged(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled ? null : theme.textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
