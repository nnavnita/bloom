import 'dart:io';
import 'package:bloom/models/plant.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:bloom/widgets/health_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;
  final VoidCallback? onQuickWater;

  const PlantCard({super.key, required this.plant, this.onTap, this.onQuickWater});

  @override
  Widget build(BuildContext context) {
    final health = StorageService.getLatestHealth(plant.id);
    final streak = StorageService.getLogStreak(plant.id);
    final lastWatered = StorageService.getLastWatered(plant.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlantImage(plant: plant),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.displayName,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _TypeBadge(type: plant.type),
                      ],
                    ),
                    if (plant.species != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant.species!,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (health != null) HealthIndicator(health: health, compact: true),
                    const Spacer(),
                    Row(
                      children: [
                        if (streak > 0) ...[
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Text(
                            '$streak',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (lastWatered != null) ...[
                          const Text('💧', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Text(
                            DateFormat('MMM d').format(lastWatered),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: Colors.blue.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: onQuickWater,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('💧', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantImage extends StatelessWidget {
  final Plant plant;
  const _PlantImage({required this.plant});

  @override
  Widget build(BuildContext context) {
    if (plant.imagePath != null) {
      final file = File(plant.imagePath!);
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(file, fit: BoxFit.cover),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: plant.type == PlantType.indoor
            ? AppColors.primary.withOpacity(0.08)
            : Colors.amber.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Text(
            plant.type == PlantType.indoor ? '🪴' : '🌿',
            style: const TextStyle(fontSize: 52),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final PlantType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: type == PlantType.indoor
            ? AppColors.indoor.withOpacity(0.15)
            : AppColors.outdoor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type == PlantType.indoor ? '🏠' : '☀️',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}
