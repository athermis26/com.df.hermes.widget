import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/client_selection.dart';
import '../core/search_controller.dart';
import '../core/theme/app_colors.dart';
import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'hi.dart';

/// Overlay déroulant qui apparaît sous la barre de recherche.
/// Visible quand `HermesSearch.instance.open == true` ET query non vide.
class SearchResultsOverlay extends StatelessWidget {
  const SearchResultsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final s = HermesSearch.instance;
    return ValueListenableBuilder<String>(
      valueListenable: s.query,
      builder: (_, q, _) {
        if (q.trim().isEmpty) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.dark,
              border: const Border(bottom: BorderSide(color: Colors.white12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: ValueListenableBuilder<bool>(
              valueListenable: s.loading,
              builder: (_, loading, _) {
                if (loading) return const _LoadingRow();
                return ValueListenableBuilder<AccessRestriction>(
                  valueListenable: s.restriction,
                  builder: (_, restriction, _) {
                    if (restriction == AccessRestriction.blacklist) {
                      return const _RestrictionRow(
                        icon: AppIcons.block,
                        color: AppColors.danger,
                        title: 'Ce numéro est bloqué',
                        msg: 'Inaccessible pour des raisons de sécurité.',
                      );
                    }
                    if (restriction == AccessRestriction.vipProtege) {
                      return const _RestrictionRow(
                        icon: AppIcons.shieldVip,
                        color: AppColors.warning,
                        title: 'Ligne VIP protégée',
                        msg: 'Habilitation spécifique requise.',
                      );
                    }
                    return ValueListenableBuilder<List<Client>>(
                      valueListenable: s.results,
                      builder: (_, list, _) {
                        if (list.isEmpty) {
                          return _EmptyRow(query: q);
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: Colors.white10),
                          itemBuilder: (_, i) => _ResultRow(client: list[i]),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: AppColors.primary),
          ),
          SizedBox(width: 10),
          Text('Recherche en cours…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String query;
  const _EmptyRow({required this.query});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const Hi(AppIcons.searchOff, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Personne ne correspond à « $query »',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictionRow extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String title;
  final String msg;
  const _RestrictionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.msg,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Hi(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(msg,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Client client;
  const _ResultRow({required this.client});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ClientSelection.instance.select(client);
        HermesSearch.instance.clear();
        HermesSearch.instance.open.value = false;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                client.photoInitiales ?? '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
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
                          style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (client.vip) const _ChipMini(label: 'VIP', color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${client.numeroPrincipal} · ${client.type} · ${client.segment}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Hi(AppIcons.chevronRight, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ChipMini extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipMini({required this.label, required this.color});
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
