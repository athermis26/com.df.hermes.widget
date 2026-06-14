import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/client_selection.dart';
import '../core/formatters.dart';
import '../core/panel_nav.dart';
import '../core/theme/app_colors.dart';
import '../mock/mock_data.dart';
import '../models/notification.dart';
import 'hi.dart';
import '../core/theme/theme_controller.dart';

/// Popover affiché sous la cloche du header.
/// Remplace l'onglet « Activité » : tout passe par cet overlay.
class NotificationsPopover extends StatefulWidget {
  final VoidCallback onClose;
  const NotificationsPopover({super.key, required this.onClose});

  @override
  State<NotificationsPopover> createState() => _NotificationsPopoverState();
}

class _NotificationsPopoverState extends State<NotificationsPopover> {
  late List<AppNotification> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = List.of(mockNotifications);
  }

  void _open(AppNotification n) {
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
        PanelNav.instance.reset(); // file → affichera la Vue 360 du client
      } catch (_) {}
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: P.bg,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  const Hi(AppIcons.tabNotifs, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Vos notifications',
                      style: TextStyle(
                        color: P.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Hi(AppIcons.close, size: 12, color: P.muted),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Flexible(
              child: _notifs.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Rien à signaler.',
                        style: TextStyle(color: P.muted, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _notifs.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (_, i) => _NotifRow(
                        n: _notifs[i],
                        onTap: () => _open(_notifs[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotifRow({required this.n, required this.onTap});

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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(child: Hi(m.icon, color: m.color, size: 13)),
                ),
                if (!n.lue)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: P.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: P.text,
                            fontSize: 11.5,
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
                  const SizedBox(height: 1),
                  Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: P.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
