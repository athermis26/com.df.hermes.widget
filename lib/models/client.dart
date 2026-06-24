// Modèles métier du widget compagnon HERMÈS.
// Volontairement simples (pas de json_serializable) pour le POC.

class Client {
  final String id;
  final String type; // "B2C" | "B2B"
  final String nom;
  final String numeroPrincipal; // numéro affiché en en-tête
  final String segment; // "Premium" | "Mass Market" | "PME"...
  final String statutIdentification; // "Valide" | "Non identifié"
  final int contactsAujourdhui;
  final bool vip;
  final bool blacklist;
  final String? photoInitiales; // ex "KA"
  final Scoring scoring;

  /// Numéros téléphoniques détenus par le client.
  /// Chaque numéro porte ses propres contrats, conso, OM, etc.
  final List<Numero> numeros;

  final Facturation? facturation;
  final List<Interaction> dernieresInteractions;
  final IaInsights ia;
  final List<ClientCase> cases;

  const Client({
    required this.id,
    required this.type,
    required this.nom,
    required this.numeroPrincipal,
    required this.segment,
    required this.statutIdentification,
    required this.contactsAujourdhui,
    required this.scoring,
    required this.numeros,
    required this.dernieresInteractions,
    required this.ia,
    this.facturation,
    this.vip = false,
    this.blacklist = false,
    this.photoInitiales,
    this.cases = const [],
  });

  bool get estPostpaye => facturation != null;

  /// Agrégation des contrats de tous les numéros (compat. ascendante).
  List<Contrat> get contrats => [
        for (final n in numeros) ...n.contrats,
      ];

  /// Conso mobile du premier numéro qui en porte une (compat.).
  Consommation get consommation {
    for (final n in numeros) {
      if (n.consommation != null) return n.consommation!;
    }
    return const Consommation(
      creditFcfa: 0,
      dataRestanteGo: 0,
      dataTotaleGo: 0,
      smsRestants: 0,
      passActifs: [],
      consoParMois: {},
    );
  }

  /// Numéros éligibles à un service donné.
  List<Numero> numerosPour(NumeroService service) =>
      numeros.where((n) => n.supporte(service)).toList();
}

/// Familles de services exposées dans la Vue 360.
enum NumeroService { mobile, fixeInternet, orangeMoney }

/// Un numéro de téléphone du client + tous ses rattachements de services.
class Numero {
  /// Format affiché — ex "+225 07 04 05 02 03".
  final String numero;

  /// Libellé optionnel — ex "Domicile", "Bureau", "Principal".
  final String? libelle;

  /// Contrats rattachés à ce numéro (Mobile / Fibre / Internet / Fixe / TV / OM).
  final List<Contrat> contrats;

  /// Consommation Mobile attachée à ce numéro (null si pas de Mobile).
  final Consommation? consommation;

  /// Prochaine échéance d'abonnement (postpayé / fibre / TV).
  final EcheanceAbonnement? echeanceAbonnement;

  /// Dernières factures liées au numéro (max ~4).
  final List<FactureRecente> factures;

  /// Compte Orange Money ou Orange Banque associé (null sinon).
  final CompteOrangeMoney? compteOM;

  const Numero({
    required this.numero,
    required this.contrats,
    this.libelle,
    this.consommation,
    this.echeanceAbonnement,
    this.factures = const [],
    this.compteOM,
  });

  bool get hasMobile => contrats.any((c) => c.service == 'Mobile');
  bool get hasFixeOuInternet => contrats.any((c) =>
      c.service == 'Fixe' ||
      c.service == 'Internet' ||
      c.service == 'Fibre' ||
      c.service == 'OrangeTV');
  bool get hasOM => compteOM != null;

  bool supporte(NumeroService s) {
    switch (s) {
      case NumeroService.mobile:
        return hasMobile;
      case NumeroService.fixeInternet:
        return hasFixeOuInternet;
      case NumeroService.orangeMoney:
        return hasOM;
    }
  }
}

class Scoring {
  final String qualitePayeur; // "Excellent" | "Bon" | "Risque"
  final String segmentValeur; // "Gold" | "Silver" | "Bronze"
  final int csi; // 0-100
  final int nps; // -100..100
  final DateTime? dernierPassageBoutique;

  const Scoring({
    required this.qualitePayeur,
    required this.segmentValeur,
    required this.csi,
    required this.nps,
    this.dernierPassageBoutique,
  });
}

class Consommation {
  final int creditFcfa;
  final double dataRestanteGo;
  final double dataTotaleGo;
  final DateTime? dataExpiration;
  final int smsRestants;
  final List<String> passActifs;
  final Map<String, double> consoParMois; // {"M-1": .., "M": ..}

  const Consommation({
    required this.creditFcfa,
    required this.dataRestanteGo,
    required this.dataTotaleGo,
    required this.smsRestants,
    required this.passActifs,
    required this.consoParMois,
    this.dataExpiration,
  });
}

class Contrat {
  final String id;
  final String service; // Mobile | Fixe | Internet | Fibre | OrangeTV | OrangeMoney
  final String statut; // Actif | Suspendu | Résilié
  final String offre;

  const Contrat({
    required this.id,
    required this.service,
    required this.statut,
    required this.offre,
  });
}

/// Prochaine échéance d'un abonnement (post-payé Mobile, Fibre, TV...).
class EcheanceAbonnement {
  final String libelle; // ex "Fibre 500 Mb/s" / "Postpayé Privilège"
  final DateTime renouvellement;
  final int montantFcfa;
  final bool autoRenouvellement;

  const EcheanceAbonnement({
    required this.libelle,
    required this.renouvellement,
    required this.montantFcfa,
    this.autoRenouvellement = true,
  });
}

/// Facture liée à un numéro (recap court pour l'onglet service).
class FactureRecente {
  final String id;
  final String libelle; // ex "Fibre 500 Mb/s"
  final String periode; // ex "Juin 2026"
  final int montantFcfa;
  final DateTime echeance;
  final bool paye;

  const FactureRecente({
    required this.id,
    required this.libelle,
    required this.periode,
    required this.montantFcfa,
    required this.echeance,
    required this.paye,
  });
}

class Facturation {
  final double montantDerniereFacture;
  final DateTime echeance;
  final bool paye;
  final double soldeDu;

  const Facturation({
    required this.montantDerniereFacture,
    required this.echeance,
    required this.paye,
    required this.soldeDu,
  });
}

class Interaction {
  final String type; // Réclamation | Demande | Dérangement | Appel
  final DateTime date;
  final String statut; // Ouvert | Résolu | En cours
  final String resume;

  const Interaction({
    required this.type,
    required this.date,
    required this.statut,
    required this.resume,
  });
}

// ─── Orange Money / Orange Banque ────────────────────────────────

enum TypeCompteOM {
  /// Compte Orange Money classique.
  orangeMoney,

  /// Compte Orange Banque (peut porter une carte virtuelle Visa).
  orangeBanque,
}

extension TypeCompteOMX on TypeCompteOM {
  String get label => this == TypeCompteOM.orangeBanque ? 'Orange Banque' : 'Orange Money';
  String get shortLabel => this == TypeCompteOM.orangeBanque ? 'OB' : 'OM';
}

class CompteOrangeMoney {
  final String id;
  final TypeCompteOM type;
  final String statut; // Actif | Suspendu
  final String offre;
  final int soldeFcfa;
  final int plafondMensuelFcfa;
  final String niveauKyc; // ex "KYC2 — Vérifié"
  final DateTime ouvertureAt;
  final CoffreOM? coffre;
  final CarteVisaVirtuelle? visa; // uniquement si type == orangeBanque
  final List<OmTransaction> dernieresTransactions;

  const CompteOrangeMoney({
    required this.id,
    required this.type,
    required this.statut,
    required this.offre,
    required this.soldeFcfa,
    required this.plafondMensuelFcfa,
    required this.niveauKyc,
    required this.ouvertureAt,
    this.coffre,
    this.visa,
    this.dernieresTransactions = const [],
  });
}

class CoffreOM {
  final int epargneFcfa;
  final double tauxAnnuelPct;
  final int versementMensuelFcfa;
  final DateTime prochainVersement;
  final int objectifFcfa;
  final int progressionPct;

  const CoffreOM({
    required this.epargneFcfa,
    required this.tauxAnnuelPct,
    required this.versementMensuelFcfa,
    required this.prochainVersement,
    required this.objectifFcfa,
    required this.progressionPct,
  });
}

class CarteVisaVirtuelle {
  final String last4;
  final String exp; // "08/27"
  final int plafondMensuelFcfa;
  final int consommeFcfa;
  final List<String> abonnementsActifs;

  const CarteVisaVirtuelle({
    required this.last4,
    required this.exp,
    required this.plafondMensuelFcfa,
    required this.consommeFcfa,
    this.abonnementsActifs = const [],
  });
}

class OmTransaction {
  final String label;
  final int amountFcfa; // < 0 = sortant
  final String when;
  const OmTransaction({
    required this.label,
    required this.amountFcfa,
    required this.when,
  });
}

// ─── Cases ───────────────────────────────────────────────────────

/// Statuts repris du web : Ouvert | En cours | Transféré | En attente | Clôturé | Annulé.
enum CaseStatut { ouvert, enCours, transfere, enAttente, cloture, annule }

extension CaseStatutX on CaseStatut {
  String get label {
    switch (this) {
      case CaseStatut.ouvert:
        return 'Ouvert';
      case CaseStatut.enCours:
        return 'En cours';
      case CaseStatut.transfere:
        return 'Transféré';
      case CaseStatut.enAttente:
        return 'En attente';
      case CaseStatut.cloture:
        return 'Clôturé';
      case CaseStatut.annule:
        return 'Annulé';
    }
  }

  bool get isActive =>
      this == CaseStatut.ouvert || this == CaseStatut.enCours;
}

enum CaseGravite { faible, moyenne, haute, critique }

extension CaseGraviteX on CaseGravite {
  String get label {
    switch (this) {
      case CaseGravite.faible:
        return 'Faible';
      case CaseGravite.moyenne:
        return 'Moyenne';
      case CaseGravite.haute:
        return 'Haute';
      case CaseGravite.critique:
        return 'Critique';
    }
  }
}

/// Dossier client persistant (équivalent du « case » côté web).
class ClientCase {
  final String id;
  final String categorie;
  final String motif;
  final String? description;
  final CaseStatut statut;
  final CaseGravite gravite;
  final String agent;
  final String corbeille;
  final DateTime createdAt;
  final int slaH;
  final DateTime? deadline;

  const ClientCase({
    required this.id,
    required this.categorie,
    required this.motif,
    required this.statut,
    required this.gravite,
    required this.agent,
    required this.corbeille,
    required this.createdAt,
    this.slaH = 48,
    this.deadline,
    this.description,
  });
}

class IaInsights {
  final double risqueChurnPct; // 0..100
  final String offreRecommandee;
  final String tonSuggere;
  final String gesteCommercial;

  const IaInsights({
    required this.risqueChurnPct,
    required this.offreRecommandee,
    required this.tonSuggere,
    required this.gesteCommercial,
  });

  String get libelleChurn {
    if (risqueChurnPct < 25) return 'Faible';
    if (risqueChurnPct < 60) return 'Moyen';
    return 'Élevé';
  }
}
