import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/client_selection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/session.dart';
import '../../mock/mock_actions.dart';
import '../../models/client.dart';
import '../../models/conseiller.dart';
import '../../models/quick_action.dart';
import '../../widgets/hi.dart';

class ActionsTab extends StatelessWidget {
  const ActionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profil = Session.instance.current.value?.profil ??
        ProfilConseiller.callCenter;
    final actions =
        mockActions.where((a) => a.allowedProfils.contains(profil)).toList();

    return ValueListenableBuilder<Client?>(
      valueListenable: ClientSelection.instance.current,
      builder: (_, client, _) {
        return Column(
          children: [
            _ContextBar(client: client, profil: profil),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                itemCount: actions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _ActionTile(
                  action: actions[i],
                  client: client,
                  onTap: () => _openSheet(context, actions[i], client),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSheet(BuildContext context, QuickAction a, Client? c) {
    if (a.requiresClient && c == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.darkSurface,
          content: Row(
            children: [
              Hi(AppIcons.info, color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisissez d\'abord un client dans la recherche.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionSheet(action: a, client: c),
    );
  }
}

// ─── Barre de contexte ───────────────────────────────────────────

class _ContextBar extends StatelessWidget {
  final Client? client;
  final ProfilConseiller profil;
  const _ContextBar({required this.client, required this.profil});
  @override
  Widget build(BuildContext context) {
    String profilLabel() {
      switch (profil) {
        case ProfilConseiller.callCenter:
          return 'Call Center';
        case ProfilConseiller.agence:
          return 'Agence';
        case ProfilConseiller.digital:
          return 'Digital';
        case ProfilConseiller.superviseur:
          return 'Superviseur';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Hi(AppIcons.profilBadge, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'Vos outils · ${profilLabel()}',
            style: const TextStyle(color: AppColors.textLight, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Hi(
            client == null ? AppIcons.noUser : AppIcons.userOk,
            size: 13,
            color: client == null ? AppColors.textMuted : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            client?.nom ?? 'Personne en ligne',
            style: TextStyle(
              color: client == null ? AppColors.textMuted : AppColors.textLight,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile ───────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final QuickAction action;
  final Client? client;
  final VoidCallback onTap;
  const _ActionTile({required this.action, required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = action.requiresClient && client == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Hi(action.icon, color: action.color, size: 18)),
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
                              action.label,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (action.sensitive)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: _Chip(label: 'HERMES web', color: AppColors.warning),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action.description,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Hi(AppIcons.chevronRight, size: 14, color: AppColors.textMuted),
              ],
            ),
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
      child: Text(label, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Bottom sheet ────────────────────────────────────────────────

enum _SheetState { confirmation, running, success, failure }

class _ActionSheet extends StatefulWidget {
  final QuickAction action;
  final Client? client;
  const _ActionSheet({required this.action, required this.client});
  @override
  State<_ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<_ActionSheet> {
  _SheetState _state = _SheetState.confirmation;
  String? _resultMessage;

  Future<void> _execute() async {
    setState(() => _state = _SheetState.running);
    await Future.delayed(Duration(milliseconds: 900 + Random().nextInt(700)));
    if (!mounted) return;
    final ok = Random().nextDouble() > 0.15;
    setState(() {
      _state = ok ? _SheetState.success : _SheetState.failure;
      _resultMessage = ok
          ? 'C\'est fait, parfait.'
          : 'Aïe, le service n\'a pas répondu. On retente ?';
    });
  }

  void _openInHermes() {
    final id = widget.client?.id ?? '?';
    final url = (widget.action.hermesPath ?? '/client/{id}/actions/${widget.action.id}')
        .replaceAll('{id}', id);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkSurface,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Hi(AppIcons.openExternal, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Direction HERMES web : $url',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
          _buildHeader(),
          const SizedBox(height: 12),
          _buildBody(),
          const SizedBox(height: 14),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: widget.action.color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Hi(widget.action.icon, color: widget.action.color, size: 20)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.action.label,
                style: const TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              if (widget.client != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Pour ${widget.client!.nom} · ${widget.client!.numeroPrincipal}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SheetState.confirmation:
        return Text(
          widget.action.description,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
        );
      case _SheetState.running:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 10),
              Text('Un instant, on s\'en occupe…', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        );
      case _SheetState.success:
        return _ResultRow(
          icon: AppIcons.checkCircle, color: AppColors.success, message: _resultMessage!,
        );
      case _SheetState.failure:
        return _ResultRow(
          icon: AppIcons.errorCircle, color: AppColors.danger, message: _resultMessage!,
        );
    }
  }

  Widget _buildFooter() {
    if (widget.action.sensitive) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('Plus tard', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _openInHermes,
              icon: const Hi(AppIcons.openExternal, size: 14, color: Colors.black),
              label: const Text('Continuer sur HERMES', style: TextStyle(fontSize: 11.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    switch (_state) {
      case _SheetState.confirmation:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Pas maintenant', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _execute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK, c\'est parti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      case _SheetState.running:
        return const SizedBox(height: 36);
      case _SheetState.success:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Super, merci', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );
      case _SheetState.failure:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: Colors.white24),
                ),
                child: const Text('Laisser tomber', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _state = _SheetState.confirmation),
                icon: const Hi(AppIcons.refresh, size: 14, color: Colors.white),
                label: const Text('On retente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
          ],
        );
    }
  }
}

class _ResultRow extends StatelessWidget {
  final AppIcon icon;
  final Color color;
  final String message;
  const _ResultRow({required this.icon, required this.color, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hi(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
