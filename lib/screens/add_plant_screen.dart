import 'dart:io';
import 'package:bloom/data/plant_database.dart';
import 'package:bloom/models/plant.dart';
import 'package:bloom/providers/plants_provider.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddPlantScreen extends ConsumerStatefulWidget {
  final Plant? existing;
  const AddPlantScreen({super.key, this.existing});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  PlantType _type = PlantType.indoor;
  String? _imagePath;
  List<String> _careTips = [];
  String? _wateringFreq;
  String? _sunlight;
  String? _difficulty;
  int? _perenualId;
  bool _saving = false;

  bool _notifEnabled = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);
  List<int> _notifDays = [1, 3, 5];

  List<LocalPlant> _searchResults = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _nameCtrl.text = p.name;
      _nicknameCtrl.text = p.nickname ?? '';
      _speciesCtrl.text = p.species ?? '';
      _notesCtrl.text = p.notes ?? '';
      _type = p.type;
      _imagePath = p.imagePath;
      _careTips = List.from(p.careTips);
      _wateringFreq = p.wateringFrequency;
      _sunlight = p.sunlight;
      _difficulty = p.difficulty;
      _perenualId = p.perenualId;
      _notifEnabled = p.notificationConfig.enabled;
      _notifTime = TimeOfDay(hour: p.notificationConfig.hour, minute: p.notificationConfig.minute);
      _notifDays = List.from(p.notificationConfig.daysOfWeek);
    }
    _searchResults = kPlantDatabase;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _speciesCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyLocalPlant(LocalPlant p) {
    setState(() {
      if (_nameCtrl.text.isEmpty) _nameCtrl.text = p.name;
      _speciesCtrl.text = p.species;
      _type = p.type;
      _careTips = List.from(p.careTips);
      _wateringFreq = p.wateringFrequency;
      _sunlight = p.sunlight;
      _difficulty = p.difficulty;
      _showSearch = false;
      _searchCtrl.clear();
    });
  }

  void _onSearch(String q) {
    final ql = q.toLowerCase();
    setState(() {
      _searchResults = kPlantDatabase
          .where((p) =>
              p.name.toLowerCase().contains(ql) ||
              p.species.toLowerCase().contains(ql))
          .toList();
    });
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
    if (result != null) setState(() => _imagePath = result.path);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _notifTime);
    if (picked != null) setState(() => _notifTime = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plant name 🌱')),
      );
      return;
    }
    setState(() => _saving = true);

    final config = NotificationConfig(
      enabled: _notifEnabled,
      hour: _notifTime.hour,
      minute: _notifTime.minute,
      daysOfWeek: _notifDays,
    );

    final plant = Plant(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
      type: _type,
      species: _speciesCtrl.text.trim().isEmpty ? null : _speciesCtrl.text.trim(),
      imagePath: _imagePath,
      dateAdded: widget.existing?.dateAdded ?? DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      perenualId: _perenualId,
      careTips: _careTips,
      wateringFrequency: _wateringFreq,
      sunlight: _sunlight,
      difficulty: _difficulty,
      notificationConfig: config,
    );

    if (widget.existing != null) {
      await ref.read(plantsProvider.notifier).updatePlant(plant);
    } else {
      await ref.read(plantsProvider.notifier).addPlant(plant);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Plant 🌱' : 'Edit Plant'),
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
          // Plant search/autofill
          _SectionLabel('Quick add from database 🔍'),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _onSearch(v);
              setState(() => _showSearch = v.isNotEmpty);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              hintText: 'Search plants to auto-fill info...',
            ),
          ),
          if (_showSearch) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.take(6).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _searchResults[i];
                  return ListTile(
                    leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.species, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.type == PlantType.indoor
                            ? Colors.blue.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.type == PlantType.indoor ? '🏠' : '☀️',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onTap: () => _applyLocalPlant(p),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Plant photo
          GestureDetector(
            onTap: _pickImage,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
                child: _imagePath != null
                    ? ClipOval(child: Image.file(File(_imagePath!), fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📸', style: TextStyle(fontSize: 30)),
                          SizedBox(height: 4),
                          Text('Add photo', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Basic info
          _SectionLabel('Plant Details'),
          const SizedBox(height: 10),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Plant name *')),
          const SizedBox(height: 10),
          TextField(controller: _nicknameCtrl, decoration: const InputDecoration(labelText: 'Nickname (optional)')),
          const SizedBox(height: 10),
          TextField(controller: _speciesCtrl, decoration: const InputDecoration(labelText: 'Species (optional)')),
          const SizedBox(height: 16),

          // Type selector
          _SectionLabel('Plant type'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _TypeButton(label: '🏠 Indoor', selected: _type == PlantType.indoor, onTap: () => setState(() => _type = PlantType.indoor))),
              const SizedBox(width: 12),
              Expanded(child: _TypeButton(label: '☀️ Outdoor', selected: _type == PlantType.outdoor, onTap: () => setState(() => _type = PlantType.outdoor))),
            ],
          ),
          const SizedBox(height: 16),

          // Care info (read-only if auto-filled)
          if (_wateringFreq != null || _sunlight != null || _difficulty != null) ...[
            _SectionLabel('Care Info'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  if (_wateringFreq != null) _InfoRow('💧', 'Watering', _wateringFreq!),
                  if (_sunlight != null) _InfoRow('☀️', 'Sunlight', _sunlight!),
                  if (_difficulty != null) _InfoRow('⭐', 'Difficulty', _difficulty!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          _SectionLabel('Notes'),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Where did you get it? Special memories...'),
          ),
          const SizedBox(height: 20),

          // Notification settings
          _SectionLabel('Reminder Notifications 🔔'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable reminders'),
                  value: _notifEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _notifEnabled = v),
                ),
                if (_notifEnabled) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    title: const Text('Reminder time'),
                    trailing: Text(
                      _notifTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 8),
                  Text('Remind me on:', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  _DayPicker(selected: _notifDays, onChanged: (days) => setState(() => _notifDays = days)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.textPrimary : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _InfoRow(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
          Expanded(
            child: Text(value, style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _DayPicker({required this.selected, required this.onChanged});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(selected);
            if (isSelected) {
              if (newDays.length > 1) newDays.remove(day);
            } else {
              newDays.add(day);
            }
            onChanged(newDays);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
