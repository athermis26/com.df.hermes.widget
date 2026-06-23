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
import '../../widgets/motif_tag.dart';
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

class _Vue360TabState extends State<Vue360Tab>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Rafraîchit l'UI toutes les secondes (comme QueueTab)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final mobileTvContrats = client.contrats
        .where((c) => c.service == 'Mobile' || c.service == 'OrangeTV')
        .toList();
    final fixeNetContrats = client.contrats
        .where((c) =>
            c.service == 'Fixe' ||
            c.service == 'Internet' ||
            c.service == 'Fibre')
        .toList();
    final omContrats =
        client.contrats.where((c) => c.service == 'OrangeMoney').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientBar(client: client, onBack: widget.onBack),
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
        _UniverseTabBar(controller: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _DataMobileTab(
                client: client,
                contrats: mobileTvContrats,
              ),
              _FixeInternetTab(contrats: fixeNetContrats),
              _OrangeMoneyTab(client: client, contrats: omContrats),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── TabBar Univers ──────────────────────────────────────────────

class _UniverseTabBar extends StatelessWidget {
  final TabController controller;
  const _UniverseTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(bottom: BorderSide(color: P.borderSoft)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        labelColor: AppColors.primary,
        unselectedLabelColor: P.muted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelPadding: EdgeInsets.zero,
        labelStyle:
            const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        tabs: const [
          _UniverseTabLabel(icon: AppIcons.smartphone, label: 'Data & Mobile'),
          _UniverseTabLabel(icon: AppIcons.wifi, label: 'Fixe & Internet'),
          _UniverseTabLabel(icon: AppIcons.wallet, label: 'Orange Money'),
        ],
      ),
    );
  }
}

class _UniverseTabLabel extends StatelessWidget {
  final AppIcon icon;
  final String label;
  const _UniverseTabLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hi(icon, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1 : Data & Mobile ───────────────────────────────────────

class _DataMobileTab extends StatelessWidget {
  final Client client;
  final List<Contrat> contrats;
  const _DataMobileTab({required this.client, required this.contrats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      children: [
        if (client.contactsAujourdhui > 1)
          _RecurrenceBanner(count: client.contactsAujourdhui),
        _ConsommationCard(conso: client.consommation),
        if (contrats.isNotEmpty)
          _ContratsCard(title: 'Mobile & TV', contrats: contrats),
        // if (client.facturation != null)
        //   _FacturationCard(facturation: client.facturation!),
      ],
    );
  }
}

// ─── Tab 2 : Fixe & Internet ─────────────────────────────────────

class _FixeInternetTab extends StatelessWidget {
  final List<Contrat> contrats;
  const _FixeInternetTab({required this.contrats});

  @override
  Widget build(BuildContext context) {
    if (contrats.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.wifi,
        title: 'Pas d\'installation fixe',
        subtitle: 'Aucune offre Fixe, Internet ou Fibre active pour ce client.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      children: [
        _ContratsCard(title: 'Réseau & Installation', contrats: contrats),
        _FixeReseauCard(contrats: contrats),
      ],
    );
  }
}

// ─── Tab 3 : Orange Money ────────────────────────────────────────

class _OrangeMoneyTab extends StatelessWidget {
  final Client client;
  final List<Contrat> contrats;
  const _OrangeMoneyTab({required this.client, required this.contrats});

  @override
  Widget build(BuildContext context) {
    final hasOm = contrats.isNotEmpty;
    if (!hasOm) {
      return _EmptyUniverse(
        icon: AppIcons.wallet,
        title: 'Pas de compte Orange Money',
        subtitle:
            'Aucun compte Orange Money associé à ce client. Proposer l\'ouverture en agence.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      children: [
        _OmAccountCard(contrat: contrats.first),
        _OmTransactionsCard(),
        _OmVisaCard(),
        _OmCoffreCard(),
      ],
    );
  }
}

class _EmptyUniverse extends StatelessWidget {
  final AppIcon icon;
  final String title;
  final String subtitle;
  const _EmptyUniverse({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: P.bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hi(icon, color: P.muted, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: P.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: P.muted, fontSize: 10.5),
          ),
        ],
      ),
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
                    icon: const Hi(AppIcons.cloturer, size: 18, color: AppColors.danger),
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
          // Expanded(
          //   child: _MiniBtn(
          //     icon: AppIcons.sparkle,
          //     label: 'Assistant',
          //     color: AppColors.primary,
          //     onTap: () => PanelNav.instance.go(PanelRoute.assistant),
          //   ),
          // ),
          // const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.createCase,
              label: 'Créer un Case',
              color: AppColors.primary,
              onTap: () {
                PanelNav.instance.go(PanelRoute.assistant);
                // L'AiTab n'est pas encore monté à ce frame : on diffère le
                // trigger pour que son listener soit bien enregistré.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AiWizardTrigger.instance.requestCreateCase();
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.transferred,
              label: 'Transférer',
              color: AppColors.primary,
              onTap: () => TransferSheet.show(context, ticket),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _MiniBtn(
              icon: AppIcons.tabActions,
              label: 'Actions',
              color: AppColors.primary,
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
      color: color,
      borderRadius: BorderRadius.circular(8),
      elevation: 1.5,
      shadowColor: color.withValues(alpha: 0.45),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Hi(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
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
                    Flexible(child: MotifTag(label: ticket.motif.label)),
                    const SizedBox(width: 4),
                    _PrioMini(label: prio.label, color: prio.color),
                  ],
                ),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: P.muted, fontSize: 12),
                    children: [
                      TextSpan(
                        text: ticket.id,
                        style: TextStyle(
                          color: P.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' · ${ticket.corbeille}'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      title: 'Consommation',
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
  final String title;
  final List<Contrat> contrats;
  const _ContratsCard({required this.title, required this.contrats});

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
      title: '$title (${contrats.length})',
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
                _KvLine(k: 'Référence', v: contrats[i].id, valueBold: true),
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

// ─── Fixe & Internet — détails réseau (mock) ─────────────────────

class _FixeReseauCard extends StatelessWidget {
  final List<Contrat> contrats;
  const _FixeReseauCard({required this.contrats});

  @override
  Widget build(BuildContext context) {
    final hasFibre = contrats.any((c) => c.service == 'Fibre');
    final hasFixe = contrats.any((c) => c.service == 'Fixe');
    return _Section(
      icon: AppIcons.antenna,
      title: 'État de l\'installation',
      trailing: _MiniBadge(label: 'En ligne', color: AppColors.success),
      child: Column(
        children: [
          _KvLine(k: 'Type d\'accès', v: hasFibre ? 'Fibre FTTH' : 'ADSL'),
          _KvLine(k: 'Débit souscrit', v: hasFibre ? '500 Mb/s' : '20 Mb/s'),
          _KvLine(k: 'Débit mesuré', v: hasFibre ? '482 Mb/s' : '18 Mb/s'),
          _KvLine(k: 'Box', v: hasFibre ? 'Livebox Fibre 6' : 'Livebox 4'),
          _KvLine(k: 'N° de ligne', v: hasFixe ? '+225 27 22 55 88 90' : '—'),
          _KvLine(k: 'Dernier incident', v: 'Aucun (30 j)'),
        ],
      ),
    );
  }
}

// ─── Orange Money — cards mockées ────────────────────────────────

class _OmAccountCard extends StatelessWidget {
  final Contrat contrat;
  const _OmAccountCard({required this.contrat});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.wallet,
      title: 'Compte Orange Money',
      trailing: _MiniBadge(label: contrat.statut, color: AppColors.success),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Tile(label: 'Solde principal', value: '125 400 F')),
              const SizedBox(width: 6),
              Expanded(child: _Tile(label: 'Plafond mensuel', value: '2 000 000 F')),
            ],
          ),
          const SizedBox(height: 8),
          _KvLine(k: 'Offre', v: contrat.offre),
          _KvLine(k: 'Référence', v: contrat.id, valueBold: true),
          _KvLine(k: 'Niveau KYC', v: 'KYC2 — Vérifié'),
          _KvLine(k: 'Date d\'ouverture', v: '14/03/2022'),
        ],
      ),
    );
  }
}

class _OmTransactionsCard extends StatelessWidget {
  const _OmTransactionsCard();

  static const _txs = <_OmTx>[
    _OmTx(label: 'Transfert vers +225 07 12 …', amount: -25000, when: 'il y a 12 min'),
    _OmTx(label: 'Dépôt agence Cocody', amount: 50000, when: 'il y a 2 h'),
    _OmTx(label: 'Paiement CIE', amount: -18750, when: 'hier'),
    _OmTx(label: 'Retrait DAB Plateau', amount: -30000, when: 'hier'),
    _OmTx(label: 'Réception salaire', amount: 250000, when: '02/06'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.transferred,
      title: 'Dernières transactions',
      child: Column(
        children: [
          for (var i = 0; i < _txs.length; i++) ...[
            if (i != 0) Divider(height: 10, color: P.borderSoft),
            _OmTxLine(tx: _txs[i]),
          ],
        ],
      ),
    );
  }
}

class _OmTx {
  final String label;
  final int amount; // F CFA, négatif = sortant
  final String when;
  const _OmTx({required this.label, required this.amount, required this.when});
}

class _OmTxLine extends StatelessWidget {
  final _OmTx tx;
  const _OmTxLine({required this.tx});

  String _fmt(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${v < 0 ? '-' : '+'}${buf.toString()} F';
  }

  @override
  Widget build(BuildContext context) {
    final out = tx.amount < 0;
    final color = out ? AppColors.danger : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Hi(
            out ? AppIcons.sendToMobile : AppIcons.coins,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: P.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(tx.when, style: TextStyle(color: P.muted, fontSize: 9.5)),
              ],
            ),
          ),
          Text(
            _fmt(tx.amount),
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _OmVisaCard extends StatelessWidget {
  const _OmVisaCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.idCard,
      title: 'Carte virtuelle Visa',
      trailing: _MiniBadge(label: 'Active', color: AppColors.success),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFFFF7900)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'VISA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '4012  ••••  ••••  8731',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Exp. 08/27   •   CVV •••',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _KvLine(k: 'Plafond mensuel', v: '500 000 F'),
          _KvLine(k: 'Consommé', v: '142 300 F'),
          _KvLine(k: 'Abonnements actifs', v: 'Netflix · Spotify · Canal+'),
        ],
      ),
    );
  }
}

class _OmCoffreCard extends StatelessWidget {
  const _OmCoffreCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: AppIcons.lock,
      title: 'Coffre-fort Orange Money',
      trailing: _MiniBadge(label: 'Ouvert', color: AppColors.info),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Tile(label: 'Épargne totale', value: '850 000 F')),
              const SizedBox(width: 6),
              Expanded(child: _Tile(label: 'Rémunération', value: '4,2 % / an')),
            ],
          ),
          const SizedBox(height: 8),
          _KvLine(k: 'Versement programmé', v: '20 000 F / mois'),
          _KvLine(k: 'Prochain versement', v: '01/07/2026'),
          _KvLine(k: 'Objectif', v: '1 200 000 F (71 %)'),
        ],
      ),
    );
  }
}
