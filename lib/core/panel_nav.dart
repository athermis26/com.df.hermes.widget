import 'package:flutter/foundation.dart';

/// Routes possibles dans le panneau (hors écran de login).
/// La Vue 360 n'est pas une route à part : elle s'affiche dans la route
/// `file` quand un ticket est sélectionné (TicketSelection.current != null).
enum PanelRoute { file, assistant }

/// Navigation en pile pour le panneau. Plus de bottom-nav : on push/pop
/// au besoin (Assistant ouvert depuis une card ou depuis la Vue 360).
class PanelNav {
  PanelNav._();
  static final instance = PanelNav._();

  final ValueNotifier<List<PanelRoute>> stack =
      ValueNotifier<List<PanelRoute>>([PanelRoute.file]);

  PanelRoute get current => stack.value.last;
  bool get canPop => stack.value.length > 1;

  void push(PanelRoute r) {
    if (current == r) return;
    stack.value = [...stack.value, r];
  }

  bool pop() {
    if (!canPop) return false;
    stack.value = stack.value.sublist(0, stack.value.length - 1);
    return true;
  }

  void reset() {
    stack.value = [PanelRoute.file];
  }
}
