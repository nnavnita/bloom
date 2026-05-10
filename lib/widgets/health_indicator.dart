import 'package:bloom/models/plant.dart';
import 'package:bloom/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthIndicator extends StatelessWidget {
  final PlantHealth health;
  final bool compact;

  const HealthIndicator({super.key, required this.health, this.compact = false});

  Color get _color {
    switch (health) {
      case PlantHealth.excellent: return AppColors.excellent;
      case PlantHealth.good: return AppColors.good;
      case PlantHealth.fair: return AppColors.fair;
      case PlantHealth.poor: return AppColors.poor;
      case PlantHealth.critical: return AppColors.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(health.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              health.label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(health.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          health.label,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class HealthSelector extends StatelessWidget {
  final PlantHealth selected;
  final ValueChanged<PlantHealth> onChanged;

  const HealthSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlantHealth.values.map((h) {
        final isSelected = h == selected;
        Color color;
        switch (h) {
          case PlantHealth.excellent: color = AppColors.excellent; break;
          case PlantHealth.good: color = AppColors.good; break;
          case PlantHealth.fair: color = AppColors.fair; break;
          case PlantHealth.poor: color = AppColors.poor; break;
          case PlantHealth.critical: color = AppColors.critical; break;
        }
        return GestureDetector(
          onTap: () => onChanged(h),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(h.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  h.label,
                  style: GoogleFonts.nunito(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
