import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../mock/mock_tickets.dart';
import '../models/ticket.dart';
import 'hi.dart';

/// Bottom sheet de transfert d'un ticket vers une autre corbeille.
class TransferSheet extends StatelessWidget {
  final Ticket ticket;
  const TransferSheet({super.key, required this.ticket});

  static Future<void> show(BuildContext context, Ticket t) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferSheet(ticket: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cibles =
        mockCorbeillesCibles.where((c) => c != ticket.corbeille).toList();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dark,
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
            children: const [
              Hi(AppIcons.transferred, color: AppColors.info, size: 18),
              SizedBox(width: 8),
              Text(
                'Transférer ce ticket',
                style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'Actuellement dans : ${ticket.corbeille}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 10),
          for (final c in cibles)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _confirm(context, c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        const Hi(AppIcons.queue,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 12),
                          ),
                        ),
                        const Hi(AppIcons.chevronRight,
                            size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: Colors.white24),
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext context, String cible) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkSurface,
        content: Row(
          children: [
            const Hi(AppIcons.checkCircle, color: AppColors.success, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ticket ${ticket.id} transféré vers « $cible ».',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
