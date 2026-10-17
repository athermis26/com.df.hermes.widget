import 'dart:math';

import '../core/formatters.dart';
import '../models/client.dart';
import '../models/ticket.dart';

abstract class AiAssistantService {
  /// Pose une question. Le contexte client et le contexte ticket (motif,
  /// priorité, corbeille…) sont injectés pour des réponses pertinentes.
  Stream<String> ask(
    String prompt, {
    Client? clientContext,
    Ticket? ticketContext,
  });
}

class MockAiAssistantService implements AiAssistantService {
  final _rand = Random();

  @override
  Stream<String> ask(
    String prompt, {
    Client? clientContext,
    Ticket? ticketContext,
  }) async* {
    final response = _pickResponse(prompt, clientContext, ticketContext);
    await Future.delayed(Duration(milliseconds: 350 + _rand.nextInt(250)));
    for (final w in response.split(' ')) {
      await Future.delayed(Duration(milliseconds: 28 + _rand.nextInt(45)));
      yield '$w ';
    }
  }

  String _pickResponse(String prompt, Client? c, Ticket? t) {
    if (c == null) {
      return 'Sélectionnez d\'abord un client (depuis la file ou la recherche) '
          'pour que je puisse vous fournir une analyse contextuelle.';
    }

    final p = prompt.toLowerCase();
    final ia = c.ia;
    final ctxTicket = t == null
        ? ''
        : '(Ticket ${t.id} · « ${t.motif.label} » · priorité ${t.priority.label.toLowerCase()}) ';

    if (_match(p, ['résume', 'resume', 'situation', 'récap', 'recap'])) {
      final recurrence = c.contactsAujourdhui > 1
          ? 'Attention : ${c.contactsAujourdhui}ᵉ contact aujourd\'hui — ton empathique recommandé. '
          : '';
      final motifPart = t == null
          ? ''
          : 'Il vous appelle pour : ${t.motif.label.toLowerCase()} (priorité ${t.priority.label.toLowerCase()}). ';
      return '${c.nom} – ${c.type}, segment ${c.segment}. '
          '$motifPart'
          '${c.contrats.length} contrat(s) actif(s) (${c.contrats.map((e) => e.service).toSet().join(', ')}). '
          'Payeur ${c.scoring.qualitePayeur.toLowerCase()}, CSI ${c.scoring.csi}/100. '
          'Risque de churn : ${ia.libelleChurn.toLowerCase()} (${ia.risqueChurnPct.toStringAsFixed(0)} %). '
          '$recurrence'
          'Action conseillée : ${_actionForMotif(t) ?? ia.gesteCommercial.toLowerCase()}.';
    }

    if (_match(p, ['churn', 'risque', 'partir', 'résilier', 'resilier'])) {
      return '${ctxTicket}Risque de churn estimé à ${ia.risqueChurnPct.toStringAsFixed(0)} % '
          '(${ia.libelleChurn.toLowerCase()}). Facteurs détectés : '
          '${_facteursChurn(c, t)}. '
          'Recommandation immédiate : ${ia.gesteCommercial.toLowerCase()}.';
    }

    if (_match(p, ['offre', 'propos', 'vendre', 'upsell', 'cross', 'recommand'])) {
      return '${ctxTicket}Offre recommandée : **${ia.offreRecommandee}**. '
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
      return '${ctxTicket}Ton suggéré : ${ia.tonSuggere}. '
          'Ouverture conseillée : « Bonjour ${c.nom.split(' ').first}, '
          'j\'ai bien vu votre dossier et je suis là pour vous aider. »';
    }

    if (_match(p, ['geste', 'compensation', 'cadeau', 'commercial'])) {
      return '${ctxTicket}Geste commercial recommandé : **${ia.gesteCommercial}**. '
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
          '${f.paye ? 'payée' : 'IMPAYÉE — solde dû ${formatFcfa(f.soldeDu)}'}.';
    }

    if (_match(p, ['data', 'forfait', 'consommation', 'conso'])) {
      final co = c.consommation;
      return 'Data : ${formatGo(co.dataRestanteGo)} restant sur '
          '${formatGo(co.dataTotaleGo)}. '
          'Crédit : ${formatFcfa(co.creditFcfa)}. SMS : ${co.smsRestants}. '
          '${co.passActifs.isEmpty ? '' : 'Pass actifs : ${co.passActifs.map((p) => p.nom).join(', ')}.'}';
    }

    // Motif-specific
    if (t != null && _match(p, ['motif', 'pourquoi', 'demande', 'sujet'])) {
      return 'Motif du ticket : **${t.motif.label}** (priorité ${t.priority.label.toLowerCase()}). '
          '${_motifGuidance(t.motif)}';
    }

    return 'Je suis votre assistant pour le dossier ${c.nom}. '
        '${t != null ? 'Le ticket actuel concerne « ${t.motif.label} ». ' : ''}'
        'Vous pouvez me demander : un résumé, le risque de churn, '
        'une offre à proposer, le ton à adopter ou un détail sur la '
        'dernière interaction.';
  }

  bool _match(String prompt, List<String> keywords) =>
      keywords.any(prompt.contains);

  String _facteursChurn(Client c, Ticket? t) {
    final f = <String>[];
    if (c.contactsAujourdhui > 1) f.add('contacts répétés');
    if (c.scoring.csi < 60) f.add('CSI bas');
    if (c.facturation != null && !c.facturation!.paye) f.add('facture impayée');
    if (c.consommation.dataRestanteGo / c.consommation.dataTotaleGo < 0.15) {
      f.add('data épuisée');
    }
    if (t?.motif == TicketMotif.reclamationFacture) f.add('réclamation facture en cours');
    if (f.isEmpty) f.add('signaux faibles');
    return f.join(', ');
  }

  String? _actionForMotif(Ticket? t) {
    if (t == null) return null;
    switch (t.motif) {
      case TicketMotif.reclamationFacture:
        return 'examiner la facture et proposer un geste commercial si nécessaire';
      case TicketMotif.rechargeImpossible:
        return 'vérifier la ligne puis recréditer le client';
      case TicketMotif.perteSim:
        return 'lancer un SIM swap et bloquer l\'ancienne SIM';
      case TicketMotif.problemeFibre:
        return 'tester la ligne et réactiver la Fibre';
      case TicketMotif.blocageOrangeMoney:
        return 'débloquer le compte OM puis réinitialiser le code';
      case TicketMotif.demandeOffre:
        return 'présenter l\'offre recommandée par l\'IA';
      case TicketMotif.configurationApn:
        return 'envoyer les paramètres APN par SMS';
      case TicketMotif.autre:
        return null;
    }
  }

  String _motifGuidance(TicketMotif m) {
    switch (m) {
      case TicketMotif.reclamationFacture:
        return 'Vérifiez la dernière facture, comparez à la conso, et envisagez un geste si l\'écart est anormal.';
      case TicketMotif.rechargeImpossible:
        return 'Demandez le mode de recharge utilisé (PIN, OM, distributeur). Vérifiez le statut de la ligne avant tout recrédit.';
      case TicketMotif.perteSim:
        return 'Procédez à un SIM swap après vérification d\'identité, puis bloquez l\'ancienne SIM.';
      case TicketMotif.problemeFibre:
        return 'Lancez un test de ligne. Si rouge, déclenchez une intervention. Sinon, reset à distance.';
      case TicketMotif.blocageOrangeMoney:
        return 'Vérifiez la cause du blocage (3 codes erronés ? fraude ?) avant de débloquer.';
      case TicketMotif.demandeOffre:
        return 'Présentez l\'offre IA-recommandée et proposez un essai si possible.';
      case TicketMotif.configurationApn:
        return 'Envoyez les paramètres APN par SMS – l\'auto-config fait le reste.';
      case TicketMotif.autre:
        return 'Posez quelques questions pour qualifier précisément la demande.';
    }
  }
}
