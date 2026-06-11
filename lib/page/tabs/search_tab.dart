import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/client_selection.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client.dart';
import '../../repositories/client_repository.dart';
import '../../widgets/hi.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  List<Client> _results = const [];
  AccessRestriction _restriction = AccessRestriction.none;
  String _lastQuery = '';

  static const _debounceMs = 300;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _run(value.trim());
    });
  }

  Future<void> _run(String query) async {
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _results = const [];
        _restriction = AccessRestriction.none;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastQuery = query;
    });
    final restriction =
        await AppServices.clientRepository.checkRestriction(query);
    if (restriction != AccessRestriction.none) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
        _restriction = restriction;
      });
      return;
    }
    final res = await AppServices.clientRepository.rechercher(query);
    if (!mounted || query != _lastQuery) return;
    setState(() {
      _loading = false;
      _results = res;
      _restriction = AccessRestriction.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          onClear: () {
            _controller.clear();
            _onChanged('');
            _focus.requestFocus();
          },
          onSubmitted: (v) => _run(v.trim()),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const _SkeletonList();
    if (_restriction == AccessRestriction.blacklist) {
      return const _RestrictionView(
        icon: AppIcons.block,
        color: AppColors.danger,
        title: 'Ce numéro est bloqué',
        message:
            'Il fait partie de la liste noire. Pour des raisons de sécurité, '
            'aucune information ne peut être consultée.',
      );
    }
    if (_restriction == AccessRestriction.vipProtege) {
      return const _RestrictionView(
        icon: AppIcons.shieldVip,
        color: AppColors.warning,
        title: 'Ligne VIP protégée',
        message:
            'Ce client a un niveau de confidentialité élevé. '
            'Une habilitation spécifique est requise pour ouvrir sa fiche.',
      );
    }
    if (_lastQuery.isEmpty) return const _IdleHint();
    if (_results.isEmpty) {
      return _EmptyResults(query: _lastQuery);
    }
    return _ResultsList(
      results: _results,
      onTap: (c) {
        _focus.unfocus();
        ClientSelection.instance.select(c);
      },
    );
  }
}

// ─── Widgets internes ────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Qui cherchez-vous ?',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(10),
            child: Hi(AppIcons.tabSearch, size: 16, color: AppColors.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Hi(AppIcons.close, size: 14, color: AppColors.textMuted),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: AppColors.darkSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous pouvez chercher par :',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          SizedBox(height: 10),
          _HintLine(icon: AppIcons.phone, label: 'Son numéro (ex : 07 07 12 34 56)'),
          _HintLine(icon: AppIcons.user, label: 'Son nom et prénoms'),
          _HintLine(icon: AppIcons.idCard, label: 'Sa pièce d\'identité'),
          _HintLine(icon: AppIcons.contract, label: 'Une référence de contrat'),
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  final AppIcon icon;
  final String label;
  const _HintLine({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Hi(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hi(AppIcons.searchOff, size: 38, color: AppColors.textMuted),
            const SizedBox(height: 10),
            const Text(
              'Personne ne correspond',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'On n\'a rien trouvé pour « $query »',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictionView extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String title;
  final String message;
  const _RestrictionView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hi(icon, size: 42, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Client> results;
  final ValueChanged<Client> onTap;
  const _ResultsList({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Text(
            '${results.length} personne${results.length > 1 ? 's' : ''} trouvée${results.length > 1 ? 's' : ''}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _ResultTile(client: results[i], onTap: () => onTap(results[i])),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  const _ResultTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (client.vip) ...[
                          const SizedBox(width: 4),
                          const _Chip(label: 'VIP', color: AppColors.warning),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.numeroPrincipal,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(label: client.type, color: AppColors.info),
                        const SizedBox(width: 4),
                        _Chip(label: client.segment, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const Hi(AppIcons.chevronRight, size: 16, color: AppColors.textMuted),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
