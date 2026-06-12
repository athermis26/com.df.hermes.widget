import 'package:flutter/foundation.dart';

import '../models/ticket.dart';
import 'client_selection.dart';

/// Sélection courante d'un ticket. Maintient en cohérence
/// `ClientSelection.current` (la Vue 360 reste centrée client) tout en
/// gardant le contexte ticket (motif, priorité, durée d'appel…) pour
/// enrichir les onglets et l'IA.
class TicketSelection {
  TicketSelection._();
  static final instance = TicketSelection._();

  final ValueNotifier<Ticket?> current = ValueNotifier<Ticket?>(null);

  void select(Ticket t) {
    current.value = t;
    ClientSelection.instance.select(t.client);
  }

  void clear() {
    current.value = null;
    ClientSelection.instance.clear();
  }
}
