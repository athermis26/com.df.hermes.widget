import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/app_icons.dart';

/// Raccourci ultra-compact pour insérer une icône HugeIcons.
///
/// Au lieu d'écrire `HugeIcon(icon: AppIcons.x, color: c, size: s)`,
/// on écrit `Hi(AppIcons.x, color: c, size: s)`.
class Hi extends StatelessWidget {
  final AppIcon icon;
  final double? size;
  final Color? color;
  final double? strokeWidth;
  const Hi(this.icon, {super.key, this.size, this.color, this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size,
      color: color,
      strokeWidth: strokeWidth ?? 1.8,
    );
  }
}
