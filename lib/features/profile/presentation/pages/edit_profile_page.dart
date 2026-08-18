import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final formKey = GlobalKey<FormState>();
  final service = ProfileService();

  late final name = TextEditingController(
    text: widget.data['displayName'] ?? '',
  );
  late final bio = TextEditingController(text: widget.data['bio'] ?? '');
  late final phone = TextEditingController(text: widget.data['phone'] ?? '');

  DateTime? selectedBirthday;
  String? photoUrl;
  Uint8List? avatarBytes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedBirthday = _parseBirthday(widget.data['birthDate'] as String?);
    photoUrl = widget.data['photoUrl'] as String?;
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await service.update(
        displayName: name.text,
        bio: bio.text,
        phone: phone.text,
        birthDate: _birthdayStorageValue(selectedBirthday),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile could not be saved')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> changePhoto() async {
    try {
      final result = await service.pickAndUploadAvatar();

      if (result != null && mounted) {
        setState(() {
          photoUrl = result.url;
          avatarBytes = result.bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar upload failed')));
      }
    }
  }

  DateTime? _parseBirthday(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = raw.trim();
    final iso = DateTime.tryParse(normalized);
    if (iso != null) return iso;

    final slashParts = normalized.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);

      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  String _birthdayStorageValue(DateTime? value) {
    if (value == null) return '';

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _birthdayDisplayValue(DateTime? value) {
    if (value == null) return 'Add birthday';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();

    final initial =
        selectedBirthday ?? DateTime(now.year - 18, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select birthday',
      cancelText: 'Cancel',
      confirmText: 'Done',
    );

    if (selected == null || !mounted) return;

    setState(() {
      selectedBirthday = DateTime(selected.year, selected.month, selected.day);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundImage: avatarBytes != null
                      ? MemoryImage(avatarBytes!)
                      : photoUrl == null
                      ? null
                      : NetworkImage(photoUrl!),
                  child: photoUrl == null && avatarBytes == null
                      ? const Icon(Icons.person_rounded, size: 48)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: changePhoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Display name'),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter at least 2 characters'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: bio,
            maxLength: 120,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickBirthday,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birthday',
                suffixIcon: Icon(Icons.calendar_month_rounded),
              ),
              child: Text(
                _birthdayDisplayValue(selectedBirthday),
                style: TextStyle(
                  color: selectedBirthday == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (selectedBirthday != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => selectedBirthday = null);
                },
                child: const Text('Clear birthday'),
              ),
            ),
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: saving ? null : save,
              child: saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save changes'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your public profile is visible to other VonoTalky users.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
