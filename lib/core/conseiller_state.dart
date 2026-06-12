import 'package:flutter/foundation.dart';

import '../models/conseiller.dart';
import '../models/ticket.dart';
import 'client_selection.dart';

/// État runtime du conseiller :
///   - statut (Disponible / En traitement / Pause)
///   - ticket actif (le seul sur lequel il est en ligne)
///   - timestamp du début de prise en charge (chrono DMT)
class ConseillerState {
  ConseillerState._();
  static final instance = ConseillerState._();

  static const Duration dmtTarget = Duration(minutes: 10);
  static const Duration dmtWarning = Duration(minutes: 8);

  final ValueNotifier<StatutConseiller> statut =
      ValueNotifier(StatutConseiller.disponible);

  /// Ticket que le conseiller est en train de traiter. Un seul à la fois.
  final ValueNotifier<Ticket?> activeTicket = ValueNotifier<Ticket?>(null);

  /// Démarrage de la prise en charge courante.
  final ValueNotifier<DateTime?> dmtStart = ValueNotifier<DateTime?>(null);

  bool get hasActiveCall => activeTicket.value != null;

  void setStatut(StatutConseiller s) {
    statut.value = s;
    if (s != StatutConseiller.enTraitement) {
      activeTicket.value = null;
      dmtStart.value = null;
    }
  }

  /// Prendre un ticket : devient l'appel actif + chrono DMT lancé.
  /// On sélectionne aussi le client pour faire apparaître la Vue 360.
  void prendre(Ticket t) {
    activeTicket.value = t;
    statut.value = StatutConseiller.enTraitement;
    dmtStart.value = DateTime.now();
    ClientSelection.instance.select(t.client);
  }

  /// Raccrocher : on libère l'appel actif et on repasse en Disponible.
  /// La Vue 360 reste accessible le temps de finaliser la fiche.
  void raccrocher() {
    activeTicket.value = null;
    statut.value = StatutConseiller.disponible;
    dmtStart.value = null;
  }

  /// Démarrage manuel d'une prise en charge sans ticket associé
  /// (ex: screen-pop simulé, action manuelle dans l'onglet Activité).
  void demarrerPriseEnCharge() {
    statut.value = StatutConseiller.enTraitement;
    dmtStart.value = DateTime.now();
  }

  void finirPriseEnCharge() => raccrocher();
}
