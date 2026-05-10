import 'dart:io';
import 'package:bloom/models/plant.dart';
import 'package:bloom/models/plant_log.dart';
import 'package:bloom/providers/logs_provider.dart';
import 'package:bloom/providers/plants_provider.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:bloom/widgets/health_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  final Plant plant;
  const AddLogScreen({super.key, required this.plant});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  PlantHealth _health = PlantHealth.good;
  bool _watered = false;
  bool _fertilized = false;
  bool _repotted = false;
  final _notesCtrl = TextEditingController();
  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.pop(ctx, await picker.pickImage(source: ImageSource.camera));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(ctx, await picker.pickImage(source: ImageSource.gallery));
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() => _imagePath = result.path);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final log = PlantLog(
      id: const Uuid().v4(),
      plantId: widget.plant.id,
      date: DateTime.now(),
      health: _health,
      watered: _watered,
      fertilized: _fertilized,
      repotted: _repotted,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      imagePath: _imagePath,
    );
    await ref.read(logsProvider(widget.plant.id).notifier).addLog(log);
    ref.read(plantsProvider.notifier).refresh();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log ${widget.plant.displayName}'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'How does it look? 🌿',
            child: HealthSelector(selected: _health, onChanged: (h) => setState(() => _health = h)),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'What did you do today?',
            child: Column(
              children: [
                _ToggleTile(
                  emoji: '💧',
                  label: 'Watered',
                  value: _watered,
                  onChanged: (v) => setState(() => _watered = v),
                ),
                _ToggleTile(
                  emoji: '🌱',
                  label: 'Fertilized',
                  value: _fertilized,
                  onChanged: (v) => setState(() => _fertilized = v),
                ),
                _ToggleTile(
                  emoji: '🪣',
                  label: 'Repotted',
                  value: _repotted,
                  onChanged: (v) => setState(() => _repotted = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Notes',
            child: TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'How\'s your plant doing? Any observations...',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Photo',
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📸', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add a photo',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColors.primary : Colors.grey.shade200,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                color: value ? AppColors.textPrimary : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            if (value)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
