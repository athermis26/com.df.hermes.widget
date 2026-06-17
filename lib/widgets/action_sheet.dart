import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/client.dart';
import '../models/quick_action.dart';
import 'hi.dart';
import '../core/theme/theme_controller.dart';

/// Bottom sheet de confirmation + simulation d'une [QuickAction].
/// Réutilisable depuis l'onglet Actions ou une card de ticket.
class ActionSheet extends StatefulWidget {
  final QuickAction action;
  final Client? client;
  const ActionSheet({super.key, required this.action, required this.client});

  /// Helper pour ouvrir la sheet.
  static Future<void> show(BuildContext context, QuickAction a, Client? c) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ActionSheet(action: a, client: c),
    );
  }

  @override
  State<ActionSheet> createState() => _ActionSheetState();
}

enum _SheetState { confirmation, running, success, failure }

class _ActionSheetState extends State<ActionSheet> {
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
    final url = (widget.action.hermesPath ??
            '/client/{id}/actions/${widget.action.id}')
        .replaceAll('{id}', id);
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
              child: Text('Direction HERMÈS web : $url',
                  style: TextStyle(color: P.text, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Text(widget.action.label,
                  style: TextStyle(
                      color: P.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (widget.client != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Pour ${widget.client!.nom} · ${widget.client!.numeroPrincipal}',
                  style: TextStyle(color: P.muted, fontSize: 10.5),
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
        return Text(widget.action.description,
            style: TextStyle(
                color: P.muted, fontSize: 11.5, height: 1.4));
      case _SheetState.running:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              SizedBox(width: 10),
              Text('Un instant, on s\'en occupe…',
                  style: TextStyle(color: P.text, fontSize: 12)),
            ],
          ),
        );
      case _SheetState.success:
        return _ResultRow(
            icon: AppIcons.checkCircle,
            color: AppColors.success,
            message: _resultMessage!);
      case _SheetState.failure:
        return _ResultRow(
            icon: AppIcons.errorCircle,
            color: AppColors.danger,
            message: _resultMessage!);
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
                  foregroundColor: P.muted,
                  side: const BorderSide(color: Colors.white24)),
              child: const Text('Plus tard', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _openInHermes,
              icon: const Hi(AppIcons.openExternal, size: 14, color: Colors.black),
              label: const Text('Continuer sur HERMÈS',
                  style: TextStyle(fontSize: 11.5)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black),
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
                    foregroundColor: P.muted,
                    side: const BorderSide(color: Colors.white24)),
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
                    foregroundColor: Colors.white),
                child: const Text('OK, c\'est parti',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Super, merci',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );
      case _SheetState.failure:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: P.muted,
                    side: const BorderSide(color: Colors.white24)),
                child: const Text('Laisser tomber', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _state = _SheetState.confirmation),
                icon: const Hi(AppIcons.refresh, size: 14, color: Colors.white),
                label: const Text('On retente',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
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
            child: Text(message,
                style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35)),
          ),
        ],
      ),
    );
  }
}
