import '../models/ticket.dart';
import 'mock_data.dart';

/// File d'attente Call Center du moment (tickets en attente — le conseiller
/// n'est pas encore en ligne avec eux). `createdAt` = arrivée dans la file.
final List<Ticket> mockTicketsCallCenter = () {
  final now = DateTime.now();
  return [
    Ticket(
      id: 'CC-2026-04421',
      client: mockClients[0], // K. ASSI
      motif: TicketMotif.rechargeImpossible,
      priority: TicketPriority.urgent,
      corbeille: 'Call Center · CI',
      createdAt: now.subtract(const Duration(minutes: 2, seconds: 30)),
    ),
    Ticket(
      id: 'CC-2026-04422',
      client: mockClients[1], // M. TRAORÉ (VIP)
      motif: TicketMotif.reclamationFacture,
      priority: TicketPriority.eleve,
      corbeille: 'Call Center · CI',
      createdAt: now.subtract(const Duration(minutes: 6, seconds: 12)),
    ),
    Ticket(
      id: 'CC-2026-04423',
      client: mockClients[2], // SCI ELEPHANT BTP
      motif: TicketMotif.problemeFibre,
      priority: TicketPriority.normal,
      corbeille: 'Call Center · Pro',
      createdAt: now.subtract(const Duration(seconds: 45)),
    ),
  ];
}();

final List<Ticket> mockTicketsAgence = () {
  final now = DateTime.now();
  return [
    Ticket(
      id: 'AG-2026-10001',
      client: mockClients[0],
      motif: TicketMotif.perteSim,
      priority: TicketPriority.urgent,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 1)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10002',
      client: mockClients[1],
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.normal,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 6)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10003',
      client: mockClients[2],
      motif: TicketMotif.reclamationFacture,
      priority: TicketPriority.eleve,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 12)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10004',
      client: mockClients[0],
      motif: TicketMotif.configurationApn,
      priority: TicketPriority.faible,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 22)),
      source: TicketSource.accueil,
    ),
  ];
}();

final List<Ticket> mockTicketsDigital = () {
  final now = DateTime.now();
  return [
    Ticket(
      id: 'DG-2026-77124',
      client: mockClients[1],
      motif: TicketMotif.blocageOrangeMoney,
      priority: TicketPriority.eleve,
      corbeille: 'Digital · Facebook',
      createdAt: now.subtract(const Duration(minutes: 4)),
      source: TicketSource.facebook,
    ),
    Ticket(
      id: 'DG-2026-77123',
      client: mockClients[0],
      motif: TicketMotif.configurationApn,
      priority: TicketPriority.normal,
      corbeille: 'Digital · Email',
      createdAt: now.subtract(const Duration(minutes: 18)),
      source: TicketSource.email,
    ),
    Ticket(
      id: 'DG-2026-77125',
      client: mockClients[2],
      motif: TicketMotif.problemeFibre,
      priority: TicketPriority.normal,
      corbeille: 'Digital · WhatsApp',
      createdAt: now.subtract(const Duration(minutes: 9)),
      source: TicketSource.whatsapp,
    ),
    Ticket(
      id: 'DG-2026-77126',
      client: mockClients[0],
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.faible,
      corbeille: 'Digital · Twitter',
      createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      source: TicketSource.twitter,
    ),
  ];
}();

/// Corbeilles cibles pour le transfert (mock).
const List<String> mockCorbeillesCibles = [
  'Call Center · Pro',
  'Niveau 2 · Réclamations',
  'Niveau 2 · Fibre',
  'Niveau 2 · Orange Money',
  'Superviseur de plateau',
];

/// Mapping Motif → liste d'IDs d'actions du catalogue `mockActions`.
const Map<TicketMotif, List<String>> actionsByMotif = {
  TicketMotif.reclamationFacture: ['remb_credit_1k', 'remb_credit_10k'],
  TicketMotif.rechargeImpossible: ['remb_credit_1k', 'sms_apn'],
  TicketMotif.perteSim: ['sim_swap', 'bloquer_om'],
  TicketMotif.problemeFibre: ['reactiv_fibre'],
  TicketMotif.blocageOrangeMoney: ['debloquer_om', 'reinit_code_om'],
  TicketMotif.demandeOffre: ['sms_maxit'],
  TicketMotif.configurationApn: ['sms_apn', 'sms_maxit'],
  TicketMotif.autre: ['sim_swap', 'remb_credit_1k', 'sms_maxit', 'sms_apn'],
};
