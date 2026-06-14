import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/client_selection.dart';
import '../../core/conseiller_state.dart';
import '../../core/formatters.dart';
import '../../core/panel_nav.dart';
import '../../core/theme/app_colors.dart';
import '../../mock/mock_data.dart';
import '../../models/conseiller.dart';
import '../../models/notification.dart';
import '../../widgets/hi.dart';
import '../../core/theme/theme_controller.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late List<AppNotification> _notifs;
  int _fileCount = mockFileAttenteCount;

  @override
  void initState() {
    super.initState();
    _notifs = List.of(mockNotifications);
  }

  void _openNotif(AppNotification n) {
    setState(() {
      _notifs = [
        for (final x in _notifs)
          x.id == n.id
              ? AppNotification(
                  id: x.id,
                  type: x.type,
                  titre: x.titre,
                  message: x.message,
                  date: x.date,
                  clientIdLie: x.clientIdLie,
                  lue: true,
                )
              : x,
      ];
    });
    if (n.clientIdLie != null) {
      try {
        final c = mockClients.firstWhere((c) => c.id == n.clientIdLie);
        ClientSelection.instance.select(c);
        PanelNav.instance.reset();
      } catch (_) {}
    }
  }

  void _clientSuivant() {
    if (_fileCount <= 0) return;
    final pick = mockClients[Random().nextInt(mockClients.length)];
    setState(() => _fileCount--);
    ClientSelection.instance.select(pick);
    ConseillerState.instance.demarrerPriseEnCharge();
    PanelNav.instance.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StatutCard(),
          const SizedBox(height: 8),
          const _DmtCard(),
          const SizedBox(height: 8),
          _FileCard(count: _fileCount, onNext: _clientSuivant),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Text(
              'Vos notifications',
              style: TextStyle(
                color: P.muted,
                fontSize: 10.5,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_notifs.isEmpty)
            const _EmptyNotifs()
          else
            for (final n in _notifs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _NotifTile(n: n, onTap: () => _openNotif(n)),
              ),
        ],
      ),
    );
  }
}

// ─── Statut conseiller ───────────────────────────────────────────

class _StatutCard extends StatelessWidget {
  const _StatutCard();

  ({Color color, String label, AppIcon icon}) _meta(StatutConseiller s) {
    switch (s) {
      case StatutConseiller.disponible:
        return (color: AppColors.success, label: 'Dispo', icon: AppIcons.statusOk);
      case StatutConseiller.enTraitement:
        return (color: AppColors.warning, label: 'En appel', icon: AppIcons.statusBusy);
      case StatutConseiller.pause:
        return (color: P.muted, label: 'En pause', icon: AppIcons.statusPause);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StatutConseiller>(
      valueListenable: ConseillerState.instance.statut,
      builder: (_, current, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: P.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              for (final s in StatutConseiller.values) ...[
                Expanded(
                  child: _SegmentBtn(
                    selected: s == current,
                    meta: _meta(s),
                    onTap: () => ConseillerState.instance.setStatut(s),
                  ),
                ),
                if (s != StatutConseiller.values.last) const SizedBox(width: 4),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  final bool selected;
  final ({Color color, String label, AppIcon icon}) meta;
  final VoidCallback onTap;
  const _SegmentBtn({required this.selected, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? meta.color.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(
            color: selected ? meta.color : Colors.white10,
            width: selected ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hi(meta.icon, size: 14, color: selected ? meta.color : P.muted),
            const SizedBox(height: 2),
            Text(
              meta.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? meta.color : P.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chrono DMT ──────────────────────────────────────────────────

class _DmtCard extends StatefulWidget {
  const _DmtCard();
  @override
  State<_DmtCard> createState() => _DmtCardState();
}

class _DmtCardState extends State<_DmtCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: ConseillerState.instance.dmtStart,
      builder: (_, start, _) {
        final elapsed = start == null
            ? Duration.zero
            : DateTime.now().difference(start);
        final progress =
            (elapsed.inSeconds / ConseillerState.dmtTarget.inSeconds).clamp(0.0, 1.5);
        Color color;
        String hint;
        if (start == null) {
          color = P.muted;
          hint = 'En attente d\'un appel';
        } else if (elapsed >= ConseillerState.dmtTarget) {
          color = AppColors.danger;
          hint = 'On a dépassé la cible de 10 min';
        } else if (elapsed >= ConseillerState.dmtWarning) {
          color = AppColors.warning;
          hint = 'On approche de la cible de 10 min';
        } else {
          color = AppColors.success;
          hint = 'Tout va bien, dans les temps';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: P.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Hi(AppIcons.dmt, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Temps de l\'appel',
                    style: TextStyle(
                      color: P.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _format(elapsed),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(hint, style: TextStyle(color: color, fontSize: 10)),
                  const Spacer(),
                  Text(
                    'Objectif : 10:00',
                    style: TextStyle(color: P.muted, fontSize: 9.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: start == null
                          ? () => ConseillerState.instance.demarrerPriseEnCharge()
                          : null,
                      icon: const Hi(AppIcons.play, size: 14, color: AppColors.success),
                      label: const Text('Je commence', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: start != null
                          ? () => ConseillerState.instance.finirPriseEnCharge()
                          : null,
                      icon: const Hi(AppIcons.stop, size: 14, color: AppColors.danger),
                      label: const Text('C\'est terminé', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}

// ─── File d'attente ──────────────────────────────────────────────

class _FileCard extends StatelessWidget {
  final int count;
  final VoidCallback onNext;
  const _FileCard({required this.count, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Hi(AppIcons.queue, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dans la file',
                  style: TextStyle(color: P.muted, fontSize: 10.5),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? 'File vide, bravo !'
                      : '$count personne${count > 1 ? 's' : ''} vous attend${count > 1 ? 'ent' : ''}',
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
            onPressed: count > 0 ? onNext : null,
            icon: const Hi(AppIcons.next, size: 14, color: Colors.white),
            label: const Text('Au suivant', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile notif ─────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotifTile({required this.n, required this.onTap});

  ({AppIcon icon, Color color}) _meta() {
    switch (n.type) {
      case NotifType.slaWarning:
        return (icon: AppIcons.sla, color: AppColors.danger);
      case NotifType.caseAssigned:
        return (icon: AppIcons.assigned, color: AppColors.primary);
      case NotifType.caseTransferred:
        return (icon: AppIcons.transferred, color: AppColors.info);
      case NotifType.retourFile:
        return (icon: AppIcons.retour, color: AppColors.warning);
      case NotifType.info:
        return (icon: AppIcons.info, color: P.muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta();
    return Material(
      color: P.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Hi(m.icon, color: m.color, size: 16)),
                  ),
                  if (!n.lue)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: P.surface, width: 1.5),
                        ),
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
                            n.titre,
                            style: TextStyle(
                              color: P.text,
                              fontSize: 12,
                              fontWeight: n.lue ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          formatDateHeure(n.date),
                          style: TextStyle(color: P.muted, fontSize: 9.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      style: TextStyle(color: P.muted, fontSize: 10.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Hi(AppIcons.chevronRight, size: 14, color: P.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifs extends StatelessWidget {
  const _EmptyNotifs();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: P.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Hi(AppIcons.allGood, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rien à signaler, tout est à jour.',
              style: TextStyle(color: P.muted, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
