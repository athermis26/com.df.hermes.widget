/// Brouillon de case en cours de saisie via l'assistant IA.
/// Tous les champs sont optionnels jusqu'à la validation finale.
class CaseDraft {
  String? sujet;
  String? categorie;
  String? motif;
  String? description;
  String? commentaire;
  String? clientId;
  String? clientNom;
  String? ticketId;

  bool get isComplete =>
      sujet != null &&
      categorie != null &&
      motif != null &&
      description != null &&
      description!.trim().isNotEmpty;
}
