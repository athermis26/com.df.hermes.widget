import 'dart:math';

import '../models/client.dart';
import '../mock/mock_data.dart';
import 'client_repository.dart';

/// Implémentation **mock** du repository client.
/// - Données en mémoire (voir [mockClients]).
/// - Latence artificielle (300-800 ms) pour simuler les APIs Booster.
class MockClientRepository implements ClientRepository {
  final _rand = Random();

  Future<void> _fakeLatency() async {
    final ms = 300 + _rand.nextInt(500);
    await Future.delayed(Duration(milliseconds: ms));
  }

  @override
  Future<List<Client>> tous() async {
    await _fakeLatency();
    return List.unmodifiable(mockClients);
  }

  @override
  Future<Client?> getById(String id) async {
    await _fakeLatency();
    try {
      return mockClients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Client>> rechercher(String query) async {
    await _fakeLatency();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final qDigits = q.replaceAll(RegExp(r'\s'), '');
    return mockClients.where((c) {
      return c.nom.toLowerCase().contains(q) ||
          c.numeroPrincipal
              .toLowerCase()
              .replaceAll(RegExp(r'\s'), '')
              .contains(qDigits) ||
          c.id.toLowerCase().contains(q) ||
          c.contrats.any((ct) => ct.id.toLowerCase().contains(q));
    }).toList(growable: false);
  }

  @override
  Future<AccessRestriction> checkRestriction(String query) async {
    final q = query.replaceAll(RegExp(r'\s'), '');
    bool match(List<String> list) =>
        list.any((n) => n.replaceAll(RegExp(r'\s'), '') == q);
    if (match(mockBlacklist)) return AccessRestriction.blacklist;
    if (match(mockVipProteges)) return AccessRestriction.vipProtege;
    return AccessRestriction.none;
  }
}
