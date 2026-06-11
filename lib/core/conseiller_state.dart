import 'package:flutter/foundation.dart';

import '../models/conseiller.dart';

/// État runtime du conseiller connecté :
/// - statut (Disponible / En traitement / Pause)
/// - début de la prise en charge courante (pour le chrono DMT)
class ConseillerState {
  ConseillerState._();
  static final instance = ConseillerState._();

  /// Objectif DMT de référence (10 min – cible du projet HERMES).
  static const Duration dmtTarget = Duration(minutes: 10);

  /// Seuil d'alerte visuelle avant d'atteindre la cible.
  static const Duration dmtWarning = Duration(minutes: 8);

  final ValueNotifier<StatutConseiller> statut =
      ValueNotifier(StatutConseiller.disponible);

  /// Timestamp de démarrage de la prise en charge courante.
  /// `null` si aucune interaction en cours.
  final ValueNotifier<DateTime?> dmtStart = ValueNotifier<DateTime?>(null);

  void setStatut(StatutConseiller s) {
    statut.value = s;
    if (s != StatutConseiller.enTraitement) {
      dmtStart.value = null;
    }
  }

  /// Démarre la prise en charge → passe en « En traitement » + lance le chrono.
  void demarrerPriseEnCharge() {
    statut.value = StatutConseiller.enTraitement;
    dmtStart.value = DateTime.now();
  }

  /// Termine la prise en charge → repasse en « Disponible » + stoppe le chrono.
  void finirPriseEnCharge() {
    statut.value = StatutConseiller.disponible;
    dmtStart.value = null;
  }
}
