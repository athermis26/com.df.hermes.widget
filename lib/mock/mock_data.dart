import '../models/client.dart';
import '../models/conseiller.dart';
import '../models/notification.dart';

/// ─────────────────────────────────────────────────────────────
/// Conseiller connecté (mock — pas de SSO/AD pour le POC)
/// ─────────────────────────────────────────────────────────────
const Conseiller mockConseiller = Conseiller(
  id: 'AGT-00421',
  nom: 'Yaël AHODAN',
  profil: ProfilConseiller.callCenter,
  agence: 'Plateau – CC Abidjan',
);

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

const int mockFileAttenteCount = 7;

const List<String> mockBlacklist = [
  '+225 07 99 99 99 99',
  '0799999999',
];

const List<String> mockVipProteges = [
  '+225 01 11 11 11 11',
  '0111111111',
];

/// ─────────────────────────────────────────────────────────────
/// 4 clients démo
///   1. Kouadio ASSI       – B2C Prépayé Mass Market
///   2. Mariam TRAORÉ      – B2C Postpayé Fibre Premium
///   3. SCI ELEPHANT BTP   – B2B PME (multi-lignes)
///   4. Koffi SERGE        – B2C multi-numéros (3 lignes) — cas de la spec
///
/// L'ordre d'affichage final (`mockClients`) est défini en bas de fichier —
/// Koffi SERGE est mis en tête pour les démos multi-numéros.
/// ─────────────────────────────────────────────────────────────
final List<Client> _mockClientsBase = [
  // ── 1. Kouadio ASSI ───────────────────────────────────────────
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
      csi: 61,
      nps: 80,
      satisfaction: 4.8,
      dernierPassageBoutique: DateTime(2026, 4, 18),
    ),
    numeros: [
      // Numéro mobile principal — Mobile prépayé + Orange Money
      Numero(
        numero: '+225 07 07 12 34 56',
        libelle: 'Principal',
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
        consommation: Consommation(
          creditFcfa: 1250,
          dataRestanteGo: 0.4,
          dataTotaleGo: 5.0,
          dataExpiration: DateTime(2026, 6, 14),
          smsRestants: 34,
          smsTotaux: 100,
          voixMinRestantes: 78,
          voixMinTotales: 120,
          passActifs: [
            PassActif(
              nom: 'Pass Internet Jour 1Go',
              avantages: '1 Go internet · Valable 24 h',
              expiration: DateTime(2026, 6, 14),
              type: PassType.data,
              prixFcfa: 500,
            ),
            PassActif(
              nom: 'Pass Réseaux Sociaux',
              avantages: 'Facebook · WhatsApp · Instagram illimités',
              expiration: DateTime(2026, 6, 30),
              type: PassType.data,
              prixFcfa: 1000,
            ),
          ],
          consoParMois: {'M-1': 4.2, 'M': 4.6},
        ),
        compteOM: CompteOrangeMoney(
          id: 'OM-77812',
          type: TypeCompteOM.orangeMoney,
          statut: 'Actif',
          offre: 'Compte OM Standard',
          soldeFcfa: 18500,
          plafondMensuelFcfa: 500000,
          niveauKyc: 'KYC1 — Basique',
          ouvertureAt: DateTime(2023, 9, 14),
          dernieresTransactions: [
            OmTransaction(label: 'Recharge mobile', amountFcfa: -1000, when: 'il y a 30 min'),
            OmTransaction(label: 'Dépôt agence Yopougon', amountFcfa: 20000, when: 'hier'),
            OmTransaction(label: 'Paiement CIE', amountFcfa: -8500, when: '03/06'),
          ],
        ),
      ),
    ],
    abonnementsFibre: [
      AbonnementFibre(
        id: 'CTR-ADSL-55102',
        adresse: 'Domicile - Yopougon',
        offre: 'ADSL Essentiel 20 Mb/s + Fixe',
        numeroFixe: '+225 27 22 55 88 90',
        details: FixeInternetDetails(
          equipement: 'Livebox 4',
          techno: 'ADSL',
          debitDescendantMbps: 20,
          debitMontantMbps: 5,
          dispoPct: 98.4,
          connectee: true,
        ),
        renouvellement: DateTime(2026, 7, 5),
        montantMensuelFcfa: 17000,
        factures: [
          FactureRecente(
            id: 'FAC-ADSL-202606',
            libelle: 'ADSL + Fixe',
            periode: 'Juin 2026',
            montantFcfa: 17000,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-ADSL-202605',
            libelle: 'ADSL + Fixe',
            periode: 'Mai 2026',
            montantFcfa: 17000,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
    ],
    abonnementsTv: [
      AbonnementTv(
        id: 'CTR-TV-55104',
        adresse: 'Domicile - Yopougon',
        details: OrangeTvDetails(
          compte: 'OTV-CI-000874',
          pack: 'Pack Essentiel',
          equipement: 'Décodeur SD',
          derniereConnexion: DateTime(2026, 6, 18),
          dateInstallation: DateTime(2022, 9, 4),
          bouquets: ['Généralistes', 'Jeunesse'],
          options: ['TV Replay'],
          nbChaines: 65,
          prixMensuelFcfa: 4900,
          statut: 'Actif',
        ),
      ),
    ],
    facturation: null, // prépayé sur le mobile principal
    dernieresInteractions: [
      Interaction(
        type: 'Problème facturation',
        date: DateTime(2026, 6, 24, 9, 12),
        statut: 'En cours',
        canal: 'Call Center — Voix',
        resume: 'Data épuisée plus vite que prévu — demande de vérification.',
      ),
      Interaction(
        type: 'Remboursement',
        date: DateTime(2026, 6, 20, 8, 41),
        statut: 'Résolu',
        canal: 'Selfcare',
        resume: 'Geste commercial automatique 1 000 FCFA.',
      ),
      Interaction(
        type: 'Résiliation',
        date: DateTime(2026, 6, 21, 17, 30),
        statut: 'Résolu',
        canal: 'Dimelo',
        resume: 'Demande de résiliation finalement annulée.',
      ),
    ],
    ia: const IaInsights(
      risqueChurnPct: 38,
      offreRecommandee: 'Forfait Data 30 Go — conso en hausse de 40 %',
      tonSuggere: 'Empathique – client visiblement contrarié (3ᵉ contact aujourd\'hui)',
      gesteCommercial: 'Offrir 2 Go en compensation',
    ),
    cases: [
      ClientCase(
        id: 'CS-2026-00421',
        categorie: 'Réclamation',
        motif: 'Data épuisée prématurément',
        description:
            'Forfait Data consommé en 4 jours au lieu de 30. Demande vérification ticketing.',
        statut: CaseStatut.enCours,
        gravite: CaseGravite.haute,
        agent: 'Yaël AHODAN',
        corbeille: 'N1 - Mobile',
        createdAt: DateTime(2026, 6, 10, 9, 12),
        slaH: 24,
      ),
      ClientCase(
        id: 'CS-2026-00388',
        categorie: 'Demande',
        motif: 'Recharge Orange Money',
        statut: CaseStatut.cloture,
        gravite: CaseGravite.faible,
        agent: 'Agent Koffi A.',
        corbeille: 'N1 - OM',
        createdAt: DateTime(2026, 6, 8, 17, 30),
        slaH: 8,
      ),
      ClientCase(
        id: 'CS-2026-00355',
        categorie: 'Dérangement',
        motif: 'Perte signal Yopougon',
        statut: CaseStatut.cloture,
        gravite: CaseGravite.moyenne,
        agent: 'Agent Bamba S.',
        corbeille: 'N2 - Réseau',
        createdAt: DateTime(2026, 6, 5, 11, 0),
        slaH: 48,
      ),
    ],
  ),

  // ── 2. Mariam TRAORÉ ─────────────────────────────────────────
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
    numeros: [
      // Mobile postpayé Premium
      Numero(
        numero: '+225 01 02 84 55 90',
        libelle: 'Mobile',
        contrats: const [
          Contrat(
            id: 'CTR-MOB-44102',
            service: 'Mobile',
            statut: 'Actif',
            offre: 'Postpayé Privilège 100Go',
          ),
        ],
        consommation: Consommation(
          creditFcfa: 0,
          dataRestanteGo: 78.3,
          dataTotaleGo: 100.0,
          dataExpiration: DateTime(2026, 6, 30),
          smsRestants: 820,
          smsTotaux: 1000,
          voixMinRestantes: 540,
          voixMinTotales: 600,
          passActifs: [
            PassActif(
              nom: 'Pass International EU',
              avantages: 'Appels & SMS depuis l\'Europe · 200 min inclus',
              expiration: DateTime(2026, 7, 5),
              type: PassType.voix,
              prixFcfa: 8000,
            ),
            PassActif(
              nom: 'Pass SMS Pro 500',
              avantages: '500 SMS nationaux · sans surcoût',
              expiration: DateTime(2026, 7, 12),
              type: PassType.sms,
              prixFcfa: 1500,
            ),
          ],
          consoParMois: {'M-1': 62.0, 'M': 68.5},
        ),
        echeanceAbonnement: EcheanceAbonnement(
          libelle: 'Postpayé Privilège 100Go',
          renouvellement: DateTime(2026, 7, 1),
          montantFcfa: 35000,
        ),
        factures: [
          FactureRecente(
            id: 'FAC-MOB-202606',
            libelle: 'Postpayé Privilège',
            periode: 'Juin 2026',
            montantFcfa: 35000,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-MOB-202605',
            libelle: 'Postpayé Privilège',
            periode: 'Mai 2026',
            montantFcfa: 35000,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
      // Fibre + TV migrés au niveau Client.abonnementsFibre / .abonnementsTv
    ],
    abonnementsFibre: [
      AbonnementFibre(
        id: 'CTR-FIB-90041',
        adresse: 'Domicile - Cocody',
        offre: 'Fibre 500 Mbps + Ligne fixe Premium',
        numeroFixe: '+225 27 22 49 80 11',
        details: FixeInternetDetails(
          equipement: 'Box Orange Fibre',
          techno: 'FTTH',
          debitDescendantMbps: 500,
          debitMontantMbps: 200,
          dispoPct: 99.8,
          connectee: true,
        ),
        renouvellement: DateTime(2026, 7, 1),
        montantMensuelFcfa: 29900,
        factures: [
          FactureRecente(
            id: 'FAC-FIB-202606',
            libelle: 'Fibre 500 Mb/s',
            periode: 'Juin 2026',
            montantFcfa: 29900,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-FIB-202605',
            libelle: 'Fibre + Fixe',
            periode: 'Mai 2026',
            montantFcfa: 29900,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
    ],
    abonnementsTv: [
      AbonnementTv(
        id: 'CTR-TV-09812',
        adresse: 'Domicile - Cocody',
        details: OrangeTvDetails(
          compte: 'OTV-CI-001205',
          pack: 'Pack Famille',
          equipement: 'Décodeur HD',
          derniereConnexion: DateTime(2026, 6, 22),
          dateInstallation: DateTime(2023, 3, 12),
          bouquets: ['Jeunesse', 'Généralistes', 'Sport AFCON'],
          options: ['TV Replay', 'Multi-écran (2)'],
          nbChaines: 120,
          prixMensuelFcfa: 9900,
          statut: 'Actif',
        ),
        factures: [
          FactureRecente(
            id: 'FAC-TV-202606',
            libelle: 'Bouquet TV',
            periode: 'Juin 2026',
            montantFcfa: 9900,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
        ],
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
    cases: [
      ClientCase(
        id: 'CS-2026-00410',
        categorie: 'Réclamation',
        motif: 'Facturation TV',
        description: 'Bouquet Sport facturé deux fois en mai (45 000 F).',
        statut: CaseStatut.ouvert,
        gravite: CaseGravite.haute,
        agent: 'Yaël AHODAN',
        corbeille: 'N2 - Facturation',
        createdAt: DateTime(2026, 6, 9, 11, 0),
        slaH: 24,
      ),
      ClientCase(
        id: 'CS-2026-00301',
        categorie: 'Demande',
        motif: 'Upgrade bouquet TV',
        statut: CaseStatut.cloture,
        gravite: CaseGravite.faible,
        agent: 'Agent Diomandé F.',
        corbeille: 'N1 - Fixe',
        createdAt: DateTime(2026, 5, 22, 14, 12),
        slaH: 8,
      ),
    ],
  ),

  // ── 3. SCI ELEPHANT BTP ──────────────────────────────────────
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
    numeros: [
      // Flotte mobile (Fibre Pro migrée vers Client.abonnementsFibre)
      Numero(
        numero: '+225 01 02 12 34 56',
        libelle: 'Flotte mobile (20 lignes)',
        contrats: const [
          Contrat(
            id: 'CTR-PRO-10022',
            service: 'Mobile',
            statut: 'Actif',
            offre: 'Flotte Pro – 20 lignes',
          ),
        ],
        consommation: Consommation(
          creditFcfa: 0,
          dataRestanteGo: 320.0,
          dataTotaleGo: 500.0,
          dataExpiration: DateTime(2026, 6, 30),
          smsRestants: 4200,
          smsTotaux: 5000,
          voixMinRestantes: 1450,
          voixMinTotales: 2000,
          passActifs: [
            PassActif(
              nom: 'Pack Pro Entreprise 20 lignes',
              avantages: '20 lignes mutualisées · 500 Go partagés',
              expiration: DateTime(2026, 12, 31),
              type: PassType.data,
              prixFcfa: 250000,
            ),
            PassActif(
              nom: 'Pass Voix Pro Illimité',
              avantages: 'Appels nationaux illimités entre lignes Pro',
              expiration: DateTime(2026, 12, 31),
              type: PassType.voix,
              prixFcfa: 50000,
            ),
          ],
          consoParMois: {'M-1': 280.0, 'M': 295.0},
        ),
        echeanceAbonnement: EcheanceAbonnement(
          libelle: 'Flotte Pro 20 lignes',
          renouvellement: DateTime(2026, 7, 15),
          montantFcfa: 270000,
        ),
        factures: [
          FactureRecente(
            id: 'FAC-FLT-202606',
            libelle: 'Flotte Pro',
            periode: 'Juin 2026',
            montantFcfa: 270000,
            echeance: DateTime(2026, 6, 30),
            paye: true,
          ),
        ],
      ),
    ],
    abonnementsFibre: [
      AbonnementFibre(
        id: 'CTR-PRO-10021',
        adresse: 'Siège - Plateau',
        offre: 'Fibre Pro 1 Gbps symétrique',
        numeroFixe: '+225 27 22 49 80 00',
        details: FixeInternetDetails(
          equipement: 'Box Orange Fibre Pro',
          techno: 'FTTH',
          debitDescendantMbps: 1000,
          debitMontantMbps: 1000,
          dispoPct: 99.95,
          connectee: true,
        ),
        renouvellement: DateTime(2026, 7, 15),
        montantMensuelFcfa: 980000,
        factures: [
          FactureRecente(
            id: 'FAC-PRO-202606',
            libelle: 'Fibre Pro 1 Gbps',
            periode: 'Juin 2026',
            montantFcfa: 980000,
            echeance: DateTime(2026, 6, 30),
            paye: true,
          ),
          FactureRecente(
            id: 'FAC-PRO-202605',
            libelle: 'Fibre Pro + backup',
            periode: 'Mai 2026',
            montantFcfa: 1025000,
            echeance: DateTime(2026, 5, 30),
            paye: true,
          ),
        ],
      ),
      AbonnementFibre(
        id: 'CTR-PRO-10023',
        adresse: 'Siège - Plateau (Backup)',
        offre: 'Lien backup ADSL',
        statut: 'Suspendu',
        details: FixeInternetDetails(
          equipement: 'Modem ADSL Pro',
          techno: 'ADSL',
          debitDescendantMbps: 20,
          debitMontantMbps: 5,
          dispoPct: 0,
          connectee: false,
        ),
        montantMensuelFcfa: 45000,
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
    cases: [
      ClientCase(
        id: 'CS-2026-00395',
        categorie: 'Demande',
        motif: 'Ajout 2 lignes flotte',
        description:
            'Extension flotte Pro — 2 lignes supplémentaires sur compte maître.',
        statut: CaseStatut.enAttente,
        gravite: CaseGravite.moyenne,
        agent: 'Agent N\'Guessan Y.',
        corbeille: 'B2B - Commercial',
        createdAt: DateTime(2026, 6, 5, 10, 15),
        slaH: 72,
      ),
      ClientCase(
        id: 'CS-2026-00342',
        categorie: 'Dérangement',
        motif: 'Coupure Fibre Treichville',
        statut: CaseStatut.cloture,
        gravite: CaseGravite.critique,
        agent: 'Agent Konaté M.',
        corbeille: 'B2B - Réseau',
        createdAt: DateTime(2026, 6, 1, 8, 30),
        slaH: 4,
      ),
      ClientCase(
        id: 'CS-2026-00298',
        categorie: 'Demande',
        motif: 'Suspension lien backup',
        statut: CaseStatut.transfere,
        gravite: CaseGravite.moyenne,
        agent: 'Yaël AHODAN',
        corbeille: 'B2B - Technique',
        createdAt: DateTime(2026, 5, 28, 9, 0),
        slaH: 48,
      ),
    ],
  ),

  // ── 4. Koffi SERGE (cas multi-numéros de la spec) ────────────
  Client(
    id: 'CLI-004',
    type: 'B2C',
    nom: 'Koffi SERGE',
    numeroPrincipal: '+225 07 04 05 02 03',
    segment: 'Premium',
    statutIdentification: 'Valide',
    photoInitiales: 'KS',
    contactsAujourdhui: 1,
    scoring: Scoring(
      qualitePayeur: 'Excellent',
      segmentValeur: 'Gold',
      csi: 81,
      nps: 35,
      dernierPassageBoutique: DateTime(2026, 5, 27),
    ),
    numeros: [
      // N°1 — Principal : Mobile + Orange Money (avec coffre-fort)
      Numero(
        numero: '+225 07 04 05 02 03',
        libelle: 'Principal',
        contrats: const [
          Contrat(
            id: 'CTR-MOB-KS01',
            service: 'Mobile',
            statut: 'Actif',
            offre: 'Postpayé Liberté 30Go',
          ),
          Contrat(
            id: 'CTR-OM-KS01',
            service: 'OrangeMoney',
            statut: 'Actif',
            offre: 'Compte OM + Coffre-fort',
          ),
        ],
        consommation: Consommation(
          creditFcfa: 0,
          dataRestanteGo: 12.8,
          dataTotaleGo: 30.0,
          dataExpiration: DateTime(2026, 6, 30),
          smsRestants: 320,
          smsTotaux: 500,
          voixMinRestantes: 210,
          voixMinTotales: 300,
          passActifs: [
            PassActif(
              nom: 'Pass Data Confort 10Go',
              avantages: '10 Go internet · Valable 30 jours',
              expiration: DateTime(2026, 7, 4),
              type: PassType.data,
              prixFcfa: 5000,
            ),
            PassActif(
              nom: 'Pass Soir Illimité',
              avantages: 'Appels illimités de 20h à 6h',
              expiration: DateTime(2026, 6, 30),
              type: PassType.voix,
              prixFcfa: 1500,
            ),
            PassActif(
              nom: 'Bonus SMS Nuit',
              avantages: '100 SMS nationaux après 22h',
              expiration: DateTime(2026, 6, 30),
              type: PassType.sms,
              prixFcfa: 0,
            ),
          ],
          consoParMois: {'M-1': 22.0, 'M': 17.2},
        ),
        echeanceAbonnement: EcheanceAbonnement(
          libelle: 'Postpayé Liberté 30Go',
          renouvellement: DateTime(2026, 7, 4),
          montantFcfa: 15000,
        ),
        factures: [
          FactureRecente(
            id: 'FAC-MOB-KS-202606',
            libelle: 'Postpayé Liberté',
            periode: 'Juin 2026',
            montantFcfa: 15000,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-MOB-KS-202605',
            libelle: 'Postpayé Liberté',
            periode: 'Mai 2026',
            montantFcfa: 15000,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
        compteOM: CompteOrangeMoney(
          id: 'OM-KS-04050203',
          type: TypeCompteOM.orangeMoney,
          statut: 'Actif',
          offre: 'Compte OM Premium',
          soldeFcfa: 245700,
          plafondMensuelFcfa: 2000000,
          niveauKyc: 'KYC2 — Vérifié',
          ouvertureAt: DateTime(2022, 3, 14),
          coffre: CoffreOM(
            epargneFcfa: 850000,
            tauxAnnuelPct: 4.2,
            versementMensuelFcfa: 20000,
            prochainVersement: DateTime(2026, 7, 1),
            objectifFcfa: 1200000,
            progressionPct: 71,
          ),
          dernieresTransactions: [
            OmTransaction(label: 'Transfert vers +225 07 12 …', amountFcfa: -25000, when: 'il y a 12 min'),
            OmTransaction(label: 'Dépôt agence Cocody', amountFcfa: 50000, when: 'il y a 2 h'),
            OmTransaction(label: 'Paiement CIE', amountFcfa: -18750, when: 'hier'),
            OmTransaction(label: 'Réception salaire', amountFcfa: 250000, when: '02/06'),
          ],
        ),
      ),

      // N°2 — Domicile : Mobile + Fibre Starter
      Numero(
        numero: '+225 07 85 62 14 56',
        libelle: 'Domicile',
        contrats: const [
          Contrat(
            id: 'CTR-MOB-KS02',
            service: 'Mobile',
            statut: 'Actif',
            offre: 'Prépayé MyControl',
          ),
        ],
        consommation: Consommation(
          creditFcfa: 2300,
          dataRestanteGo: 1.2,
          dataTotaleGo: 5.0,
          dataExpiration: DateTime(2026, 6, 20),
          smsRestants: 42,
          smsTotaux: 100,
          voixMinRestantes: 95,
          voixMinTotales: 120,
          passActifs: [
            PassActif(
              nom: 'Pass Internet Hebdo 5Go',
              avantages: '5 Go internet · Valable 7 jours',
              expiration: DateTime(2026, 7, 1),
              type: PassType.data,
              prixFcfa: 2500,
            ),
            PassActif(
              nom: 'Pass Voix Maison',
              avantages: '60 min appels nationaux inclus',
              expiration: DateTime(2026, 7, 1),
              type: PassType.voix,
              prixFcfa: 1000,
            ),
            PassActif(
              nom: 'Pass SMS Famille',
              avantages: '200 SMS nationaux inclus',
              expiration: DateTime(2026, 7, 1),
              type: PassType.sms,
              prixFcfa: 500,
            ),
          ],
          consoParMois: {'M-1': 3.4, 'M': 3.8},
        ),
        // Fibre + TV de Koffi N°2 migrés vers Client.abonnementsFibre / .abonnementsTv
      ),

      // N°3 — Bureau : Mobile + Fibre Plus + Orange Banque (Visa virtuelle)
      Numero(
        numero: '+225 07 88 20 81 68',
        libelle: 'Bureau',
        contrats: const [
          Contrat(
            id: 'CTR-MOB-KS03',
            service: 'Mobile',
            statut: 'Actif',
            offre: 'Postpayé Pro 50Go',
          ),
          Contrat(
            id: 'CTR-OB-KS03',
            service: 'OrangeMoney',
            statut: 'Actif',
            offre: 'Orange Banque + Visa virtuelle',
          ),
        ],
        consommation: Consommation(
          creditFcfa: 0,
          dataRestanteGo: 41.5,
          dataTotaleGo: 50.0,
          dataExpiration: DateTime(2026, 6, 30),
          smsRestants: 870,
          smsTotaux: 1000,
          voixMinRestantes: 380,
          voixMinTotales: 500,
          passActifs: [
            PassActif(
              nom: 'Pass Voyage Afrique',
              avantages: 'Roaming inclus dans 15 pays africains · 30 j',
              expiration: DateTime(2026, 7, 10),
              type: PassType.data,
              prixFcfa: 12000,
            ),
            PassActif(
              nom: 'Pass Voix Roaming Afrique',
              avantages: 'Appels reçus gratuits · 60 min émis inclus',
              expiration: DateTime(2026, 7, 10),
              type: PassType.voix,
              prixFcfa: 5000,
            ),
            PassActif(
              nom: 'Pass SMS Pro Illimité',
              avantages: 'SMS nationaux & internationaux illimités',
              expiration: DateTime(2026, 7, 12),
              type: PassType.sms,
              prixFcfa: 3000,
            ),
          ],
          consoParMois: {'M-1': 38.0, 'M': 8.5},
        ),
        echeanceAbonnement: EcheanceAbonnement(
          libelle: 'Postpayé Pro 50Go',
          renouvellement: DateTime(2026, 7, 12),
          montantFcfa: 25000,
        ),
        factures: [
          FactureRecente(
            id: 'FAC-MOB-KS3-202606',
            libelle: 'Postpayé Pro',
            periode: 'Juin 2026',
            montantFcfa: 25000,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
        ],
        compteOM: CompteOrangeMoney(
          id: 'OB-KS-88208168',
          type: TypeCompteOM.orangeBanque,
          statut: 'Actif',
          offre: 'Orange Banque Liberté',
          soldeFcfa: 642000,
          plafondMensuelFcfa: 5000000,
          niveauKyc: 'KYC3 — Renforcé',
          ouvertureAt: DateTime(2024, 1, 22),
          visa: CarteVisaVirtuelle(
            last4: '8731',
            exp: '08/27',
            plafondMensuelFcfa: 500000,
            consommeFcfa: 142300,
            abonnementsActifs: ['Netflix', 'Spotify', 'Canal+'],
          ),
          dernieresTransactions: [
            OmTransaction(label: 'Achat Amazon.fr', amountFcfa: -34200, when: 'il y a 1 h'),
            OmTransaction(label: 'Abonnement Netflix', amountFcfa: -7900, when: 'hier'),
            OmTransaction(label: 'Virement reçu', amountFcfa: 180000, when: '05/06'),
          ],
        ),
      ),
    ],
    abonnementsFibre: [
      AbonnementFibre(
        id: 'CTR-FIB-KS02',
        adresse: 'Domicile - Riviera',
        offre: 'Fibre Starter 50 Mb/s',
        details: FixeInternetDetails(
          equipement: 'Box Orange Fibre',
          techno: 'FTTH',
          debitDescendantMbps: 100,
          debitMontantMbps: 50,
          dispoPct: 99.8,
          connectee: true,
        ),
        renouvellement: DateTime(2026, 7, 10),
        montantMensuelFcfa: 17500,
        factures: [
          FactureRecente(
            id: 'FAC-FIB-KS2-202606',
            libelle: 'Fibre Starter',
            periode: 'Juin 2026',
            montantFcfa: 17500,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-FIB-KS2-202605',
            libelle: 'Fibre Starter',
            periode: 'Mai 2026',
            montantFcfa: 17500,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
      AbonnementFibre(
        id: 'CTR-FIB-KS03',
        adresse: 'Bureau - Plateau',
        offre: 'Fibre Plus 200 Mb/s',
        details: FixeInternetDetails(
          equipement: 'Box Orange Fibre Pro',
          techno: 'FTTH',
          debitDescendantMbps: 200,
          debitMontantMbps: 100,
          dispoPct: 99.9,
          connectee: true,
        ),
        renouvellement: DateTime(2026, 7, 12),
        montantMensuelFcfa: 24900,
        factures: [
          FactureRecente(
            id: 'FAC-FIB-KS3-202606',
            libelle: 'Fibre Plus',
            periode: 'Juin 2026',
            montantFcfa: 24900,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-FIB-KS3-202605',
            libelle: 'Fibre Plus',
            periode: 'Mai 2026',
            montantFcfa: 24900,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
    ],
    abonnementsTv: [
      AbonnementTv(
        id: 'CTR-TV-KS02',
        adresse: 'Domicile - Riviera',
        details: OrangeTvDetails(
          compte: 'OTV-CI-002317',
          pack: 'Pack Sport+',
          equipement: 'Décodeur HD',
          derniereConnexion: DateTime(2026, 6, 23),
          dateInstallation: DateTime(2024, 1, 15),
          bouquets: ['Sport AFCON', 'beIN Sports', 'Généralistes'],
          options: ['TV Replay', 'Enregistrement (10 h)'],
          nbChaines: 95,
          prixMensuelFcfa: 7500,
          statut: 'Actif',
        ),
        factures: [
          FactureRecente(
            id: 'FAC-TV-KS2-202606',
            libelle: 'Pack Sport+',
            periode: 'Juin 2026',
            montantFcfa: 7500,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
        ],
      ),
      AbonnementTv(
        id: 'CTR-TV-KS03',
        adresse: 'Bureau - Plateau',
        details: OrangeTvDetails(
          compte: 'OTV-CI-002948',
          pack: 'Pack Business',
          equipement: 'Décodeur HD 4K',
          derniereConnexion: DateTime(2026, 6, 24),
          dateInstallation: DateTime(2024, 6, 2),
          bouquets: ['News & Affaires', 'International', 'Généralistes'],
          options: ['TV Replay', 'Multi-écran (3)', 'Pause direct'],
          nbChaines: 140,
          prixMensuelFcfa: 14900,
          statut: 'Actif',
        ),
        factures: [
          FactureRecente(
            id: 'FAC-TV-KS3-202606',
            libelle: 'Pack Business',
            periode: 'Juin 2026',
            montantFcfa: 14900,
            echeance: DateTime(2026, 6, 25),
            paye: false,
          ),
          FactureRecente(
            id: 'FAC-TV-KS3-202605',
            libelle: 'Pack Business',
            periode: 'Mai 2026',
            montantFcfa: 14900,
            echeance: DateTime(2026, 5, 25),
            paye: true,
          ),
        ],
      ),
    ],
    facturation: Facturation(
      montantDerniereFacture: 82400,
      echeance: DateTime(2026, 6, 25),
      paye: false,
      soldeDu: 82400,
    ),
    dernieresInteractions: [
      Interaction(
        type: 'Demande',
        date: DateTime(2026, 6, 9, 15, 30),
        statut: 'Résolu',
        resume: 'Activation carte Visa virtuelle Orange Banque.',
      ),
      Interaction(
        type: 'Appel',
        date: DateTime(2026, 6, 5, 10, 10),
        statut: 'Résolu',
        resume: 'Question sur le versement programmé du coffre-fort.',
      ),
    ],
    ia: const IaInsights(
      risqueChurnPct: 18,
      offreRecommandee: 'Pack convergence Famille (Fibre + Mobile + OB)',
      tonSuggere: 'Pro / cordial – client multi-équipé, sensible aux offres groupées',
      gesteCommercial: 'Remise 10 % sur Fibre Plus si paiement Orange Banque',
    ),
    cases: [
      ClientCase(
        id: 'CS-2026-00450',
        categorie: 'Demande',
        motif: 'Visa virtuelle plafond',
        description:
            'Demande d\'augmentation du plafond mensuel Visa virtuelle (500K → 1M F).',
        statut: CaseStatut.ouvert,
        gravite: CaseGravite.moyenne,
        agent: 'Yaël AHODAN',
        corbeille: 'OB - Cartes',
        createdAt: DateTime(2026, 6, 10, 14, 0),
        slaH: 48,
      ),
      ClientCase(
        id: 'CS-2026-00402',
        categorie: 'Réclamation',
        motif: 'Latence Fibre Bureau',
        description: 'Latence > 80 ms sur la Fibre Plus du bureau (Plateau).',
        statut: CaseStatut.enCours,
        gravite: CaseGravite.haute,
        agent: 'Agent Touré I.',
        corbeille: 'N2 - Réseau',
        createdAt: DateTime(2026, 6, 8, 9, 30),
        slaH: 24,
      ),
      ClientCase(
        id: 'CS-2026-00301',
        categorie: 'Demande',
        motif: 'Activation coffre-fort',
        statut: CaseStatut.cloture,
        gravite: CaseGravite.faible,
        agent: 'Agent N\'Goran A.',
        corbeille: 'N1 - OM',
        createdAt: DateTime(2026, 5, 27, 11, 0),
        slaH: 8,
      ),
    ],
  ),
];

/// Ordre d'affichage public — Koffi SERGE en tête pour la démo multi-numéros.
final List<Client> mockClients = [
  _mockClientsBase[3], // Koffi SERGE
  _mockClientsBase[0], // Kouadio ASSI
  _mockClientsBase[1], // Mariam TRAORÉ
  _mockClientsBase[2], // SCI ELEPHANT BTP
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
