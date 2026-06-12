// Options du wizard de création de case (mock).
// Pour brancher le vrai référentiel : remplacer ces maps par un appel
// au repo « CaseRefRepository ».

const List<String> caseSujets = [
  'Mobile',
  'Fixe / Fibre',
  'Orange Money',
  'Facturation',
  'TV',
];

const Map<String, List<String>> caseCategoriesParSujet = {
  'Mobile': ['Réseau', 'Recharge', 'Identification', 'Roaming'],
  'Fixe / Fibre': ['Coupure', 'Lenteur', 'Installation', 'Résiliation'],
  'Orange Money': ['Compte bloqué', 'Code oublié', 'Transaction', 'Frais'],
  'Facturation': ['Erreur de facture', 'Retard de paiement', 'Réclamation'],
  'TV': ['Pas de signal', 'Chaînes manquantes', 'Bouquet'],
};

const Map<String, List<String>> caseMotifsParCategorie = {
  // Mobile
  'Réseau': ['Pas de signal', 'Lenteur', 'Coupures répétées'],
  'Recharge': ['Recharge non créditée', 'Carte invalide', 'Plafond atteint'],
  'Identification': ['Identité expirée', 'Photo refusée', 'Doublon'],
  'Roaming': ['Activation', 'Tarifs anormaux'],
  // Fixe / Fibre
  'Coupure': ['Totale', 'Intermittente', 'Programmée'],
  'Lenteur': ['Débit faible', 'Latence élevée'],
  'Installation': ['Date à planifier', 'Technicien absent'],
  'Résiliation': ['Demande client', 'Déménagement'],
  // OM
  'Compte bloqué': ['3 codes erronés', 'Soupçon de fraude'],
  'Code oublié': ['Reset demandé'],
  'Transaction': ['Non aboutie', 'Doublonnée', 'Montant erroné'],
  'Frais': ['Contestation', 'Demande de remboursement'],
  // Facturation
  'Erreur de facture': ['Montant', 'Période', 'Service facturé'],
  'Retard de paiement': ['Demande de délai', 'Plan de paiement'],
  'Réclamation': ['Service non rendu', 'Surfacturation'],
  // TV
  'Pas de signal': ['Décodeur', 'Bouquet'],
  'Chaînes manquantes': ['Mise à jour bouquet'],
  'Bouquet': ['Changement', 'Ajout option'],
};
