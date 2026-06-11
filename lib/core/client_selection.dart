import 'package:flutter/foundation.dart';

import '../models/client.dart';

/// Sélection de client courante dans le widget.
///
/// Émet une notification quand l'utilisateur ouvre la Vue 360 d'un client
/// depuis :
///   • la recherche
///   • le screen-pop (appel entrant simulé)
///   • le clic sur une notification liée à un client
///
/// Vue 360 n'est visible **que** si [current] != null.
class ClientSelection {
  ClientSelection._();
  static final instance = ClientSelection._();

  final ValueNotifier<Client?> current = ValueNotifier<Client?>(null);

  void select(Client c) => current.value = c;
  void clear() => current.value = null;
}
