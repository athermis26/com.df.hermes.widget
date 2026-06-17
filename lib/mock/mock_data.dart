import '../models/client.dart';
import '../models/conseiller.dart';
import '../models/notification.dart';

/// ─────────────────────────────────────────────────────────────
/// Conseiller connecté (mock — pas de SSO/AD pour le POC)
/// ─────────────────────────────────────────────────────────────
/// Conseiller par défaut (rétro-compat). La session courante est dans
/// `Session.instance.current` — c'est le conseiller choisi à la connexion.
const Conseiller mockConseiller = Conseiller(
  id: 'AGT-00421',
  nom: 'Yaël AHODAN',
  profil: ProfilConseiller.callCenter,
  agence: 'Plateau – CC Abidjan',
);

/// 3 conseillers démo (un par profil) — proposés sur l'écran de connexion.
const List<Conseiller> mockConseillers = [
  Conseiller(
    id: 'AGT-00421',
    nom: 'Yaël AHODAN',
    profil: ProfilConseiller.callCenter,
    agence: 'Plateau – CC Abidjan',
  ),
  Conseiller(
    id: 'AGT-00132',
    nom: 'Yao N\'GUESSAN',
    profil: ProfilConseiller.agence,
    agence: 'Cocody – Agence II Plateaux',
  ),
  Conseiller(
    id: 'AGT-00777',
    nom: 'Fatou DIOMANDÉ',
    profil: ProfilConseiller.digital,
    agence: 'Hub Digital – Abidjan',
  ),
];

/// ─────────────────────────────────────────────────────────────
/// File d'attente agence (mock)
/// ─────────────────────────────────────────────────────────────
const int mockFileAttenteCount = 7;

/// ─────────────────────────────────────────────────────────────
/// Numéros restreints (blacklist / VIP protégés)
/// Une recherche correspondante affichera un message dédié.
/// ─────────────────────────────────────────────────────────────
const List<String> mockBlacklist = [
  '+225 07 99 99 99 99', // ex-collaborateur frauduleux
  '0799999999',
];

const List<String> mockVipProteges = [
  '+225 01 11 11 11 11', // ligne ministre
  '0111111111',
];

/// ─────────────────────────────────────────────────────────────
/// 3 clients démo
///   1. Kouadio ASSI       – B2C Prépayé Mass Market
///   2. Mariam TRAORÉ      – B2C Postpayé Fibre Premium
///   3. SCI ELEPHANT BTP   – B2B PME (multi-lignes)
/// ─────────────────────────────────────────────────────────────
final List<Client> mockClients = [
  // ── 1. Kouadio ASSI ───────────────────────────────────────
  Client(
    id: 'CLI-001',
    type: 'B2C',
    nom: 'Kouadio ASSI',
    numeroPrincipal: '+225 07 07 12 34 56',
    segment: 'Mass Market',
    statutIdentification: 'Valide',
    photoInitiales: 'KA',
    contactsAujourdhui: 3, // déclenchera l'alerte « client récurrent »
    scoring: Scoring(
      qualitePayeur: 'Bon',
      segmentValeur: 'Bronze',
      csi: 62,
      nps: 4,
      dernierPassageBoutique: DateTime(2026, 4, 18),
    ),
    consommation: Consommation(
      creditFcfa: 1250,
      dataRestanteGo: 0.4,
      dataTotaleGo: 5.0,
      dataExpiration: DateTime(2026, 6, 14),
      smsRestants: 12,
      passActifs: ['Pass Internet Jour 1Go', 'Pass Réseaux Sociaux'],
      consoParMois: {'M-1': 4.2, 'M': 4.6},
    ),
    contrats: const [
      Contrat(
        id: 'CTR-MOB-77812',
        service: 'Mobile',
        statut: 'Actif',
        offre: 'Prépayé MyMax',
      ),
      Contrat(
        id: 'CTR-OM-22198',
        service: 'OrangeMoney',
        statut: 'Actif',
        offre: 'Compte OM Standard',
      ),
    ],
    facturation: null, // prépayé
    dernieresInteractions: [
      Interaction(
        type: 'Réclamation',
        date: DateTime(2026, 6, 10, 9, 12),
        statut: 'En cours',
        resume: 'Data épuisée plus vite que prévu — demande de vérification.',
      ),
      Interaction(
        type: 'Appel',
        date: DateTime(2026, 6, 10, 8, 41),
        statut: 'Résolu',
        resume: 'Question sur le solde OrangeMoney.',
      ),
      Interaction(
        type: 'Dérangement',
        date: DateTime(2026, 6, 8, 17, 30),
        statut: 'Résolu',
        resume: 'Perte de signal zone Yopougon — incident résolu.',
      ),
    ],
    ia: const IaInsights(
      risqueChurnPct: 38,
      offreRecommandee: 'Forfait Data 30 Go — conso en hausse de 40 %',
      tonSuggere: 'Empathique – client visiblement contrarié (3ᵉ contact aujourd\'hui)',
      gesteCommercial: 'Offrir 2 Go en compensation',
    ),
  ),

  // ── 2. Mariam TRAORÉ ──────────────────────────────────────
  Client(
    id: 'CLI-002',
    type: 'B2C',
    nom: 'Mariam TRAORÉ',
    numeroPrincipal: '+225 01 02 84 55 90',
    segment: 'Premium',
    statutIdentification: 'Valide',
    photoInitiales: 'MT',
    contactsAujourdhui: 1,
    vip: true,
    scoring: Scoring(
      qualitePayeur: 'Excellent',
      segmentValeur: 'Gold',
      csi: 88,
      nps: 42,
      dernierPassageBoutique: DateTime(2026, 5, 2),
    ),
    consommation: Consommation(
      creditFcfa: 0,
      dataRestanteGo: 78.3,
      dataTotaleGo: 100.0,
      dataExpiration: DateTime(2026, 6, 30),
      smsRestants: 999,
      passActifs: ['Pass International EU', 'Orange TV Premium'],
      consoParMois: {'M-1': 62.0, 'M': 68.5},
    ),
    contrats: const [
      Contrat(
        id: 'CTR-FIB-90041',
        service: 'Fibre',
        statut: 'Actif',
        offre: 'Fibre 500 Mbps + TV',
      ),
      Contrat(
        id: 'CTR-MOB-44102',
        service: 'Mobile',
        statut: 'Actif',
        offre: 'Postpayé Privilège 100Go',
      ),
      Contrat(
        id: 'CTR-TV-09812',
        service: 'OrangeTV',
        statut: 'Actif',
        offre: 'Bouquet Famille + Sport',
      ),
    ],
    facturation: Facturation(
      montantDerniereFacture: 45000,
      echeance: DateTime(2026, 6, 25),
      paye: false,
      soldeDu: 45000,
    ),
    dernieresInteractions: [
      Interaction(
        type: 'Demande',
        date: DateTime(2026, 6, 9, 11, 0),
        statut: 'Résolu',
        resume: 'Demande de mise à niveau bouquet TV.',
      ),
      Interaction(
        type: 'Réclamation',
        date: DateTime(2026, 5, 22, 14, 12),
        statut: 'Résolu',
        resume: 'Latence Fibre — corrigée après reset modem.',
      ),
    ],
    ia: const IaInsights(
      risqueChurnPct: 12,
      offreRecommandee: 'Upgrade Fibre 1 Gbps — usage stable très élevé',
      tonSuggere: 'Premium / déférent – cliente fidèle Gold',
      gesteCommercial: '1 mois Orange TV Premium offert',
    ),
  ),

  // ── 3. SCI ELEPHANT BTP ───────────────────────────────────
  Client(
    id: 'CLI-003',
    type: 'B2B',
    nom: 'SCI ELEPHANT BTP',
    numeroPrincipal: '+225 27 22 49 80 00',
    segment: 'PME',
    statutIdentification: 'Valide',
    photoInitiales: 'SE',
    contactsAujourdhui: 0,
    scoring: Scoring(
      qualitePayeur: 'Excellent',
      segmentValeur: 'Gold',
      csi: 75,
      nps: 18,
      dernierPassageBoutique: null,
    ),
    consommation: Consommation(
      creditFcfa: 0,
      dataRestanteGo: 320.0,
      dataTotaleGo: 500.0,
      dataExpiration: DateTime(2026, 6, 30),
      smsRestants: 5000,
      passActifs: ['Pack Pro Entreprise 20 lignes'],
      consoParMois: {'M-1': 280.0, 'M': 295.0},
    ),
    contrats: const [
      Contrat(
        id: 'CTR-PRO-10021',
        service: 'Fibre',
        statut: 'Actif',
        offre: 'Fibre Pro 1 Gbps symétrique',
      ),
      Contrat(
        id: 'CTR-PRO-10022',
        service: 'Mobile',
        statut: 'Actif',
        offre: 'Flotte Pro – 20 lignes',
      ),
      Contrat(
        id: 'CTR-PRO-10023',
        service: 'Internet',
        statut: 'Suspendu',
        offre: 'Lien backup ADSL',
      ),
    ],
    facturation: Facturation(
      montantDerniereFacture: 1250000,
      echeance: DateTime(2026, 6, 30),
      paye: true,
      soldeDu: 0,
    ),
    dernieresInteractions: [
      Interaction(
        type: 'Demande',
        date: DateTime(2026, 6, 5, 10, 15),
        statut: 'Résolu',
        resume: 'Ajout de 2 lignes flotte mobile.',
      ),
      Interaction(
        type: 'Dérangement',
        date: DateTime(2026, 6, 1, 8, 30),
        statut: 'Résolu',
        resume: 'Coupure Fibre site Treichville — SLA respecté.',
      ),
    ],
    ia: const IaInsights(
      risqueChurnPct: 8,
      offreRecommandee: 'Activation SD-WAN multi-sites',
      tonSuggere: 'Pro / institutionnel – interlocuteur DSI',
      gesteCommercial: 'Audit réseau gratuit',
    ),
  ),
];

/// ─────────────────────────────────────────────────────────────
/// Notifications (file de l'onglet E)
/// ─────────────────────────────────────────────────────────────
final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 'N-001',
    type: NotifType.slaWarning,
    titre: 'SLA à échéance — CASE-2026-04421',
    message: 'Statut SLA en retard dans 12 min · K. ASSI.',
    date: DateTime(2026, 6, 10, 9, 30),
    clientIdLie: 'CLI-001',
  ),
  AppNotification(
    id: 'N-002',
    type: NotifType.caseAssigned,
    titre: 'Nouveau case assigné',
    message: 'Réclamation — M. TRAORÉ (CASE-2026-04422).',
    date: DateTime(2026, 6, 10, 9, 12),
    clientIdLie: 'CLI-002',
  ),
  AppNotification(
    id: 'N-003',
    type: NotifType.retourFile,
    titre: 'Retour en file',
    message: 'SCI ELEPHANT BTP est revenu dans votre corbeille.',
    date: DateTime(2026, 6, 10, 8, 55),
    clientIdLie: 'CLI-003',
    lue: true,
  ),
];
