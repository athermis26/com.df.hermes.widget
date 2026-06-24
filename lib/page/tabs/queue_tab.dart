import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/conseiller_state.dart';
import '../../core/panel_nav.dart';
import '../../core/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ticket_selection.dart';
import '../../mock/mock_tickets.dart';
import '../../models/conseiller.dart';
import '../../models/ticket.dart';
import '../../widgets/hi.dart';
import '../../widgets/motif_actions_sheet.dart';
import '../../widgets/motif_tag.dart';
import '../../widgets/transfer_sheet.dart';
import '../../core/theme/theme_controller.dart';

/// Strings et icônes qui varient selon le profil du conseiller.
class _ProfilUi {
  final String fileLabel;       // "Votre file" / "Comptoir agence" / "Boîte digitale"
  final String emptyLabel;      // "File vide…"
  final String unitOne;         // "ticket"
  final String unitMany;        // "tickets"
  final String nextLabel;       // "Prendre le suivant"
  final String takeLabel;       // "Prendre" / "Appeler" / "Répondre"
  final String activeLabel;     // "En ligne avec %"
  final AppIcon icon;
  final bool showCallChrono;    // chrono live uniquement Call Center

  const _ProfilUi({
    required this.fileLabel,
    required this.emptyLabel,
    required this.unitOne,
    required this.unitMany,
    required this.nextLabel,
    required this.takeLabel,
    required this.activeLabel,
    required this.icon,
    required this.showCallChrono,
  });

  static _ProfilUi from(ProfilConseiller p) {
    switch (p) {
      case ProfilConseiller.callCenter:
        return const _ProfilUi(
          fileLabel: 'Corbeille appels',
          emptyLabel: 'File vide — aucun client en attente',
          unitOne: 'interaction',
          unitMany: 'interactions',
          nextLabel: 'Appeler le suivant',
          takeLabel: 'Décrocher',
          activeLabel: 'Interaction en cours avec',
          icon: AppIcons.queue,
          showCallChrono: true,
        );
      case ProfilConseiller.agence:
        return const _ProfilUi(
          fileLabel: 'Corbeille agence',
          emptyLabel: 'Aucun client en agence pour le moment',
          unitOne: 'client',
          unitMany: 'clients',
          nextLabel: 'Appeler le suivant',
          takeLabel: 'Prendre en charge',
          activeLabel: 'Interaction en cours avec',
          icon: AppIcons.queue,
          showCallChrono: true,
        );
      case ProfilConseiller.digital:
        return const _ProfilUi(
          fileLabel: 'Corbeille digitale',
          emptyLabel: 'Aucune interaction en attente — vous êtes disponible',
          unitOne: 'message',
          unitMany: 'messages',
          nextLabel: 'Prendre le suivant',
          takeLabel: 'Prendre en charge',
          activeLabel: 'Interaction en cours avec',
          icon: AppIcons.tabNotifs,
          showCallChrono: false,
        );
      case ProfilConseiller.superviseur:
        return const _ProfilUi(
          fileLabel: 'Toutes corbeilles',
          emptyLabel: 'Aucun case en attente',
          unitOne: 'case',
          unitMany: 'cases',
          nextLabel: 'Prendre le suivant',
          takeLabel: 'Prendre en charge',
          activeLabel: 'Interaction en cours avec',
          icon: AppIcons.queue,
          showCallChrono: true,
        );
    }
  }
}

class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  late List<Ticket> _tickets;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tickets = _initialQueueForProfil();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<Ticket> _initialQueueForProfil() {
    final profil = Session.instance.current.value?.profil ??
        ProfilConseiller.callCenter;
    switch (profil) {
      case ProfilConseiller.callCenter:
        return List.of(mockTicketsCallCenter);
      case ProfilConseiller.agence:
        return List.of(mockTicketsAgence);
      case ProfilConseiller.digital:
        return List.of(mockTicketsDigital);
      case ProfilConseiller.superviseur:
        return [
          ...mockTicketsCallCenter,
          ...mockTicketsAgence,
          ...mockTicketsDigital,
        ];
    }
  }

  void _prendre(Ticket t) {
    setState(() => _tickets.removeWhere((x) => x.id == t.id));
    ConseillerState.instance.prendre(t);
    TicketSelection.instance.select(t);
  }

  void _prendreSuivant() {
    if (_tickets.isEmpty) return;
    _prendre(_tickets.first);
  }

  void _voirFiche(Ticket t) {
    TicketSelection.instance.select(t);
    PanelNav.instance.go(PanelRoute.vue360);
  }

  void _raccrocher() {
    final t = ConseillerState.instance.activeTicket.value;
    if (t != null) {
      ConseillerState.instance.raccrocher();
      TicketSelection.instance.clear();
    }
  }

  void _transfer(Ticket t) => TransferSheet.show(context, t);

  void _openAi(Ticket t) {
    TicketSelection.instance.select(t);
    PanelNav.instance.go(PanelRoute.assistant);
  }

  void _showMotifActions(Ticket t) => MotifActionsSheet.show(context, t);

  @override
  Widget build(BuildContext context) {
    final profil = Session.instance.current.value?.profil ??
        ProfilConseiller.callCenter;
    final ui = _ProfilUi.from(profil);
    return ValueListenableBuilder<Ticket?>(
      valueListenable: ConseillerState.instance.activeTicket,
      builder: (_, active, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QueueHeader(
              ui: ui,
              count: _tickets.length,
              onNext: _prendreSuivant,
              canTake: active == null,
            ),
            if (active != null)
              _ActiveCallBanner(
                ticket: active,
                ui: ui,
                onVoir: () => _voirFiche(active),
                onRaccrocher: _raccrocher,
              ),
            Expanded(
              child: _tickets.isEmpty
                  ? _EmptyQueue(message: ui.emptyLabel)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _TicketCard(
                        ticket: _tickets[i],
                        ui: ui,
                        agentBusy: active != null,
                        onPrendre: () => _prendre(_tickets[i]),
                        onTransfer: () => _transfer(_tickets[i]),
                        onAi: () => _openAi(_tickets[i]),
                        onActions: () => _showMotifActions(_tickets[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Helpers source ──────────────────────────────────────────────

({AppIcon icon, Color color, String label}) sourceMeta(TicketSource s) {
  switch (s) {
    case TicketSource.telephone:
      return (icon: AppIcons.sourcePhone, color: AppColors.primary, label: 'Appel entrant');
    case TicketSource.email:
      return (icon: AppIcons.sourceEmail, color: AppColors.info, label: 'Email');
    case TicketSource.whatsapp:
      return (icon: AppIcons.sourceWhatsapp, color: AppColors.success, label: 'WhatsApp');
    case TicketSource.facebook:
      return (icon: AppIcons.sourceFacebook, color: AppColors.info, label: 'Facebook');
    case TicketSource.twitter:
      return (icon: AppIcons.sourceTwitter, color: P.text, label: 'Twitter');
    case TicketSource.accueil:
      return (icon: AppIcons.sourceAccueil, color: AppColors.primary, label: 'Agence physique');
  }
}

// ─── Header de la file ───────────────────────────────────────────

class _QueueHeader extends StatelessWidget {
  final _ProfilUi ui;
  final int count;
  final VoidCallback onNext;
  final bool canTake;
  const _QueueHeader({
    required this.ui,
    required this.count,
    required this.onNext,
    required this.canTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Hi(ui.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ui.fileLabel,
                    style: TextStyle(color: P.muted, fontSize: 10.5)),
                Text(
                  count == 0
                      ? ui.emptyLabel
                      : '$count ${count > 1 ? ui.unitMany : ui.unitOne} en attente',
                  style: TextStyle(
                    color: P.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: (count > 0 && canTake) ? onNext : null,
            icon: const Hi(AppIcons.next, size: 14, color: Colors.white),
            label: Text(ui.nextLabel,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              disabledBackgroundColor: P.surface,
              disabledForegroundColor: P.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bannière du ticket en cours ─────────────────────────────────

class _ActiveCallBanner extends StatelessWidget {
  final Ticket ticket;
  final _ProfilUi ui;
  final VoidCallback onVoir;
  final VoidCallback onRaccrocher;
  const _ActiveCallBanner({
    required this.ticket,
    required this.ui,
    required this.onVoir,
    required this.onRaccrocher,
  });

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: ConseillerState.instance.dmtStart,
      builder: (_, start, _) {
        final dur =
            start == null ? Duration.zero : DateTime.now().difference(start);
        final color = dur >= ConseillerState.dmtTarget
            ? AppColors.danger
            : (dur >= ConseillerState.dmtWarning
                ? AppColors.warning
                : AppColors.success);
        return Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Hi(AppIcons.statusBusy, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ui.activeLabel} ${ticket.client.nom}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: P.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MotifTag(label: ticket.motif.label, dense: true),
                    ),
                  ],
                ),
              ),
              if (ui.showCallChrono)
                Text(
                  _format(dur),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Voir la fiche',
                onPressed: onVoir,
                icon: const Hi(AppIcons.identity, size: 18, color: AppColors.primary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                tooltip: 'Clôturer',
                onPressed: onRaccrocher,
                icon: const Hi(AppIcons.cloturer, size: 18, color: AppColors.danger),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Card ticket ─────────────────────────────────────────────────

class _TicketCard extends StatefulWidget {
  final Ticket ticket;
  final _ProfilUi ui;
  final bool agentBusy;
  final VoidCallback onPrendre;
  final VoidCallback onTransfer;
  final VoidCallback onAi;
  final VoidCallback onActions;

  const _TicketCard({
    required this.ticket,
    required this.ui,
    required this.agentBusy,
    required this.onPrendre,
    required this.onTransfer,
    required this.onAi,
    required this.onActions,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _hovered = false;

  ({Color color, String label}) _prioMeta(TicketPriority p) =>
      (color: _prioColor(p), label: p.label);

  Color _prioColor(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
        return AppColors.danger; // Critique
      case TicketPriority.eleve:
        return AppColors.warning; // Haute
      case TicketPriority.normal:
        return AppColors.info; // Moyenne
      case TicketPriority.faible:
        return P.muted; // Faible
    }
  }

  String _waitingLabel(Duration d) {
    if (d.inMinutes < 1) return 'à l\'instant';
    if (d.inMinutes < 60) return 'depuis ${d.inMinutes} min';
    return 'depuis ${d.inHours} h ${d.inMinutes.remainder(60)}';
  }

  @override
  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final client = ticket.client;
    final prio = _prioMeta(ticket.priority);
    final source = sourceMeta(ticket.source);
    final waiting = DateTime.now().difference(ticket.createdAt);
    final waitingColor = waiting.inMinutes >= 10
        ? AppColors.danger
        : (waiting.inMinutes >= 5 ? AppColors.warning : P.muted);
    final showSource =
        ticket.source != TicketSource.telephone && ticket.source != TicketSource.accueil;

    return LayoutBuilder(builder: (context, c) {
      // Évite les RenderFlex overflow lorsque le panel se réduit
      // (transition vers la bulle, fenêtre minimisée, etc.).
      if (c.maxWidth < 220) return const SizedBox.shrink();
      return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.agentBusy ? null : widget.onPrendre,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            client.photoInitiales ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (showSource)
                          Positioned(
                            right: -12, bottom: -8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: P.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: P.bg, width: 1),
                              ),
                              child: Hi(source.icon, size: 14, color: source.color),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  client.nom,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: P.text,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (client.vip) ...[
                                const SizedBox(width: 4),
                                const _Chip(label: 'VIP', color: AppColors.warning),
                              ],
                              const SizedBox(width: 4),
                              _Chip(label: prio.label, color: prio.color),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                        color: P.muted, fontSize: 12),
                                    children: [
                                      TextSpan(
                                        text: showSource
                                            ? source.label
                                            : client.numeroPrincipal,
                                      ),
                                      const TextSpan(text: ' · '),
                                      TextSpan(
                                        text: ticket.id,
                                        style: TextStyle(
                                          color: P.text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(child: MotifTag(label: ticket.motif.label)),
                    const Spacer(),
                    Hi(AppIcons.dmt, size: 11, color: waitingColor),
                    const SizedBox(width: 3),
                    Text(
                      'attend ${_waitingLabel(waiting)}',
                      style: TextStyle(
                        color: waitingColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Boutons secondaires : invisibles tant qu'on ne survole pas
                    // la carte (réduit la charge visuelle).
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _hovered ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_hovered,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IconAction(
                              icon: AppIcons.transferred,
                              tooltip: 'Transférer',
                              color: AppColors.info,
                              onTap: widget.onTransfer,
                            ),
                            const SizedBox(width: 6),
                            _IconAction(
                              icon: AppIcons.sparkle,
                              tooltip: 'Demander à l\'assistant',
                              color: P.text,
                              onTap: widget.onAi,
                            ),
                            const SizedBox(width: 6),
                            _IconAction(
                              icon: AppIcons.tabActions,
                              tooltip: 'Actions du motif',
                              color: AppColors.success,
                              onTap: widget.onActions,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: widget.agentBusy ? null : widget.onPrendre,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        disabledBackgroundColor: P.bg,
                        disabledForegroundColor: P.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // const Hi(AppIcons.callAccept, size: 13, color: Colors.white),
                          // const SizedBox(width: 8),
                          Text(
                            widget.ui.takeLabel,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }
}

class _IconAction extends StatelessWidget {
  final AppIcon icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Hi(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  final String message;
  const _EmptyQueue({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hi(AppIcons.allGood, size: 38, color: AppColors.success),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: P.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vous êtes disponible.',
              style: TextStyle(color: P.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
