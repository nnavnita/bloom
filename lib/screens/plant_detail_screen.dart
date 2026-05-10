import 'dart:io';
import 'package:bloom/models/plant.dart';
import 'package:bloom/models/plant_log.dart';
import 'package:bloom/providers/logs_provider.dart';
import 'package:bloom/providers/plants_provider.dart';
import 'package:bloom/screens/add_log_screen.dart';
import 'package:bloom/screens/add_plant_screen.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:bloom/widgets/health_indicator.dart';
import 'package:bloom/widgets/log_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PlantDetailScreen extends ConsumerWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider(plant.id));
    final streak = StorageService.getLogStreak(plant.id);
    final latestHealth = StorageService.getLatestHealth(plant.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _PlantAppBar(plant: plant, ref: ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(plant: plant, streak: streak, latestHealth: latestHealth),
                  if (plant.careTips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CareTipsCard(plant: plant),
                  ],
                  const SizedBox(height: 16),
                  if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                    _NotesCard(notes: plant.notes!),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Journal', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${logs.length} ${logs.length == 1 ? "entry" : "entries"}',
                        style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (logs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No entries yet!\nTap + to log your first observation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(color: Colors.grey.shade500, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => LogEntryCard(
                  log: logs[i],
                  onDelete: () => _confirmDelete(ctx, ref, logs[i]),
                ),
                childCount: logs.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddLogScreen(plant: plant)),
          );
          if (result == true) {
            // ignore: unused_result
            ref.refresh(logsProvider(plant.id));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Log entry'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, PlantLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(logsProvider(log.plantId).notifier).deleteLog(log.id);
    }
  }
}

class _PlantAppBar extends StatelessWidget {
  final Plant plant;
  final WidgetRef ref;

  const _PlantAppBar({required this.plant, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => AddPlantScreen(existing: plant)),
            );
            if (result == true) ref.read(plantsProvider.notifier).refresh();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDeletePlant(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: plant.imagePath != null
            ? Image.file(File(plant.imagePath!), fit: BoxFit.cover)
            : Container(
                color: plant.type == PlantType.indoor
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.08),
                child: Center(
                  child: Text(
                    plant.type == PlantType.indoor ? '🪴' : '🌿',
                    style: const TextStyle(fontSize: 90),
                  ),
                ),
              ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant.displayName,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: plant.imagePath != null ? Colors.white : AppColors.textPrimary,
                shadows: plant.imagePath != null
                    ? [const Shadow(color: Colors.black45, blurRadius: 6)]
                    : [],
              ),
            ),
            if (plant.species != null)
              Text(
                plant.species!,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: plant.imagePath != null ? Colors.white70 : Colors.grey.shade500,
                  shadows: plant.imagePath != null
                      ? [const Shadow(color: Colors.black45, blurRadius: 6)]
                      : [],
                ),
              ),
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  Future<void> _confirmDeletePlant(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete plant?'),
        content: Text('This will delete ${plant.displayName} and all its journal entries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(plantsProvider.notifier).deletePlant(plant.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _StatsRow extends StatelessWidget {
  final Plant plant;
  final int streak;
  final PlantHealth? latestHealth;

  const _StatsRow({required this.plant, required this.streak, this.latestHealth});

  @override
  Widget build(BuildContext context) {
    final lastWatered = StorageService.getLastWatered(plant.id);
    return Row(
      children: [
        _StatChip(
          emoji: plant.type == PlantType.indoor ? '🏠' : '☀️',
          label: plant.type == PlantType.indoor ? 'Indoor' : 'Outdoor',
          color: plant.type == PlantType.indoor ? AppColors.indoor : AppColors.outdoor,
        ),
        const SizedBox(width: 8),
        if (streak > 0)
          _StatChip(emoji: '🔥', label: '$streak day streak', color: Colors.orange),
        if (latestHealth != null) ...[
          const SizedBox(width: 8),
          HealthIndicator(health: latestHealth!, compact: true),
        ],
        const Spacer(),
        if (lastWatered != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('💧 Last watered', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                DateFormat('MMM d').format(lastWatered),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _StatChip({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareTipsCard extends StatelessWidget {
  final Plant plant;
  const _CareTipsCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Care Tips', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          if (plant.wateringFrequency != null || plant.sunlight != null || plant.difficulty != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (plant.wateringFrequency != null)
                    _InfoPill('💧 ${plant.wateringFrequency!}'),
                  if (plant.sunlight != null)
                    _InfoPill('☀️ ${plant.sunlight!}'),
                  if (plant.difficulty != null)
                    _InfoPill('⭐ ${plant.difficulty!}'),
                ],
              ),
            ),
          const SizedBox(height: 10),
          ...plant.careTips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(tip, style: GoogleFonts.nunito(fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
      ),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📝', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(notes, style: GoogleFonts.nunito(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
