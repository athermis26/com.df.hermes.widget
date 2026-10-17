import 'package:flutter/foundation.dart';

/// Routes affichées par la BottomNavigation du panneau.
enum PanelRoute { queue, vue360, assistant, chat }

/// Sélection de l'onglet courant. Plus de pile : la BottomNav est
/// l'unique point de navigation entre les 4 vues principales.
class PanelNav {
  PanelNav._();
  static final instance = PanelNav._();

  final ValueNotifier<PanelRoute> current =
      ValueNotifier<PanelRoute>(PanelRoute.queue);

  void go(PanelRoute r) {
    if (current.value == r) return;
    current.value = r;
  }

  void reset() => go(PanelRoute.queue);
}
