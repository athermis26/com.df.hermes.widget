import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'services.dart';

/// État de la barre de recherche persistante du header.
/// L'overlay de résultats écoute ce controller.
class HermesSearch {
  HermesSearch._();
  static final instance = HermesSearch._();

  final ValueNotifier<String> query = ValueNotifier('');
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<List<Client>> results = ValueNotifier(const []);
  final ValueNotifier<AccessRestriction> restriction =
      ValueNotifier(AccessRestriction.none);
  final ValueNotifier<bool> open = ValueNotifier(false);

  Timer? _debounce;
  String _lastFired = '';

  void setQuery(String q) {
    query.value = q;
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      _lastFired = '';
      loading.value = false;
      results.value = const [];
      restriction.value = AccessRestriction.none;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q.trim()));
  }

  Future<void> _run(String q) async {
    _lastFired = q;
    loading.value = true;
    final r = await AppServices.clientRepository.checkRestriction(q);
    if (q != _lastFired) return;
    if (r != AccessRestriction.none) {
      loading.value = false;
      results.value = const [];
      restriction.value = r;
      return;
    }
    final res = await AppServices.clientRepository.rechercher(q);
    if (q != _lastFired) return;
    loading.value = false;
    restriction.value = AccessRestriction.none;
    results.value = res;
  }

  void clear() {
    _debounce?.cancel();
    _lastFired = '';
    query.value = '';
    loading.value = false;
    results.value = const [];
    restriction.value = AccessRestriction.none;
  }
}
