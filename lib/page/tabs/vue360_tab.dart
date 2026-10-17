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
import '../../models/quick_action.dart';
import '../../models/ticket.dart';
import '../../mock/mock_actions.dart';
import '../../widgets/action_sheet.dart';
import '../../widgets/hi.dart';
import '../../widgets/motif_actions_sheet.dart';
import '../../widgets/motif_tag.dart';
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
    _tabs = TabController(length: 5, vsync: this);
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
              _DataMobileTab(client: client),
              _OrangeMoneyTab(client: client),
              _FixeInternetTab(client: client),
              _TvTab(client: client),
              _CasesTab(client: client),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Composant chips réutilisable — sélection numéro par onglet ──

class _NumeroChipsBar extends StatelessWidget {
  final List<Numero> numeros;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _NumeroChipsBar({
    required this.numeros,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(bottom: BorderSide(color: P.borderSoft)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: numeros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _NumeroChip(
          numero: numeros[i],
          active: i == selectedIndex,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _NumeroChip extends StatelessWidget {
  final Numero numero;
  final bool active;
  final VoidCallback onTap;
  const _NumeroChip({
    required this.numero,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: active ? AppColors.primary : P.borderSoft,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                numero.numero,
                style: TextStyle(
                  color: active ? Colors.white : P.text,
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (numero.libelle != null)
                Text(
                  numero.libelle!,
                  style: TextStyle(
                    color: active
                        ? Colors.white.withValues(alpha: 0.85)
                        : P.muted,
                    fontSize: 8.5,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
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
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        labelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        tabs: const [
          _UniverseTabLabel(icon: AppIcons.smartphone, label: 'Mobile'),
          _UniverseTabLabel(icon: AppIcons.wallet, label: 'Orange Money'),
          _UniverseTabLabel(icon: AppIcons.wifi, label: 'Fibre'),
          _UniverseTabLabel(icon: AppIcons.tv, label: 'TV'),
          _UniverseTabLabel(icon: AppIcons.contracts, label: 'Cases'),
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
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Hi(icon, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1 : Data & Mobile ───────────────────────────────────────

class _DataMobileTab extends StatefulWidget {
  final Client client;
  const _DataMobileTab({required this.client});

  @override
  State<_DataMobileTab> createState() => _DataMobileTabState();
}

class _DataMobileTabState extends State<_DataMobileTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final numeros = widget.client.numerosPour(NumeroService.mobile);
    if (numeros.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.smartphone,
        title: 'Aucun numéro Mobile',
        subtitle: 'Ce client ne possède aucune offre Mobile active.',
      );
    }
    final idx = _selectedIndex.clamp(0, numeros.length - 1);
    final selected = numeros[idx];
    final conso = selected.consommation ?? widget.client.consommation;

    return Column(
      children: [
        _NumeroChipsBar(
          numeros: numeros,
          selectedIndex: idx,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            children: [
              if (widget.client.contactsAujourdhui > 1)
                _RecurrenceBanner(count: widget.client.contactsAujourdhui),
              _MobileLineCard(
                numero: selected,
                conso: conso,
                client: widget.client,
              ),
              // if (mobileContrats.isNotEmpty)
              //   _ContratsCard(title: 'Mobile', contrats: mobileContrats),
              // if (selected.echeanceAbonnement != null)
              //   _EcheanceCard(echeance: selected.echeanceAbonnement!),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 2 : Fibre (abonnements au niveau client) ────────────────

class _FixeInternetTab extends StatefulWidget {
  final Client client;
  const _FixeInternetTab({required this.client});

  @override
  State<_FixeInternetTab> createState() => _FixeInternetTabState();
}

class _FixeInternetTabState extends State<_FixeInternetTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final abos = widget.client.abonnementsFibre;
    if (abos.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.wifi,
        title: 'Pas d\'abonnement Fibre / Internet',
        subtitle:
            'Aucune offre Fibre, Internet ou Fixe active pour ce client.',
      );
    }
    final idx = _selectedIndex.clamp(0, abos.length - 1);
    final selected = abos[idx];

    return Column(
      children: [
        if (abos.length > 1)
          _AbonnementChipsBar(
            labels: [for (final a in abos) a.adresse],
            selectedIndex: idx,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            children: [
              _FixeInternetLineCard(
                abonnement: selected,
                client: widget.client,
              ),
              if (selected.factures.isNotEmpty)
                _FacturesCard(factures: selected.factures),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab : TV (abonnements au niveau client) ─────────────────────

class _TvTab extends StatefulWidget {
  final Client client;
  const _TvTab({required this.client});

  @override
  State<_TvTab> createState() => _TvTabState();
}

class _TvTabState extends State<_TvTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final abos = widget.client.abonnementsTv;
    if (abos.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.tv,
        title: 'Aucun abonnement TV',
        subtitle: 'Ce client n\'a pas d\'abonnement Orange TV actif.',
      );
    }
    final idx = _selectedIndex.clamp(0, abos.length - 1);
    final selected = abos[idx];

    return Column(
      children: [
        if (abos.length > 1)
          _AbonnementChipsBar(
            labels: [for (final a in abos) a.adresse],
            selectedIndex: idx,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            children: [
              _TvLineCard(abonnement: selected, client: widget.client),
              if (selected.factures.isNotEmpty)
                _FacturesCard(factures: selected.factures),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barre de chips pour sélectionner un abonnement (Fibre / TV) par adresse.
/// Calquée sur [_NumeroChipsBar] mais avec un libellé simple.
class _AbonnementChipsBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _AbonnementChipsBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(bottom: BorderSide(color: P.borderSoft)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == selectedIndex;
          return Material(
            color: active ? AppColors.primary : Colors.white10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: active ? AppColors.primary : P.borderSoft,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(i),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: active ? Colors.white : P.text,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab 3 : Orange Money ────────────────────────────────────────

class _OrangeMoneyTab extends StatefulWidget {
  final Client client;
  const _OrangeMoneyTab({required this.client});

  @override
  State<_OrangeMoneyTab> createState() => _OrangeMoneyTabState();
}

class _OrangeMoneyTabState extends State<_OrangeMoneyTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final numeros = widget.client.numerosPour(NumeroService.orangeMoney);
    if (numeros.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.wallet,
        title: 'Pas de compte Orange Money',
        subtitle:
            'Aucun compte Orange Money associé à ce client. Proposer l\'ouverture en agence.',
      );
    }
    final idx = _selectedIndex.clamp(0, numeros.length - 1);
    final selected = numeros[idx];
    final compte = selected.compteOM;

    return Column(
      children: [
        _NumeroChipsBar(
          numeros: numeros,
          selectedIndex: idx,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            children: [
              if (compte != null) _OmAccountCard(compte: compte),
              // if (compte != null && compte.coffre != null)
              //   _OmCoffreCard(coffre: compte.coffre!),
              if (compte != null && compte.visa != null)
                _OmVisaCard(visa: compte.visa!),
              if (compte != null)
                _OmTransactionsCard(transactions: compte.dernieresTransactions),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 4 : Cases client ────────────────────────────────────────

class _CasesTab extends StatefulWidget {
  final Client client;
  const _CasesTab({required this.client});

  @override
  State<_CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<_CasesTab> {
  CaseStatut? _filter; // null = Tous

  @override
  Widget build(BuildContext context) {
    final cases = widget.client.cases;
    if (cases.isEmpty) {
      return _EmptyUniverse(
        icon: AppIcons.contracts,
        title: 'Aucun case ouvert',
        subtitle:
            'Ce client n\'a aucun dossier en cours. Crée un case depuis la barre d\'actions.',
      );
    }

    final counts = <CaseStatut, int>{};
    for (final c in cases) {
      counts[c.statut] = (counts[c.statut] ?? 0) + 1;
    }
    // Ordre d'affichage côté web : actifs en haut.
    const order = {
      CaseStatut.ouvert: 0,
      CaseStatut.enCours: 1,
      CaseStatut.transfere: 2,
      CaseStatut.enAttente: 3,
      CaseStatut.cloture: 4,
      CaseStatut.annule: 5,
    };
    final filtered = (_filter == null
            ? [...cases]
            : cases.where((c) => c.statut == _filter).toList())
      ..sort((a, b) {
        final sd = (order[a.statut] ?? 9) - (order[b.statut] ?? 9);
        if (sd != 0) return sd;
        return b.createdAt.compareTo(a.createdAt);
      });

    final activeCount =
        cases.where((c) => c.statut.isActive).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: P.surface,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${cases.length} case(s)',
                    style: TextStyle(
                      color: P.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$activeCount actif${activeCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 24,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Chip(
                      label: 'Tous',
                      count: cases.length,
                      active: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final s in CaseStatut.values)
                      if ((counts[s] ?? 0) > 0)
                        _Chip(
                          label: s.label,
                          count: counts[s]!,
                          active: _filter == s,
                          onTap: () => setState(() => _filter = s),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            children: [
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucun case dans cette catégorie',
                      style: TextStyle(color: P.muted, fontSize: 11),
                    ),
                  ),
                )
              else
                for (final c in filtered) _CaseCard(cas: c),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: active ? AppColors.primary : P.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? AppColors.primary : P.borderSoft,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : P.text,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: active
                        ? Colors.white.withValues(alpha: 0.75)
                        : P.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ClientCase cas;
  const _CaseCard({required this.cas});

  ({Color bg, Color fg}) _statutColors(CaseStatut s) {
    switch (s) {
      case CaseStatut.ouvert:
        return (bg: AppColors.info.withValues(alpha: 0.15), fg: AppColors.info);
      case CaseStatut.enCours:
        return (
          bg: AppColors.warning.withValues(alpha: 0.18),
          fg: AppColors.warning,
        );
      case CaseStatut.transfere:
        return (bg: const Color(0x33A78BFA), fg: const Color(0xFF7C3AED));
      case CaseStatut.enAttente:
        return (bg: Colors.white12, fg: P.muted);
      case CaseStatut.cloture:
        return (
          bg: AppColors.success.withValues(alpha: 0.15),
          fg: AppColors.success,
        );
      case CaseStatut.annule:
        return (
          bg: AppColors.danger.withValues(alpha: 0.15),
          fg: AppColors.danger,
        );
    }
  }

  Color _graviteColor(CaseGravite g) {
    switch (g) {
      case CaseGravite.faible:
        return AppColors.success;
      case CaseGravite.moyenne:
        return AppColors.info;
      case CaseGravite.haute:
        return AppColors.warning;
      case CaseGravite.critique:
        return AppColors.danger;
    }
  }

  double _slaPct() {
    if (cas.deadline == null && cas.slaH <= 0) return 0;
    final start = cas.createdAt;
    final end = cas.deadline ?? start.add(Duration(hours: cas.slaH));
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _slaColor(double pct) {
    if (pct >= 1.0) return AppColors.danger;
    if (pct >= 0.75) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final st = _statutColors(cas.statut);
    final isActive = cas.statut.isActive;
    final slaPct = isActive ? _slaPct() : 0.0;
    final slaCol = _slaColor(slaPct);
    final dimmed = cas.statut == CaseStatut.cloture ||
        cas.statut == CaseStatut.annule;

    return Opacity(
      opacity: dimmed ? 0.78 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: P.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  cas.id,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                _Pill(label: cas.statut.label, bg: st.bg, fg: st.fg),
                const Spacer(),
                _Pill(
                  label: cas.gravite.label,
                  bg: _graviteColor(cas.gravite).withValues(alpha: 0.15),
                  fg: _graviteColor(cas.gravite),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: P.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: cas.categorie),
                  TextSpan(
                    text: '  ›  ${cas.motif}',
                    style: TextStyle(
                      color: P.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (cas.description != null) ...[
              const SizedBox(height: 3),
              Text(
                cas.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: P.muted, fontSize: 10.5),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Hi(AppIcons.agent, size: 11, color: P.muted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    cas.agent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: P.muted, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '› ${cas.corbeille}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: P.muted, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  formatDate(cas.createdAt),
                  style: TextStyle(color: P.muted, fontSize: 10),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'SLA ${cas.slaH}h',
                    style: TextStyle(color: P.muted, fontSize: 9.5),
                  ),
                  const Spacer(),
                  Text(
                    '${(slaPct * 100).round()} %',
                    style: TextStyle(
                      color: slaCol,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: slaPct,
                  minHeight: 3,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(slaCol),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
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

  /// Renvoie l'agent vers la Vue 360 web pour ce client.
  /// Reprend la convention déjà utilisée dans [ActionSheet._openInHermes].
  void _openVue360Web(BuildContext context) {
    final url = '/client/${client.id}/vue360';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: P.surface,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Hi(AppIcons.openExternal,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Direction HERMÈS web : $url',
                style: TextStyle(color: P.text, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
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
              // « Voir plus » → renvoie vers la Vue 360 web pour ce client
              IconButton(
                tooltip: 'Voir plus (HERMÈS web)',
                onPressed: () => _openVue360Web(context),
                icon: const Hi(AppIcons.openExternal,
                    size: 16, color: AppColors.primary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 4),

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
    // Aligné sur .card / .card-header / .card-title du web
    // (hermes_final_fixed.html) en gardant un padding compact adapté
    // à la largeur du widget.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: P.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Hi(widget.icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: P.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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

// ─── Ligne Mobile (carte unifiée n° + conso + actions) ──────────

class _MobileLineCard extends StatelessWidget {
  final Numero numero;
  final Consommation conso;
  final Client client;
  const _MobileLineCard({
    required this.numero,
    required this.conso,
    required this.client,
  });

  static String _formatMinutes(int m) {
    if (m <= 0) return '0 min';
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h${r.toString().padLeft(2, '0')}';
  }

  Color _ratioColor(double pct) {
    if (pct < 0.15) return AppColors.danger;
    if (pct < 0.35) return AppColors.warning;
    return AppColors.success;
  }

  QuickAction? _action(String id) {
    for (final a in mockActions) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _openAction(BuildContext context, String id) {
    final a = _action(id);
    if (a == null) return;
    ActionSheet.show(context, a, client);
  }

  @override
  Widget build(BuildContext context) {
    final mobileContrat = numero.contrats.firstWhere(
      (c) => c.service == 'Mobile',
      orElse: () => const Contrat(
        id: '-',
        service: 'Mobile',
        statut: 'Actif',
        offre: 'Forfait Mobile',
      ),
    );
    final libelle = numero.libelle ?? 'Principale';
    final dataPct =
        conso.dataTotaleGo == 0 ? 0.0 : conso.dataRestanteGo / conso.dataTotaleGo;
    final voixPct = conso.voixMinTotales == 0
        ? 0.0
        : conso.voixMinRestantes / conso.voixMinTotales;
    final smsPct =
        conso.smsTotaux == 0 ? 0.0 : conso.smsRestants / conso.smsTotaux;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: P.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête : numéro + libellé · offre · techno
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Hi(AppIcons.smartphone, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      numero.numero,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$libelle · ${mobileContrat.offre}',
                          style: TextStyle(color: P.muted, fontSize: 10.5),
                        ),
                        Text(
                          '4G',
                          style: TextStyle(
                            color: AppColors.info,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Jauges Data / Voix / SMS — chaque jauge inclut, en-dessous,
          // les pass actifs qui couvrent ce type d'usage.
          _MobileGaugeRow(
            icon: AppIcons.consumption,
            label: 'Data',
            value:
                '${formatGo(conso.dataRestanteGo)} / ${formatGo(conso.dataTotaleGo)}',
            pct: dataPct,
            color: _ratioColor(dataPct),
            passes: conso.passActifs
                .where((p) => p.type == PassType.data)
                .toList(),
          ),
          const SizedBox(height: 10),
          _MobileGaugeRow(
            icon: AppIcons.landline,
            label: 'Voix',
            value:
                '${_formatMinutes(conso.voixMinRestantes)} / ${conso.voixMinTotales} min',
            pct: voixPct,
            color: _ratioColor(voixPct),
            passes: conso.passActifs
                .where((p) => p.type == PassType.voix)
                .toList(),
          ),
          const SizedBox(height: 10),
          _MobileGaugeRow(
            icon: AppIcons.sendToMobile,
            label: 'SMS',
            value: '${conso.smsRestants} / ${conso.smsTotaux}',
            pct: smsPct,
            color: _ratioColor(smsPct),
            passes: conso.passActifs
                .where((p) => p.type == PassType.sms)
                .toList(),
          ),
          const SizedBox(height: 12),
          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillAction(
                icon: AppIcons.power,
                label: 'Suspendre',
                color: AppColors.danger,
                onTap: () => _openAction(context, 'suspendre_compte'),
              ),
              _PillAction(
                icon: AppIcons.sim,
                label: 'SIM SWAP',
                color: AppColors.info,
                onTap: () => _openAction(context, 'sim_swap'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une ligne d'un pass actif : nom + avantages + date d'expiration.
/// Inspirée du popover « Pass actifs » côté web (vue 360).
class _PassActifRow extends StatelessWidget {
  final PassActif pass;
  const _PassActifRow({required this.pass});

  Color _expiryColor(DateTime exp) {
    final days = exp.difference(DateTime.now()).inDays;
    if (days < 0) return AppColors.danger;
    if (days <= 3) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final col = _expiryColor(pass.expiration);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pass.nom,
                  style: TextStyle(
                    color: P.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Hi(AppIcons.calendar, size: 10, color: col),
              const SizedBox(width: 3),
              Text(
                'Expire le ${formatDate(pass.expiration)}',
                style: TextStyle(
                  color: col,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            pass.avantages,
            style: TextStyle(color: P.muted, fontSize: 10, height: 1.25),
          ),
        ],
      ),
    );
  }
}

/// Une ligne icône + label + barre de progression + valeur, façon screenshot.
class _MobileGaugeRow extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final String value;
  final double pct;
  final Color color;
  /// Pass actifs qui couvrent cette catégorie d'usage (data / voix / sms).
  /// Affichés en compact sous la jauge — vide = rien.
  final List<PassActif> passes;
  const _MobileGaugeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
    this.passes = const [],
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hi(icon, size: 13, color: P.muted),
            const SizedBox(width: 6),
            SizedBox(
              width: 34,
              child: Text(
                label,
                style: TextStyle(color: P.muted, fontSize: 10.5),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: P.text,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Affiche les pass uniquement si présents — sinon la jauge reste seule.
        if (passes.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            // Aligne sous le début du libellé (icône 13 + gap 6).
            padding: const EdgeInsets.only(left: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < passes.length; i++) ...[
                  if (i != 0) const SizedBox(height: 4),
                  _PassActifRow(pass: passes[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton pilule (outline + icône + label) pour les actions de la ligne.
class _PillAction extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hi(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
                    child: Text(p.nom, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
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

// ─── Ligne Fixe / Internet (carte unifiée box + débits + actions) ─

class _FixeInternetLineCard extends StatelessWidget {
  final AbonnementFibre abonnement;
  final Client client;
  const _FixeInternetLineCard({
    required this.abonnement,
    required this.client,
  });

  QuickAction? _action(String id) {
    for (final a in mockActions) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _openAction(BuildContext context, String id) {
    final a = _action(id);
    if (a == null) return;
    ActionSheet.show(context, a, client);
  }

  Color _dispoColor(double pct) {
    if (pct >= 99) return AppColors.success;
    if (pct >= 95) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final d = abonnement.details;
    final statutLabel = d.connectee ? 'Connectée' : 'Déconnectée';
    final statutColor = d.connectee ? AppColors.success : AppColors.danger;
    final incidentLabel = d.incidentEnCours ?? 'Aucun en cours';
    final incidentColor = d.incidentEnCours == null
        ? AppColors.success
        : AppColors.danger;
    final renew = abonnement.renouvellement;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: P.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête : pastille statut + équipement + (débit max · techno · statut)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statutColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.equipement,
                      style: TextStyle(
                        color: P.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.debitDescendantMbps} Mbps ${d.techno} · $statutLabel',
                      style: TextStyle(color: P.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tuiles débits + dispo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Débit ↓',
                  value: '${d.debitDescendantMbps}',
                  unit: 'Mb/s',
                  color: P.text,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Débit ↑',
                  value: '${d.debitMontantMbps}',
                  unit: 'Mb/s',
                  color: P.text,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Disponibilité',
                  value: '${d.dispoPct.toStringAsFixed(1)}%',
                  unit: '',
                  color: _dispoColor(d.dispoPct),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: P.borderSoft, height: 1),
          const SizedBox(height: 6),
          // KV lines
          _KvLine(k: 'Adresse', v: abonnement.adresse, valueBold: true),
          _KvLine(k: 'Offre', v: abonnement.offre, valueBold: true),
          _KvLine(k: 'Équipement', v: d.equipement, valueBold: true),
          if (abonnement.numeroFixe != null)
            _KvLine(
              k: 'Ligne fixe',
              v: abonnement.numeroFixe!,
              valueBold: true,
            ),
          if (abonnement.montantMensuelFcfa > 0)
            _KvLine(
              k: 'Abonnement',
              v: '${formatFcfa(abonnement.montantMensuelFcfa)} / mois',
              valueBold: true,
              valueColor: AppColors.primary,
            ),
          if (renew != null)
            _KvLine(k: 'Renouvellement', v: formatDate(renew), valueBold: true),
          _KvLine(
            k: 'Incidents',
            v: incidentLabel,
            valueColor: incidentColor,
            valueBold: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillAction(
                icon: AppIcons.refresh,
                label: 'Réactiver',
                color: AppColors.success,
                onTap: () => _openAction(context, 'reactiv_fibre'),
              ),
              _PillAction(
                icon: AppIcons.calendar,
                label: 'Restitution jours',
                color: AppColors.info,
                onTap: () => _openAction(context, 'restitution_jours'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ligne TV (carte unifiée Orange TV) ─────────────────────────

class _TvLineCard extends StatelessWidget {
  final AbonnementTv abonnement;
  final Client client;
  const _TvLineCard({required this.abonnement, required this.client});

  QuickAction? _action(String id) {
    for (final a in mockActions) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _openAction(BuildContext context, String id) {
    final a = _action(id);
    if (a == null) return;
    ActionSheet.show(context, a, client);
  }

  @override
  Widget build(BuildContext context) {
    final tv = abonnement.details;
    final compte = tv.compte;
    final pack = tv.pack;
    final equipement = tv.equipement;
    final bouquets = tv.bouquets;
    final options = tv.options;
    final nbChaines = tv.nbChaines;
    final prixMensuel = tv.prixMensuelFcfa;
    final dateInstallation = tv.dateInstallation;
    final derniereConnexion = tv.derniereConnexion;
    final statut = tv.statut;
    final statutColor = statut == 'Actif'
        ? AppColors.success
        : statut == 'Suspendu'
            ? AppColors.danger
            : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: P.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête : icône TV + titre Orange TV + pack + badge statut
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Hi(AppIcons.tv, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orange TV',
                      style: TextStyle(
                        color: P.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pack,
                      style: TextStyle(color: P.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              _MiniBadge(label: statut, color: statutColor),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: P.borderSoft, height: 1),
          const SizedBox(height: 6),
          // KV lines — mêmes intitulés que le web (.rs-tv) + enrichissements
          _KvLine(k: 'Adresse', v: abonnement.adresse, valueBold: true),
          _KvLine(k: 'N° compte', v: compte, valueBold: true),
          _KvLine(k: 'Équipement', v: equipement, valueBold: true),
          if (nbChaines > 0)
            _KvLine(k: 'Chaînes', v: '$nbChaines incluses', valueBold: true),
          if (prixMensuel > 0)
            _KvLine(
              k: 'Abonnement',
              v: '${formatFcfa(prixMensuel)} / mois',
              valueBold: true,
              valueColor: AppColors.primary,
            ),
          if (dateInstallation != null)
            _KvLine(
              k: 'Installé le',
              v: formatDate(dateInstallation),
              valueBold: true,
            ),
          _KvLine(
            k: 'Dernière connexion',
            v: derniereConnexion != null ? formatDate(derniereConnexion) : '—',
            valueBold: true,
          ),
          if (bouquets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bouquets inclus',
              style: TextStyle(
                color: P.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in bouquets)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Options activées',
              style: TextStyle(
                color: P.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in options)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.10),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.30),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hi(AppIcons.checkCircle,
                            size: 10, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          o,
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Actions — Gérer TV / Créer case
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PillAction(
                icon: AppIcons.tv,
                label: 'Gérer TV',
                color: AppColors.primary,
                onTap: () => _openAction(context, 'gerer_tv'),
              ),
              _PillAction(
                icon: AppIcons.contracts,
                label: 'Créer case',
                color: AppColors.info,
                onTap: () => _openAction(context, 'creer_case'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petite tuile chiffre + unité + label en dessous (pour les débits / dispo).
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: P.muted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: P.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

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

// ─── Échéance abonnement (réutilisable) ─────────────────────────

class _EcheanceCard extends StatelessWidget {
  final EcheanceAbonnement echeance;
  const _EcheanceCard({required this.echeance});

  @override
  Widget build(BuildContext context) {
    final reste = echeance.renouvellement.difference(DateTime.now());
    final jours = reste.inDays;
    final colorJours = jours < 0
        ? AppColors.danger
        : jours <= 3
            ? AppColors.warning
            : AppColors.success;
    final libJours = jours < 0
        ? 'Échue depuis ${-jours} j'
        : jours == 0
            ? 'Échue aujourd\'hui'
            : 'Dans $jours j';
    return _Section(
      icon: AppIcons.sla,
      title: 'Prochaine échéance',
      trailing: _MiniBadge(
        label: echeance.autoRenouvellement ? 'Auto-renouv.' : 'Manuel',
        color: echeance.autoRenouvellement ? AppColors.info : AppColors.warning,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'Renouvellement',
                  value: formatDate(echeance.renouvellement),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(
                  label: 'Montant',
                  value: formatFcfa(echeance.montantFcfa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  echeance.libelle,
                  style: TextStyle(color: P.muted, fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                libJours,
                style: TextStyle(
                  color: colorJours,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Factures (réutilisable Mobile / Fixe / Internet / TV) ──────

class _FacturesCard extends StatelessWidget {
  final List<FactureRecente> factures;
  const _FacturesCard({required this.factures});

  @override
  Widget build(BuildContext context) {
    if (factures.isEmpty) {
      return _Section(
        icon: AppIcons.billing,
        title: 'Historique des factures',
        child: Text(
          'Aucune facture pour ce numéro.',
          style: TextStyle(color: P.muted, fontSize: 11),
        ),
      );
    }
    final unpaid = factures.where((f) => !f.paye).toList();
    final unpaidCount = unpaid.length;
    final totalEnCours =
        unpaid.fold<int>(0, (sum, f) => sum + f.montantFcfa);
    final prochaineEcheance = unpaid.isNotEmpty
        ? (unpaid.map((f) => f.echeance).reduce((a, b) => a.isBefore(b) ? a : b))
        : factures.first.echeance;

    return _Section(
      icon: AppIcons.billing,
      title: 'Historique des factures',
      trailing: _MiniBadge(
        label: unpaidCount > 0 ? '$unpaidCount en attente' : 'À jour',
        color: unpaidCount > 0 ? AppColors.warning : AppColors.success,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total dû',
                        style: TextStyle(color: P.muted, fontSize: 9.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        formatFcfa(totalEnCours),
                        style: TextStyle(
                          color: unpaidCount > 0
                              ? AppColors.warning
                              : AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Échéance',
                      style: TextStyle(color: P.muted, fontSize: 9.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatDate(prochaineEcheance),
                      style: TextStyle(
                        color: P.text,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < factures.length; i++) ...[
            if (i != 0) Divider(height: 10, color: P.borderSoft),
            _FixeFactureLine(facture: factures[i]),
          ],
        ],
      ),
    );
  }
}

class _FixeFactureLine extends StatelessWidget {
  final FactureRecente facture;
  const _FixeFactureLine({required this.facture});

  @override
  Widget build(BuildContext context) {
    final color = facture.paye ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Hi(
            facture.paye ? AppIcons.checkCircle : AppIcons.sla,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facture.libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: P.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${facture.periode} · ${facture.id}',
                  style: TextStyle(color: P.muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatFcfa(facture.montantFcfa),
                style: TextStyle(
                  color: P.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                facture.paye ? 'Réglé' : 'En attente',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Orange Money / Orange Banque — cards dynamiques ─────────────

class _OmAccountCard extends StatelessWidget {
  final CompteOrangeMoney compte;
  const _OmAccountCard({required this.compte});

  @override
  Widget build(BuildContext context) {
    final isOB = compte.type == TypeCompteOM.orangeBanque;
    final accent = isOB ? const Color(0xFF7C3AED) : AppColors.primary;
    return _Section(
      icon: isOB ? AppIcons.idCard : AppIcons.wallet,
      title: isOB ? 'Compte Orange Banque' : 'Compte Orange Money',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              compte.type.shortLabel,
              style: TextStyle(
                color: accent,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _MiniBadge(
            label: compte.statut,
            color: compte.statut == 'Actif'
                ? AppColors.success
                : AppColors.warning,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'Solde disponible',
                  value: formatFcfa(compte.soldeFcfa),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(
                  label: 'Plafond du compte',
                  value: formatFcfa(compte.plafondMensuelFcfa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _KvLine(k: 'Offre', v: compte.offre),
          _KvLine(k: 'Référence', v: compte.id, valueBold: true),
          _KvLine(k: 'Niveau KYC', v: compte.niveauKyc),
          _KvLine(
            k: 'Date d\'ouverture',
            v: formatDate(compte.ouvertureAt),
          ),
        ],
      ),
    );
  }
}

class _OmTransactionsCard extends StatelessWidget {
  final List<OmTransaction> transactions;
  const _OmTransactionsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _Section(
        icon: AppIcons.transferred,
        title: 'Dernières transactions',
        child: Text(
          'Aucune transaction récente.',
          style: TextStyle(color: P.muted, fontSize: 11),
        ),
      );
    }
    return _Section(
      icon: AppIcons.transferred,
      title: 'Dernières transactions',
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i != 0) Divider(height: 10, color: P.borderSoft),
            _OmTxLine(tx: transactions[i]),
          ],
        ],
      ),
    );
  }
}

class _OmTxLine extends StatelessWidget {
  final OmTransaction tx;
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
    final out = tx.amountFcfa < 0;
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
            _fmt(tx.amountFcfa),
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
  final CarteVisaVirtuelle visa;
  const _OmVisaCard({required this.visa});

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
              children: [
                const Text(
                  'VISA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '••••  ••••  ••••  ${visa.last4}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exp. ${visa.exp}   •   CVV •••',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _KvLine(k: 'Plafond mensuel', v: formatFcfa(visa.plafondMensuelFcfa)),
          _KvLine(k: 'Consommé', v: formatFcfa(visa.consommeFcfa)),
          if (visa.abonnementsActifs.isNotEmpty)
            _KvLine(
              k: 'Abonnements actifs',
              v: visa.abonnementsActifs.join(' · '),
            ),
        ],
      ),
    );
  }
}

class _OmCoffreCard extends StatelessWidget {
  final CoffreOM coffre;
  const _OmCoffreCard({required this.coffre});

  @override
  Widget build(BuildContext context) {
    final tauxStr =
        '${coffre.tauxAnnuelPct.toStringAsFixed(1).replaceAll('.', ',')} % / an';
    return _Section(
      icon: AppIcons.lock,
      title: 'Coffre-fort Orange Money',
      trailing: _MiniBadge(label: 'Ouvert', color: AppColors.info),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'Épargne totale',
                  value: formatFcfa(coffre.epargneFcfa),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Tile(label: 'Rémunération', value: tauxStr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _KvLine(
            k: 'Versement programmé',
            v: '${formatFcfa(coffre.versementMensuelFcfa)} / mois',
          ),
          _KvLine(
            k: 'Prochain versement',
            v: formatDate(coffre.prochainVersement),
          ),
          _KvLine(
            k: 'Objectif',
            v:
                '${formatFcfa(coffre.objectifFcfa)} (${coffre.progressionPct} %)',
          ),
        ],
      ),
    );
  }
}
