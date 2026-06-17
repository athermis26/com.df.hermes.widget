import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../mock/mock_actions.dart';
import '../mock/mock_tickets.dart';
import '../models/ticket.dart';
import 'action_sheet.dart';
import 'hi.dart';
import '../core/theme/theme_controller.dart';

/// Bottom sheet listant les actions pertinentes pour le motif du ticket.
class MotifActionsSheet extends StatelessWidget {
  final Ticket ticket;
  const MotifActionsSheet({super.key, required this.ticket});

  static Future<void> show(BuildContext context, Ticket t) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MotifActionsSheet(ticket: t),
    );
  }

  void _openInHermes(BuildContext context) {
    final url = '/client/${ticket.client.id}/vue360';
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: P.surface,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Hi(AppIcons.openExternal, color: AppColors.primary, size: 16),
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
    final ids = actionsByMotif[ticket.motif] ?? const <String>[];
    final actions =
        mockActions.where((a) => ids.contains(a.id)).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: P.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          top: BorderSide(color: Colors.white12),
          left: BorderSide(color: Colors.white12),
          right: BorderSide(color: Colors.white12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32, height: 3,
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Hi(AppIcons.tabActions, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quoi faire pour « ${ticket.motif.label} » ?',
                  style: TextStyle(
                      color: P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (actions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Aucune action rapide directe pour ce motif.',
                style: TextStyle(color: P.muted, fontSize: 11.5),
              ),
            )
          else
            for (final a in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: P.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.of(context).pop();
                      ActionSheet.show(context, a, ticket.client);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Hi(a.icon, color: a.color, size: 16)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.label,
                                  style: TextStyle(
                                      color: P.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.description,
                                  style: TextStyle(
                                      color: P.muted,
                                      fontSize: 10.5,
                                      height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Hi(AppIcons.chevronRight,
                              size: 14, color: P.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 8),
          // Bouton de redirection vers HERMÈS web — toujours disponible
          // pour les opérations qui sortent du périmètre du widget.
          Material(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openInHermes(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                          child: Hi(AppIcons.openExternal,
                              color: AppColors.primary, size: 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voir le dossier complet sur HERMÈS',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pour aller plus loin que les actions rapides.',
                            style: TextStyle(
                                color: P.muted,
                                fontSize: 10.5,
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Hi(AppIcons.chevronRight,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
