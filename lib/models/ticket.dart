import 'client.dart';

/// Priorité du ticket dans la file.
enum TicketPriority { urgent, eleve, normal, faible }

/// Motif du ticket — pilote la liste d'actions contextuelles.
enum TicketMotif {
  reclamationFacture,
  rechargeImpossible,
  perteSim,
  problemeFibre,
  blocageOrangeMoney,
  demandeOffre,
  configurationApn,
  autre,
}

extension TicketMotifX on TicketMotif {
  String get label {
    switch (this) {
      case TicketMotif.reclamationFacture:
        return 'Réclamation facture';
      case TicketMotif.rechargeImpossible:
        return 'Recharge impossible';
      case TicketMotif.perteSim:
        return 'Perte / vol SIM';
      case TicketMotif.problemeFibre:
        return 'Problème Fibre';
      case TicketMotif.blocageOrangeMoney:
        return 'Compte OM bloqué';
      case TicketMotif.demandeOffre:
        return 'Demande d\'offre';
      case TicketMotif.configurationApn:
        return 'Configuration APN';
      case TicketMotif.autre:
        return 'Autre';
    }
  }
}

extension TicketPriorityX on TicketPriority {
  // Aligné sur HERMÈS web : Critique / Haute / Moyenne / Faible.
  String get label {
    switch (this) {
      case TicketPriority.urgent:
        return 'Critique';
      case TicketPriority.eleve:
        return 'Haute';
      case TicketPriority.normal:
        return 'Moyenne';
      case TicketPriority.faible:
        return 'Faible';
    }
  }
}

/// Source d'un ticket Digital (email / WhatsApp / Facebook…).
enum TicketSource { telephone, email, whatsapp, facebook, twitter, accueil }

class Ticket {
  final String id;
  final Client client;
  final TicketMotif motif;
  final TicketPriority priority;
  final String corbeille;
  final DateTime createdAt;
  final DateTime? callStartedAt; // Call Center uniquement
  final TicketSource source;

  const Ticket({
    required this.id,
    required this.client,
    required this.motif,
    required this.priority,
    required this.corbeille,
    required this.createdAt,
    this.callStartedAt,
    this.source = TicketSource.telephone,
  });
}
