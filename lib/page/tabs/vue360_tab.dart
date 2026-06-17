import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ai_wizard_trigger.dart';
import '../../core/app_icons.dart';
import '../../core/conseiller_state.dart';
import '../../core/formatters.dart';
import '../../core/panel_nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ticket_selection.dart';
import '../../models/client.dart';
import '../../models/ticket.dart';
import '../../widgets/hi.dart';
import '../../widgets/motif_actions_sheet.dart';
import '../../widgets/transfer_sheet.dart';
import '../../core/theme/theme_controller.dart';

/// Mini Vue 360 — fiche client compacte, scrollable, cartes repliables.
class Vue360Tab extends StatefulWidget {
  final Client client;
  final VoidCallback onBack;

  const Vue360Tab({
    super.key,
    required this.client,
    required this.onBack,
  });

  @override
  State<Vue360Tab> createState() => _Vue360TabState();
}

class _Vue360TabState extends State<Vue360Tab> {
  Timer? _timer;
  late final ValueNotifier<DateTime?> _dmtStart;

  @override
  void initState() {
    super.initState();
    _dmtStart = ConseillerState.instance.dmtStart;
    // Rafraîchit l'UI toutes les secondes (comme QueueTab)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientBar(client: widget.client, onBack: widget.onBack),
        ValueListenableBuilder<Ticket?>(
          valueListenable: TicketSelection.instance.current,
          builder: (_, ticket, _) {
            if (ticket == null) return const SizedBox.shrink();
            return Column(
              children: [
                _TicketBanner(ticket: ticket),
                _Vue360QuickActions(ticket: ticket),
              ],
            );
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            children: [
              if (widget.client.contactsAujourdhui > 1)
                _RecurrenceBanner(count: widget.client.contactsAujourdhui),
              _IdentiteCard(client: widget.client),
              _ScoringCard(scoring: widget.client.scoring),
              _ConsommationCard(conso: widget.client.consommation),
              _ContratsCard(contrats: widget.client.contrats),
              if (widget.client.facturation != null)
                _FacturationCard(facturation: widget.client.facturation!),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header client ───────────────────────────────────────────────

class _ClientBar extends StatelessWidget {
  final Client client;
  final VoidCallback onBack;
  const _ClientBar({required this.client, required this.onBack});

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  void onRaccrocher() {
    final t = ConseillerState.instance.activeTicket.value;
    if (t != null) {
      ConseillerState.instance.raccrocher();
      TicketSelection.instance.clear();
    }
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
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: P.surface,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [

              IconButton(
                tooltip: 'Retour',
                icon: Hi(AppIcons.back, color: P.text, size: 18),
                onPressed: onBack,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  client.photoInitiales ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      client.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: P.text, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${client.type} • ${client.segment} • ${client.numeroPrincipal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: P.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (client.vip)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('VIP',
                      style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w700)),
                ),

              const SizedBox(width: 8),

              Row(
                spacing: 8,
                children: [
                  Text(
                    _format(dur),
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Clôturer',
                    onPressed: onRaccrocher,
                    icon: const Hi(AppIcons.callReject, size: 18, color: AppColors.danger),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

// ─── Barre d'actions rapides ─────────────────────────────────────

class _Vue360QuickActions extends StatelessWidget {
  final Ticket ticket;
  const _Vue360QuickActions({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: P.bg,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.sparkle,
              label: 'Assistant',
              color: AppColors.primary,
              onTap: () => PanelNav.instance.push(PanelRoute.assistant),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.createCase,
              label: 'Créer un Case',
              color: AppColors.info,
              onTap: () {
                PanelNav.instance.push(PanelRoute.assistant);
                AiWizardTrigger.instance.requestCreateCase();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.transferred,
              label: 'Transférer',
              color: AppColors.warning,
              onTap: () => TransferSheet.show(context, ticket),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.tabActions,
              label: 'Actions',
              color: AppColors.success,
              onTap: () => MotifActionsSheet.show(context, ticket),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hi(icon, size: 14, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bandeau ticket en cours ─────────────────────────────────────

class _TicketBanner extends StatelessWidget {
  final Ticket ticket;
  const _TicketBanner({required this.ticket});

  ({Color color, String label}) _prioMeta(TicketPriority p) {
    switch (p) {
      case TicketPriority.urgent:
        return (color: AppColors.danger, label: 'Urgent');
      case TicketPriority.eleve:
        return (color: AppColors.warning, label: 'Élevée');
      case TicketPriority.normal:
        return (color: AppColors.info, label: 'Normale');
      case TicketPriority.faible:
        return (color: P.muted, label: 'Faible');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prio = _prioMeta(ticket.priority);
    final isActive =
        ConseillerState.instance.activeTicket.value?.id == ticket.id;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: P.bg,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Hi(
            isActive ? AppIcons.statusBusy : AppIcons.tabActions,
            size: 13,
            color: isActive ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ticket.motif.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: P.text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _PrioMini(label: prio.label, color: prio.color),
                  ],
                ),
                Text(
                  '${ticket.id} · ${ticket.corbeille}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: P.muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioMini extends StatelessWidget {
  final String label;
  final Color color;
  const _PrioMini({required this.label, required this.color});
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

// ─── Bandeau client récurrent ────────────────────────────────────

class _RecurrenceBanner extends StatefulWidget {
  final int count;
  const _RecurrenceBanner({required this.count});
  @override
  State<_RecurrenceBanner> createState() => _RecurrenceBannerState();
}

class _RecurrenceBannerState extends State<_RecurrenceBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_ctrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.danger),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Hi(AppIcons.alertRecurrence, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Client multicontact — ${widget.count} contacts aujourd\'hui',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte repliable réutilisable ────────────────────────────────

class _Section extends StatefulWidget {
  final AppIcon icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  Hi(widget.icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: P.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                  Hi(
                    _open ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 14,
                    color: P.muted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: widget.child,
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

// ─── Identité ────────────────────────────────────────────────────

class _IdentiteCard extends StatelessWidget {
  final Client client;
  const _IdentiteCard({required this.client});
  @override
  Widget build(BuildContext context) {
    final identifie = client.statutIdentification == 'Valide';
    return _Section(
      icon: AppIcons.identity,
      title: 'Identité Client',
      trailing: _MiniBadge(
        label: identifie ? 'Identifié' : 'Non identifié',
        color: identifie ? AppColors.success : AppColors.danger,
      ),
      child: Column(
        children: [
          _KvLine(k: 'Type', v: client.type),
          _KvLine(k: 'Segment', v: client.segment),
          _KvLine(k: 'MSISDN', v: client.numeroPrincipal),
          _KvLine(k: 'Réf. IDBASE', v: client.id),
        ],
      ),
    );
  }
}

// ─── Scoring ─────────────────────────────────────────────────────

class _ScoringCard extends StatelessWidget {
  final Scoring scoring;
  const _ScoringCard({required this.scoring});

  Color _payeurColor(String s) {
    switch (s) {
      case 'Excellent':
        return AppColors.success;
      case 'Bon':
        return AppColors.info;
      case 'Risque':
        return AppColors.danger;
      default:
        return P.muted;
    }
  }

  Color _valueColor(String s) {
    switch (s) {
      case 'Gold':
        return AppColors.warning;
      case 'Silver':
        return P.muted;
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return P.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.scoring,
      title: 'Scoring & Fidélité',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ScoringBadge(label: 'Score qualité payeur', value: scoring.qualitePayeur, color: _payeurColor(scoring.qualitePayeur))),
              const SizedBox(width: 6),
              Expanded(child: _ScoringBadge(label: 'Segment valeur', value: scoring.segmentValeur, color: _valueColor(scoring.segmentValeur))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Gauge(label: 'Score CSI', value: scoring.csi, max: 100, color: AppColors.primary)),
              const SizedBox(width: 6),
              Expanded(child: _Gauge(label: 'NPS', value: scoring.nps + 100, max: 200, displayValue: scoring.nps, color: AppColors.info)),
            ],
          ),
          if (scoring.dernierPassageBoutique != null) ...[
            const SizedBox(height: 8),
            _KvLine(k: 'Dernière visite', v: formatDate(scoring.dernierPassageBoutique!)),
          ],
        ],
      ),
    );
  }
}

class _ScoringBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoringBadge({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: P.muted, fontSize: 9.5)),
          const SizedBox(height: 1),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final int? displayValue;
  final Color color;
  const _Gauge({required this.label, required this.value, required this.max, this.displayValue, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: P.muted, fontSize: 9.5))),
            Text(
              '${displayValue ?? value}',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0, 1),
            minHeight: 5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Consommation ────────────────────────────────────────────────

class _ConsommationCard extends StatelessWidget {
  final Consommation conso;
  const _ConsommationCard({required this.conso});

  @override
  Widget build(BuildContext context) {
    final dataPct = conso.dataTotaleGo == 0 ? 0.0 : conso.dataRestanteGo / conso.dataTotaleGo;
    final dataColor = dataPct < 0.15
        ? AppColors.danger
        : dataPct < 0.35
            ? AppColors.warning
            : AppColors.success;
    return _Section(
      icon: AppIcons.consumption,
      title: 'Services & Consommation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Tile(label: 'Crédit', value: formatFcfa(conso.creditFcfa))),
              const SizedBox(width: 6),
              Expanded(child: _Tile(label: 'SMS restants', value: '${conso.smsRestants}')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Internet', style: TextStyle(color: P.muted, fontSize: 10.5)),
              const Spacer(),
              Text(
                '${formatGo(conso.dataRestanteGo)} sur ${formatGo(conso.dataTotaleGo)}',
                style: TextStyle(color: dataColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dataPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(dataColor),
            ),
          ),
          if (conso.dataExpiration != null) ...[
            const SizedBox(height: 4),
            Text(
              'Valable jusqu\'au ${formatDate(conso.dataExpiration!)}',
              style: TextStyle(color: P.muted, fontSize: 9.5),
            ),
          ],
          const SizedBox(height: 10),
          if (conso.passActifs.isNotEmpty) ...[
            Text('Pass actifs', style: TextStyle(color: P.muted, fontSize: 10.5)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final p in conso.passActifs)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _MiniBarChart(values: conso.consoParMois),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final Map<String, double> values;
  const _MiniBarChart({required this.values});
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.values.reduce((a, b) => a > b ? a : b);
    final entries = values.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consommation mensuelle', style: TextStyle(color: P.muted, fontSize: 10.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (entries[i].value / max).clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == entries.length - 1 ? AppColors.primary : Colors.white24,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entries[i].key} • ${formatGo(entries[i].value)}',
                        style: TextStyle(color: P.muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                if (i != entries.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Contrats ────────────────────────────────────────────────────

class _ContratsCard extends StatelessWidget {
  final List<Contrat> contrats;
  const _ContratsCard({required this.contrats});

  AppIcon _iconFor(String service) {
    switch (service) {
      case 'Mobile':
        return AppIcons.smartphone;
      case 'Fixe':
        return AppIcons.landline;
      case 'Internet':
      case 'Fibre':
        return AppIcons.wifi;
      case 'OrangeTV':
        return AppIcons.tv;
      case 'OrangeMoney':
        return AppIcons.wallet;
      default:
        return AppIcons.contracts;
    }
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'Actif':
        return AppColors.success;
      case 'Suspendu':
        return AppColors.warning;
      case 'Résilié':
        return AppColors.danger;
      default:
        return P.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.contracts,
      title: 'Contrats (${contrats.length})',
      child: Column(
        children: [
          for (var i = 0; i < contrats.length; i++) ...[
            if (i != 0) const Divider(height: 12, color: Colors.white10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 6),
              collapsedShape: const Border(),
              shape: const Border(),
              dense: true,
              visualDensity: VisualDensity.compact,
              iconColor: P.muted,
              collapsedIconColor: P.muted,
              title: Row(
                children: [
                  Hi(_iconFor(contrats[i].service), size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contrats[i].service,
                      style: TextStyle(color: P.text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _MiniBadge(label: contrats[i].statut, color: _statutColor(contrats[i].statut)),
                ],
              ),
              subtitle: Text(
                contrats[i].offre,
                style: TextStyle(color: P.muted, fontSize: 10.5),
              ),
              children: [
                _KvLine(k: 'Référence', v: contrats[i].id),
                _KvLine(k: 'Offre', v: contrats[i].offre),
                _KvLine(k: 'Statut', v: contrats[i].statut),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Facturation ─────────────────────────────────────────────────

class _FacturationCard extends StatelessWidget {
  final Facturation facturation;
  const _FacturationCard({required this.facturation});
  @override
  Widget build(BuildContext context) {
    final paye = facturation.paye;
    return _Section(
      icon: AppIcons.billing,
      title: 'Facturation',
      trailing: _MiniBadge(
        label: paye ? 'Réglé' : 'En attente',
        color: paye ? AppColors.success : AppColors.danger,
      ),
      child: Column(
        children: [
          _KvLine(k: 'Dernière facture', v: formatFcfa(facturation.montantDerniereFacture)),
          _KvLine(k: 'Échéance', v: formatDate(facturation.echeance)),
          if (facturation.soldeDu > 0)
            _KvLine(
              k: 'Solde dû',
              v: formatFcfa(facturation.soldeDu),
              valueColor: AppColors.danger,
              valueBold: true,
            ),
        ],
      ),
    );
  }
}

// ─── Petits widgets génériques ───────────────────────────────────

class _KvLine extends StatelessWidget {
  final String k;
  final String v;
  final Color? valueColor;
  final bool valueBold;
  const _KvLine({required this.k, required this.v, this.valueColor, this.valueBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(color: P.muted, fontSize: 10.5)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: valueColor ?? P.text,
                fontSize: 11.5,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: P.muted, fontSize: 9.5)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: P.text, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
    );
  }
}
