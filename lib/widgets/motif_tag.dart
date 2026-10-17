import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Tag visuel uniforme pour afficher un motif de ticket — même logique
/// d'apparence que les badges de priorité ou de statut : pastille colorée
/// orange + bordure + libellé compact.
class MotifTag extends StatelessWidget {
  final String label;
  final bool dense;
  const MotifTag({super.key, required this.label, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 6,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: dense ? 9.5 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
