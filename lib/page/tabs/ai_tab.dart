import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/ai_wizard_trigger.dart';
import '../../core/app_icons.dart';
import '../../core/client_selection.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ticket_selection.dart';
import '../../mock/mock_case_options.dart';
import '../../models/case_draft.dart';
import '../../models/client.dart';
import '../../models/ticket.dart';
import '../../widgets/hi.dart';
import '../../core/theme/theme_controller.dart';

class AiTab extends StatefulWidget {
  const AiTab({super.key});
  @override
  State<AiTab> createState() => _AiTabState();
}

enum _Sender { user, assistant }

/// Étapes du wizard de création de case.
enum _WizardStep { off, sujet, categorie, motif, description, commentaire, recap, sending, done }

class _Msg {
  final _Sender sender;
  String text;
  final bool streaming;
  final CaseDraft? recap; // si non null, le message est rendu comme une carte récap
  _Msg(this.sender, this.text, {this.streaming = false, this.recap});
}

class _AiTabState extends State<AiTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  StreamSubscription<String>? _sub;
  bool _isStreaming = false;
  Client? _lastContext;

  _WizardStep _step = _WizardStep.off;
  CaseDraft _draft = CaseDraft();

  @override
  void initState() {
    super.initState();
    ClientSelection.instance.current.addListener(_onClientChanged);
    AiWizardTrigger.instance.createCase.addListener(_onExternalWizardRequest);
  }

  void _onExternalWizardRequest() {
    if (ClientSelection.instance.current.value == null) return;
    if (_step == _WizardStep.off || _step == _WizardStep.done) {
      _startWizard();
    }
  }

  @override
  void dispose() {
    ClientSelection.instance.current.removeListener(_onClientChanged);
    AiWizardTrigger.instance.createCase.removeListener(_onExternalWizardRequest);
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onClientChanged() {
    final c = ClientSelection.instance.current.value;
    if (c?.id != _lastContext?.id) {
      _sub?.cancel();
      setState(() {
        _messages.clear();
        _isStreaming = false;
        _lastContext = c;
        _resetWizard();
      });
    }
  }

  void _resetWizard() {
    _step = _WizardStep.off;
    _draft = CaseDraft();
  }

  // ── Wizard ─────────────────────────────────────────────────────

  void _startWizard() {
    final client = ClientSelection.instance.current.value;
    if (client == null) return;
    final ticket = TicketSelection.instance.current.value;
    setState(() {
      _resetWizard();
      _draft.clientId = client.id;
      _draft.clientNom = client.nom;
      _draft.ticketId = ticket?.id;
      _step = _WizardStep.sujet;
      _messages.add(_Msg(
        _Sender.assistant,
        'Très bien, créons une case ensemble pour ${client.nom}. Quel est le **sujet** ?',
      ));
    });
    _scrollDown();
  }

  void _cancelWizard() {
    setState(() {
      _resetWizard();
      _messages.add(_Msg(_Sender.assistant, 'D\'accord, on laisse de côté pour l\'instant.'));
    });
    _scrollDown();
  }

  void _onWizardChoice(String value) {
    if (_isStreaming) return;
    setState(() {
      _messages.add(_Msg(_Sender.user, value));
      switch (_step) {
        case _WizardStep.sujet:
          _draft.sujet = value;
          _step = _WizardStep.categorie;
          _messages.add(_Msg(_Sender.assistant,
              'Parfait : « $value ». Dans quelle **catégorie** ?'));
          break;
        case _WizardStep.categorie:
          _draft.categorie = value;
          _step = _WizardStep.motif;
          _messages.add(_Msg(_Sender.assistant,
              'Bien noté. Et le **motif précis** ?'));
          break;
        case _WizardStep.motif:
          _draft.motif = value;
          _step = _WizardStep.description;
          _messages.add(_Msg(_Sender.assistant,
              'Merci. Décrivez maintenant le problème en quelques mots.'));
          break;
        case _WizardStep.off:
        case _WizardStep.description:
        case _WizardStep.commentaire:
        case _WizardStep.recap:
        case _WizardStep.sending:
        case _WizardStep.done:
          break;
      }
    });
    _scrollDown();
  }

  void _skipCommentaire() {
    setState(() {
      _messages.add(_Msg(_Sender.user, '(pas de commentaire)'));
      _draft.commentaire = null;
      _step = _WizardStep.recap;
      _messages.add(_Msg(_Sender.assistant,
          'Voilà ce que je vais envoyer — relisez et validez :',
          recap: _draft));
    });
    _scrollDown();
  }

  Future<void> _validateCase() async {
    setState(() {
      _step = _WizardStep.sending;
      _messages.add(_Msg(_Sender.assistant, 'J\'envoie ça dans le système…'));
    });
    _scrollDown();
    await Future.delayed(Duration(milliseconds: 900 + Random().nextInt(700)));
    if (!mounted) return;
    final caseId = 'CASE-2026-${10000 + Random().nextInt(89999)}';
    setState(() {
      _step = _WizardStep.done;
      _messages.add(_Msg(
        _Sender.assistant,
        'Case **$caseId** créée. Bon courage pour la suite !',
      ));
    });
    _scrollDown();
  }

  // ── Chat libre ─────────────────────────────────────────────────

  void _send(String prompt) {
    final p = prompt.trim();
    if (p.isEmpty || _isStreaming) return;

    // Si on est dans un step texte du wizard, on capture la saisie.
    if (_step == _WizardStep.description) {
      _input.clear();
      setState(() {
        _draft.description = p;
        _messages.add(_Msg(_Sender.user, p));
        _step = _WizardStep.commentaire;
        _messages.add(_Msg(_Sender.assistant,
            'Très bien. Un commentaire à ajouter ? (optionnel)'));
      });
      _scrollDown();
      return;
    }
    if (_step == _WizardStep.commentaire) {
      _input.clear();
      setState(() {
        _draft.commentaire = p;
        _messages.add(_Msg(_Sender.user, p));
        _step = _WizardStep.recap;
        _messages.add(_Msg(_Sender.assistant,
            'Voilà ce que je vais envoyer — relisez et validez :',
            recap: _draft));
      });
      _scrollDown();
      return;
    }

    // Chat normal vers l'IA.
    final client = ClientSelection.instance.current.value;
    final ticket = TicketSelection.instance.current.value;
    _input.clear();
    setState(() {
      _messages.add(_Msg(_Sender.user, p));
      _messages.add(_Msg(_Sender.assistant, '', streaming: true));
      _isStreaming = true;
    });
    _scrollDown();

    final stream = AppServices.aiAssistantService.ask(
      p,
      clientContext: client,
      ticketContext: ticket,
    );
    _sub = stream.listen(
      (token) {
        setState(() => _messages.last.text += token);
        _scrollDown();
      },
      onDone: () {
        setState(() => _isStreaming = false);
        _scrollDown();
      },
      onError: (_) {
        setState(() {
          _messages.last.text = 'Hmm, je n\'arrive pas à répondre. On réessaie ?';
          _isStreaming = false;
        });
      },
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────

  bool get _isInputStep =>
      _step == _WizardStep.description || _step == _WizardStep.commentaire;

  bool get _isChoiceStep =>
      _step == _WizardStep.sujet ||
      _step == _WizardStep.categorie ||
      _step == _WizardStep.motif;

  List<String> _currentChoices() {
    switch (_step) {
      case _WizardStep.sujet:
        return caseSujets;
      case _WizardStep.categorie:
        return caseCategoriesParSujet[_draft.sujet] ?? const ['Autre'];
      case _WizardStep.motif:
        return caseMotifsParCategorie[_draft.categorie] ?? const ['Autre'];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Client?>(
      valueListenable: ClientSelection.instance.current,
      builder: (_, client, _) {
        return ValueListenableBuilder<Ticket?>(
          valueListenable: TicketSelection.instance.current,
          builder: (_, ticket, _) {
            return Column(
              children: [
                _ContextBar(client: client, ticket: ticket),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyState(client: client)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[i];
                            if (m.recap != null) {
                              return _RecapBubble(
                                draft: m.recap!,
                                onValidate: _step == _WizardStep.recap ? _validateCase : null,
                                onEdit: _step == _WizardStep.recap
                                    ? () {
                                        setState(() {
                                          _step = _WizardStep.sujet;
                                          _messages.add(_Msg(_Sender.assistant,
                                              'Reprenons : quel est le **sujet** ?'));
                                        });
                                        _scrollDown();
                                      }
                                    : null,
                              );
                            }
                            return _Bubble(msg: m);
                          },
                        ),
                ),
                if (client != null) _ActionBar(
                  step: _step,
                  onStart: _startWizard,
                  onCancel: _cancelWizard,
                  onSkipCommentaire: _skipCommentaire,
                ),
                if (_isChoiceStep)
                  _ChoiceChips(
                    options: _currentChoices(),
                    onTap: _onWizardChoice,
                  )
                else if (client != null && _step == _WizardStep.off)
                  _Suggestions(
                    client: client,
                    ticket: ticket,
                    onTap: _send,
                    disabled: _isStreaming,
                  ),
                _Input(
                  controller: _input,
                  enabled: !_isStreaming && !_isChoiceStep && _step != _WizardStep.sending,
                  hint: _isInputStep
                      ? (_step == _WizardStep.description
                          ? 'Décrivez le problème…'
                          : 'Commentaire (optionnel)…')
                      : 'Posez-moi une question…',
                  onSubmit: _send,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Action bar (Créer une case / Annuler / Skip) ────────────────

class _ActionBar extends StatelessWidget {
  final _WizardStep step;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onSkipCommentaire;
  const _ActionBar({
    required this.step,
    required this.onStart,
    required this.onCancel,
    required this.onSkipCommentaire,
  });

  @override
  Widget build(BuildContext context) {
    final inWizard = step != _WizardStep.off && step != _WizardStep.done;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      decoration: BoxDecoration(
        color: P.bg,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          if (!inWizard)
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Hi(AppIcons.tabActions, size: 14, color: Colors.white),
              label: const Text('Créer un Case',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (inWizard) ...[
            OutlinedButton.icon(
              onPressed: step == _WizardStep.sending ? null : onCancel,
              icon: const Hi(AppIcons.close, size: 12, color: AppColors.danger),
              label: const Text('Annuler la case', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Spacer(),
            if (step == _WizardStep.commentaire)
              TextButton(
                onPressed: onSkipCommentaire,
                style: TextButton.styleFrom(
                  foregroundColor: P.muted,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Passer cette étape',
                    style: TextStyle(fontSize: 11, decoration: TextDecoration.underline)),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Chips de choix (sujet / catégorie / motif) ──────────────────

class _ChoiceChips extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onTap;
  const _ChoiceChips({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: P.bg),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final o in options)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(o),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(o,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bulle récap de la case ──────────────────────────────────────

class _RecapBubble extends StatelessWidget {
  final CaseDraft draft;
  final VoidCallback? onValidate;
  final VoidCallback? onEdit;
  const _RecapBubble({required this.draft, this.onValidate, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Hi(AppIcons.sparkle, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: P.surface,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Hi(AppIcons.contract, size: 13, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Récap de la case',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Kv(k: 'Sujet', v: draft.sujet ?? '—'),
                  _Kv(k: 'Catégorie', v: draft.categorie ?? '—'),
                  _Kv(k: 'Motif', v: draft.motif ?? '—'),
                  _Kv(k: 'Description', v: draft.description ?? '—'),
                  if (draft.commentaire != null && draft.commentaire!.isNotEmpty)
                    _Kv(k: 'Commentaire', v: draft.commentaire!),
                  const Divider(color: Colors.white12, height: 14),
                  _Kv(k: 'Client', v: draft.clientNom ?? '—'),
                  if (draft.ticketId != null)
                    _Kv(k: 'Ticket lié', v: draft.ticketId!),
                  if (onValidate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: Hi(AppIcons.refresh, size: 12, color: P.muted),
                            label: const Text('Modifier', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: P.muted,
                              side: const BorderSide(color: Colors.white24),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: onValidate,
                            icon: const Hi(AppIcons.checkCircle, size: 12, color: Colors.white),
                            label: const Text('Valider et envoyer',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String k;
  final String v;
  const _Kv({required this.k, required this.v});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(k,
                style: TextStyle(color: P.muted, fontSize: 10)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                  color: P.text,
                  fontSize: 11,
                  height: 1.3,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Contexte ────────────────────────────────────────────────────

class _ContextBar extends StatelessWidget {
  final Client? client;
  final Ticket? ticket;
  const _ContextBar({required this.client, required this.ticket});
  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: P.surface,
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Hi(AppIcons.info, size: 14, color: P.muted),
            SizedBox(width: 6),
            Text('Aucune interaction en cours',
                style: TextStyle(color: P.muted, fontSize: 11)),
          ],
        ),
      );
    }
    final txt = ticket != null
        ? 'Contexte : ${client!.nom} · ${ticket!.motif.label}'
        : 'Contexte : ${client!.nom} · ${client!.type} · ${client!.segment}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Hi(AppIcons.sparkle, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(txt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Client? client;
  const _EmptyState({required this.client});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hi(AppIcons.sparkle, size: 42, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Assistant Hermès IA',
                style: TextStyle(
                    color: P.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              client == null
                  ? 'Trouvez d\'abord un client dans la recherche, et je vous prépare une analyse aux petits oignons.'
                  : 'Posez une question, piochez une suggestion ou cliquez sur « Créer une case » ci-dessous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: P.muted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    final bg = isUser ? AppColors.primary : P.surface;
    final fg = isUser ? Colors.white : P.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: Hi(AppIcons.sparkle, size: 12, color: Colors.white),
            ),
          if (!isUser) const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: bg,
                border: isUser ? null : Border.all(color: Colors.white10),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(isUser ? 10 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 10),
                ),
              ),
              child: msg.streaming && msg.text.isEmpty
                  ? const _TypingDots()
                  : Text(msg.text.trim(),
                      style: TextStyle(color: fg, fontSize: 12, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        Widget dot(int i) {
          final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final op = (1 - (t - 0.5).abs() * 2).clamp(0.3, 1.0);
          return Container(
            width: 5, height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: P.muted.withValues(alpha: op),
              shape: BoxShape.circle,
            ),
          );
        }
        return Row(mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1), dot(2)]);
      },
    );
  }
}

// ─── Suggestions classiques ──────────────────────────────────────

class _Suggestions extends StatelessWidget {
  final Client client;
  final Ticket? ticket;
  final ValueChanged<String> onTap;
  final bool disabled;
  const _Suggestions({
    required this.client,
    required this.ticket,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final ia = client.ia;
    final chips = <_Sugg>[
      if (ticket != null)
        _Sugg(
          'Motif : « ${ticket!.motif.label} »',
          AppIcons.tabActions,
          'Comment traiter le motif « ${ticket!.motif.label} » ?',
        ),
      _Sugg('Résume-moi tout ça', AppIcons.summarize, 'Résume la situation de ce client'),
      _Sugg('Risque de partir ?', AppIcons.churn, 'Quel est son risque de churn ?'),
      _Sugg('Une offre à proposer ?', AppIcons.offer, 'Quelle offre lui proposer ?'),
      _Sugg('Sa dernière fois ?', AppIcons.history, 'Quelle est la dernière interaction ?'),
      _Sugg('Quel ton adopter ?', AppIcons.voice, 'Quel ton dois-je adopter avec lui ?'),
      _Sugg('Un petit geste ?', AppIcons.gift, 'Quel geste commercial proposer ?'),
      _Sugg(
        'Offre IA : ${ia.offreRecommandee}',
        AppIcons.sparkle,
        'Pourquoi recommander : ${ia.offreRecommandee} ?',
      ),
    ];
    return Container(
      decoration: BoxDecoration(color: P.bg),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final s = chips[i];
            return InkWell(
              onTap: disabled ? null : () => onTap(s.prompt),
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: P.surface,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hi(s.icon, size: 12, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(s.label, style: TextStyle(color: P.text, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Sugg {
  final String label;
  final AppIcon icon;
  final String prompt;
  _Sugg(this.label, this.icon, this.prompt);
}

// ─── Input ───────────────────────────────────────────────────────

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final ValueChanged<String> onSubmit;
  const _Input({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(color: P.bg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              style: TextStyle(color: P.text, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(color: P.muted, fontSize: 11.5),
                filled: true,
                fillColor: P.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: enabled ? AppColors.primary : P.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onSubmit(controller.text) : null,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Hi(AppIcons.send, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
