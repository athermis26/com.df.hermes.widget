// Modèles métier du widget compagnon HERMES.
// Volontairement simples (pas de json_serializable) pour le POC.

class Client {
  final String id;
  final String type; // "B2C" | "B2B"
  final String nom;
  final String numeroPrincipal;
  final String segment; // "Premium" | "Mass Market" | "PME"...
  final String statutIdentification; // "Valide" | "Non identifié"
  final int contactsAujourdhui;
  final bool vip;
  final bool blacklist;
  final String? photoInitiales; // ex "KA"
  final Scoring scoring;
  final Consommation consommation;
  final List<Contrat> contrats;
  final Facturation? facturation;
  final List<Interaction> dernieresInteractions;
  final IaInsights ia;

  const Client({
    required this.id,
    required this.type,
    required this.nom,
    required this.numeroPrincipal,
    required this.segment,
    required this.statutIdentification,
    required this.contactsAujourdhui,
    required this.scoring,
    required this.consommation,
    required this.contrats,
    required this.dernieresInteractions,
    required this.ia,
    this.facturation,
    this.vip = false,
    this.blacklist = false,
    this.photoInitiales,
  });

  bool get estPostpaye => facturation != null;
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
