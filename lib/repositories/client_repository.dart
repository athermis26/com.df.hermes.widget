import '../models/client.dart';

/// Restriction d'accès retournée par [ClientRepository.checkRestriction].
enum AccessRestriction {
  none,
  blacklist,    // numéro blacklisté → pas de recherche possible
  vipProtege,   // ligne VIP avec habilitation requise
}

/// Interface du repository client.
///
/// Pour brancher le vrai backend (ESB Booster / Datamart), il suffira
/// de créer une nouvelle implémentation `HermesClientRepository`
/// et de la fournir via l'injection de dépendances.
abstract class ClientRepository {
  Future<List<Client>> rechercher(String query);
  Future<Client?> getById(String id);
  Future<List<Client>> tous();

  /// Vérifie si la requête (numéro / identité) tombe dans une liste
  /// d'accès restreint avant même de chercher.
  Future<AccessRestriction> checkRestriction(String query);
}
