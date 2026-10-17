import '../models/client.dart';
import '../models/ticket.dart';
import 'mock_data.dart';

/// Lookup par préfixe de nom — robuste au réordonnancement de `mockClients`.
Client _by(String prefix) =>
    mockClients.firstWhere((c) => c.nom.startsWith(prefix));

/// File d'attente Call Center du moment (tickets en attente — le conseiller
/// n'est pas encore en ligne avec eux). `createdAt` = arrivée dans la file.
final List<Ticket> mockTicketsCallCenter = () {
  final now = DateTime.now();
  return [
    Ticket(
      id: 'CC-2026-04424',
      client: _by('Koffi'),
      motif: TicketMotif.blocageOrangeMoney,
      priority: TicketPriority.eleve,
      corbeille: 'Call Center · CI',
      createdAt: now.subtract(const Duration(minutes: 3, seconds: 50)),
    ),
    Ticket(
      id: 'CC-2026-04421',
      client: _by('Kouadio'),
      motif: TicketMotif.rechargeImpossible,
      priority: TicketPriority.urgent,
      corbeille: 'Call Center · CI',
      createdAt: now.subtract(const Duration(minutes: 2, seconds: 30)),
    ),
    Ticket(
      id: 'CC-2026-04422',
      client: _by('Mariam'),
      motif: TicketMotif.reclamationFacture,
      priority: TicketPriority.eleve,
      corbeille: 'Call Center · CI',
      createdAt: now.subtract(const Duration(minutes: 6, seconds: 12)),
    ),
    Ticket(
      id: 'CC-2026-04423',
      client: _by('SCI'),
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
      id: 'AG-2026-10005',
      client: _by('Koffi'),
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.normal,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 4)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10001',
      client: _by('Kouadio'),
      motif: TicketMotif.perteSim,
      priority: TicketPriority.urgent,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 1)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10002',
      client: _by('Mariam'),
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.normal,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 6)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10003',
      client: _by('SCI'),
      motif: TicketMotif.reclamationFacture,
      priority: TicketPriority.eleve,
      corbeille: 'Agence Cocody II Plateaux',
      createdAt: now.subtract(const Duration(minutes: 12)),
      source: TicketSource.accueil,
    ),
    Ticket(
      id: 'AG-2026-10004',
      client: _by('Kouadio'),
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
      id: 'DG-2026-77127',
      client: _by('Koffi'),
      motif: TicketMotif.reclamationFacture,
      priority: TicketPriority.eleve,
      corbeille: 'Digital · WhatsApp',
      createdAt: now.subtract(const Duration(minutes: 7)),
      source: TicketSource.whatsapp,
    ),
    Ticket(
      id: 'DG-2026-77124',
      client: _by('Mariam'),
      motif: TicketMotif.blocageOrangeMoney,
      priority: TicketPriority.eleve,
      corbeille: 'Digital · Facebook',
      createdAt: now.subtract(const Duration(minutes: 4)),
      source: TicketSource.facebook,
    ),
    Ticket(
      id: 'DG-2026-77123',
      client: _by('Kouadio'),
      motif: TicketMotif.configurationApn,
      priority: TicketPriority.normal,
      corbeille: 'Digital · Email',
      createdAt: now.subtract(const Duration(minutes: 18)),
      source: TicketSource.email,
    ),
    Ticket(
      id: 'DG-2026-77125',
      client: _by('SCI'),
      motif: TicketMotif.problemeFibre,
      priority: TicketPriority.normal,
      corbeille: 'Digital · WhatsApp',
      createdAt: now.subtract(const Duration(minutes: 9)),
      source: TicketSource.whatsapp,
    ),
    Ticket(
      id: 'DG-2026-77126',
      client: _by('Kouadio'),
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.faible,
      corbeille: 'Digital · Twitter',
      createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      source: TicketSource.twitter,
    ),
    Ticket(
      id: 'DG-2026-77128',
      client: _by('Koffi'),
      motif: TicketMotif.configurationApn,
      priority: TicketPriority.normal,
      corbeille: 'Digital · Telegram',
      createdAt: now.subtract(const Duration(minutes: 11)),
      source: TicketSource.telegram,
    ),
    Ticket(
      id: 'DG-2026-77129',
      client: _by('Mariam'),
      motif: TicketMotif.rechargeImpossible,
      priority: TicketPriority.urgent,
      corbeille: 'Digital · Telegram',
      createdAt: now.subtract(const Duration(minutes: 2, seconds: 15)),
      source: TicketSource.telegram,
    ),
    Ticket(
      id: 'DG-2026-77130',
      client: _by('SCI'),
      motif: TicketMotif.demandeOffre,
      priority: TicketPriority.faible,
      corbeille: 'Digital · Telegram',
      createdAt: now.subtract(const Duration(minutes: 25)),
      source: TicketSource.telegram,
    ),
  ];
}();

/// Corbeilles cibles pour le transfert (mock).
const List<String> mockCorbeillesCibles = [
  'N2 — Expertise Technique N2',
  'N3 — Direction Technique N3',
  'Expertise & Escalade N2',
  'Agence Front Office N1',
  'Administration',
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
