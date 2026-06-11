import 'dart:math';

import '../core/formatters.dart';
import '../models/client.dart';

/// Interface de l'assistant IA.
///
/// Pour brancher un vrai LLM (Claude, GPT, modèle interne), il suffira
/// de créer une nouvelle implémentation et de remplacer celle exposée
/// dans `AppServices.aiAssistantService`.
abstract class AiAssistantService {
  /// Pose une question, en injectant éventuellement un client comme
  /// contexte. Retourne un stream de tokens (mots) pour pouvoir
  /// afficher un effet de typing.
  Stream<String> ask(String prompt, {Client? clientContext});
}

/// Impl mock — réponses pré-écrites contextualisées + effet de typing.
class MockAiAssistantService implements AiAssistantService {
  final _rand = Random();

  @override
  Stream<String> ask(String prompt, {Client? clientContext}) async* {
    final response = _pickResponse(prompt, clientContext);
    // Petite latence de "réflexion" avant le premier token
    await Future.delayed(Duration(milliseconds: 350 + _rand.nextInt(250)));
    // Streaming mot à mot pour simuler du typing
    final words = response.split(' ');
    for (final w in words) {
      await Future.delayed(Duration(milliseconds: 28 + _rand.nextInt(45)));
      yield '$w ';
    }
  }

  String _pickResponse(String prompt, Client? c) {
    if (c == null) {
      return 'Sélectionnez d\'abord un client (onglet Recherche) pour que '
          'je puisse vous fournir une analyse contextuelle.';
    }

    final p = prompt.toLowerCase();
    final ia = c.ia;

    if (_match(p, ['résume', 'resume', 'situation', 'récap', 'recap'])) {
      final recurrence = c.contactsAujourdhui > 1
          ? '⚠️ ${c.contactsAujourdhui}ᵉ contact aujourd\'hui — ton empathique recommandé. '
          : '';
      return '${c.nom} – ${c.type}, segment ${c.segment}. '
          '${c.contrats.length} contrat(s) actif(s) (${c.contrats.map((e) => e.service).toSet().join(', ')}). '
          'Payeur ${c.scoring.qualitePayeur.toLowerCase()}, CSI ${c.scoring.csi}/100. '
          'Risque de churn : ${ia.libelleChurn.toLowerCase()} (${ia.risqueChurnPct.toStringAsFixed(0)} %). '
          '$recurrence'
          'Action conseillée : ${ia.gesteCommercial.toLowerCase()}.';
    }

    if (_match(p, ['churn', 'risque', 'partir', 'résilier', 'resilier'])) {
      return 'Risque de churn estimé à ${ia.risqueChurnPct.toStringAsFixed(0)} % '
          '(${ia.libelleChurn.toLowerCase()}). Facteurs détectés : '
          '${_facteursChurn(c)}. '
          'Recommandation immédiate : ${ia.gesteCommercial.toLowerCase()}.';
    }

    if (_match(p, ['offre', 'propos', 'vendre', 'upsell', 'cross', 'recommand'])) {
      return 'Offre recommandée : **${ia.offreRecommandee}**. '
          'Argument clé : usage en hausse, segment ${c.scoring.segmentValeur}. '
          'Ton suggéré : ${ia.tonSuggere.toLowerCase()}.';
    }

    if (_match(p, ['réclamation', 'reclamation', 'dernière', 'derniere', 'historique', 'interaction'])) {
      if (c.dernieresInteractions.isEmpty) {
        return 'Aucune interaction récente n\'est remontée pour ce client.';
      }
      final last = c.dernieresInteractions.first;
      return 'Dernière interaction : ${last.type.toLowerCase()} le '
          '${formatDateHeure(last.date)}, statut « ${last.statut} ». '
          'Résumé : ${last.resume}';
    }

    if (_match(p, ['ton', 'script', 'parler', 'aborder'])) {
      return 'Ton suggéré : ${ia.tonSuggere}. '
          'Ouverture conseillée : « Bonjour ${c.nom.split(' ').first}, '
          'j\'ai bien vu votre dossier et je suis là pour vous aider. »';
    }

    if (_match(p, ['geste', 'compensation', 'cadeau', 'commercial'])) {
      return 'Geste commercial recommandé : **${ia.gesteCommercial}**. '
          'Marge d\'autonomie conseiller suffisante – pas de validation '
          'superviseur requise pour ce montant.';
    }

    if (_match(p, ['facture', 'paiement', 'impayé', 'impaye', 'solde'])) {
      final f = c.facturation;
      if (f == null) {
        return 'Ce client est en prépayé, pas de facture à analyser. '
            'Solde crédit : ${formatFcfa(c.consommation.creditFcfa)}.';
      }
      return 'Dernière facture : ${formatFcfa(f.montantDerniereFacture)}, '
          'échéance le ${formatDate(f.echeance)}, '
          '${f.paye ? 'payée ✓' : 'IMPAYÉE — solde dû ${formatFcfa(f.soldeDu)}'}.';
    }

    if (_match(p, ['data', 'forfait', 'consommation', 'conso'])) {
      final co = c.consommation;
      return 'Data : ${formatGo(co.dataRestanteGo)} restant sur '
          '${formatGo(co.dataTotaleGo)}. '
          'Crédit : ${formatFcfa(co.creditFcfa)}. SMS : ${co.smsRestants}. '
          '${co.passActifs.isEmpty ? '' : 'Pass actifs : ${co.passActifs.join(', ')}.'}';
    }

    // Fallback
    return 'Je suis votre assistant pour le dossier ${c.nom}. '
        'Vous pouvez me demander : un résumé, le risque de churn, '
        'une offre à proposer, le ton à adopter ou un détail sur la '
        'dernière interaction.';
  }

  bool _match(String prompt, List<String> keywords) =>
      keywords.any(prompt.contains);

  String _facteursChurn(Client c) {
    final f = <String>[];
    if (c.contactsAujourdhui > 1) f.add('contacts répétés');
    if (c.scoring.csi < 60) f.add('CSI bas');
    if (c.facturation != null && !c.facturation!.paye) f.add('facture impayée');
    if (c.consommation.dataRestanteGo / c.consommation.dataTotaleGo < 0.15) {
      f.add('data épuisée');
    }
    if (f.isEmpty) f.add('signaux faibles');
    return f.join(', ');
  }
}
