import 'package:flutter/foundation.dart';

/// Permet aux onglets de demander le passage à un autre onglet
/// (ex: clic sur une notification → ouvre l'onglet Recherche/Vue 360).
class PanelNav {
  PanelNav._();
  static final instance = PanelNav._();

  /// 0 Recherche/Vue360 · 1 IA · 2 Actions · 3 Notifs
  final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  void goTo(int i) => tabIndex.value = i;
}
