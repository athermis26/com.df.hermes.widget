import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import 'conseiller.dart';

/// Action rapide proposée dans l'onglet « Actions ».
class QuickAction {
  final String id;
  final String label;
  final String description;
  final AppIcon icon;
  final Color color;
  final List<ProfilConseiller> allowedProfils;
  final bool requiresClient;
  final bool sensitive;
  final String? hermesPath;

  const QuickAction({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.allowedProfils,
    this.requiresClient = true,
    this.sensitive = false,
    this.hermesPath,
  });
}
