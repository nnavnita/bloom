import 'dart:io';
import 'package:bloom/models/plant_log.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:bloom/widgets/health_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LogEntryCard extends StatelessWidget {
  final PlantLog log;
  final VoidCallback? onDelete;

  const LogEntryCard({super.key, required this.log, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('EEE, MMM d · h:mm a').format(log.date),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              HealthIndicator(health: log.health, compact: true),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (log.watered) _ActionChip(emoji: '💧', label: 'Watered'),
              if (log.fertilized) _ActionChip(emoji: '🌱', label: 'Fertilized'),
              if (log.repotted) _ActionChip(emoji: '🪣', label: 'Repotted'),
            ],
          ),
          if (log.watered || log.fertilized || log.repotted)
            const SizedBox(height: 8),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            Text(
              log.notes!,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF444444),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (log.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(log.imagePath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _ActionChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
