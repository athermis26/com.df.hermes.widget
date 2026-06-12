import 'package:flutter/foundation.dart';

import '../models/conseiller.dart';

/// Session courante du conseiller connecté.
///
/// Tant que `current.value == null`, l'app affiche l'écran de connexion.
/// Pour brancher un SSO/AD plus tard : remplacer `login()` par un vrai
/// flow d'auth + récupération du profil depuis l'annuaire.
class Session {
  Session._();
  static final instance = Session._();

  final ValueNotifier<Conseiller?> current = ValueNotifier<Conseiller?>(null);

  bool get isAuthenticated => current.value != null;
  Conseiller get conseiller => current.value!;

  void login(Conseiller c) => current.value = c;
  void logout() => current.value = null;
}
