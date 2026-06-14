import 'package:flutter/material.dart';

/// Palette mutable utilisée par tous les widgets — remplace les anciennes
/// constantes `AppColors.dark/darkSurface/textLight/textMuted` qui
/// étaient figées sur le thème sombre.
///
/// Les champs sont réassignés par [ThemeController.toggle].
/// Comme ils ne sont pas `const`, les widgets ne peuvent plus utiliser
/// `const` à l'extérieur des sous-arbres qui les contiennent — c'est le
/// prix à payer pour un thème dynamique.
class P {
  P._();

  // Valeurs initiales = thème clair (le démarrage applique ensuite la
  // palette définitive via ThemeController.apply()).
  static Color bg = const Color(0xFFF5F5F7);
  static Color surface = Colors.white;
  static Color text = const Color(0xFF1A1A1A);
  static Color muted = const Color(0xFF6B6B6B);
  static Color border = Colors.black12;
  static Color borderSoft = const Color(0x14000000);
  static Color borderStrong = Colors.black26;
}

class ThemeController {
  ThemeController._();
  static final instance = ThemeController._();

  /// `false` = mode clair (par défaut). Le header expose un toggle qui
  /// inverse la valeur ; main.dart écoute pour reconstruire l'arbre.
  final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  void toggle() {
    isDark.value = !isDark.value;
    _apply(isDark.value);
  }

  /// Appelée aussi au démarrage (avant `runApp`) pour s'assurer que P est
  /// cohérent avec la valeur initiale.
  void apply() => _apply(isDark.value);

  void _apply(bool dark) {
    if (dark) {
      P.bg = const Color(0xFF1A1A1A);
      P.surface = const Color(0xFF242424);
      P.text = const Color(0xFFF5F5F5);
      P.muted = const Color(0xFFB0B0B0);
      P.border = Colors.white12;
      P.borderSoft = Colors.white10;
      P.borderStrong = Colors.white24;
    } else {
      P.bg = const Color(0xFFF5F5F7);
      P.surface = Colors.white;
      P.text = const Color(0xFF1A1A1A);
      P.muted = const Color(0xFF6B6B6B);
      P.border = Colors.black12;
      P.borderSoft = const Color(0x14000000); // ~black 8 %
      P.borderStrong = Colors.black26;
    }
  }
}
