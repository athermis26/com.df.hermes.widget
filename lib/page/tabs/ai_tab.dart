import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/client_selection.dart';
import '../../core/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client.dart';
import '../../widgets/hi.dart';

class AiTab extends StatefulWidget {
  const AiTab({super.key});
  @override
  State<AiTab> createState() => _AiTabState();
}

enum _Sender { user, assistant }

class _Msg {
  final _Sender sender;
  String text;
  final bool streaming;
  _Msg(this.sender, this.text, {this.streaming = false});
}

class _AiTabState extends State<AiTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  StreamSubscription<String>? _sub;
  bool _isStreaming = false;
  Client? _lastContext;

  @override
  void initState() {
    super.initState();
    ClientSelection.instance.current.addListener(_onClientChanged);
  }

  @override
  void dispose() {
    ClientSelection.instance.current.removeListener(_onClientChanged);
    _sub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onClientChanged() {
    final c = ClientSelection.instance.current.value;
    if (c?.id != _lastContext?.id) {
      _sub?.cancel();
      setState(() {
        _messages.clear();
        _isStreaming = false;
        _lastContext = c;
      });
    }
  }

  void _send(String prompt) {
    final p = prompt.trim();
    if (p.isEmpty || _isStreaming) return;
    final client = ClientSelection.instance.current.value;
    _input.clear();
    setState(() {
      _messages.add(_Msg(_Sender.user, p));
      _messages.add(_Msg(_Sender.assistant, '', streaming: true));
      _isStreaming = true;
    });
    _scrollDown();

    final stream = AppServices.aiAssistantService.ask(p, clientContext: client);
    _sub = stream.listen(
      (token) {
        setState(() => _messages.last.text += token);
        _scrollDown();
      },
      onDone: () {
        setState(() => _isStreaming = false);
        _scrollDown();
      },
      onError: (_) {
        setState(() {
          _messages.last.text = '⚠️ Hmm, je n\'arrive pas à répondre. On réessaie ?';
          _isStreaming = false;
        });
      },
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Client?>(
      valueListenable: ClientSelection.instance.current,
      builder: (_, client, _) {
        return Column(
          children: [
            _ContextBar(client: client),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(client: client)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
                    ),
            ),
            if (client != null) _Suggestions(client: client, onTap: _send, disabled: _isStreaming),
            _Input(
              controller: _input,
              enabled: !_isStreaming,
              onSubmit: _send,
            ),
          ],
        );
      },
    );
  }
}

// ─── Barre de contexte client ────────────────────────────────────

class _ContextBar extends StatelessWidget {
  final Client? client;
  const _ContextBar({required this.client});
  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: const Row(
          children: [
            Hi(AppIcons.info, size: 14, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Personne en ligne pour l\'instant',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Hi(AppIcons.sparkle, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Je connais ${client!.nom} · ${client!.type} · ${client!.segment}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Client? client;
  const _EmptyState({required this.client});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hi(AppIcons.sparkle, size: 42, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Votre assistant IA',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              client == null
                  ? 'Trouvez d\'abord un client dans la recherche, et je vous prépare une analyse aux petits oignons.'
                  : 'Posez-moi une question, ou piochez dans les suggestions ci-dessous.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bulles ──────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    final bg = isUser ? AppColors.primary : AppColors.darkSurface;
    final fg = isUser ? Colors.white : AppColors.textLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: Hi(AppIcons.sparkle, size: 12, color: Colors.white),
            ),
          if (!isUser) const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: bg,
                border: isUser ? null : Border.all(color: Colors.white10),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(isUser ? 10 : 2),
                  bottomRight: Radius.circular(isUser ? 2 : 10),
                ),
              ),
              child: msg.streaming && msg.text.isEmpty
                  ? const _TypingDots()
                  : Text(
                      msg.text.trim(),
                      style: TextStyle(color: fg, fontSize: 12, height: 1.35),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        Widget dot(int i) {
          final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
          final op = (1 - (t - 0.5).abs() * 2).clamp(0.3, 1.0);
          return Container(
            width: 5, height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: op),
              shape: BoxShape.circle,
            ),
          );
        }
        return Row(mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1), dot(2)]);
      },
    );
  }
}

// ─── Suggestions ─────────────────────────────────────────────────

class _Suggestions extends StatelessWidget {
  final Client client;
  final ValueChanged<String> onTap;
  final bool disabled;
  const _Suggestions({required this.client, required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final ia = client.ia;
    final chips = <_Sugg>[
      _Sugg('Résume-moi tout ça', AppIcons.summarize, 'Résume la situation de ce client'),
      _Sugg('Risque de partir ?', AppIcons.churn, 'Quel est son risque de churn ?'),
      _Sugg('Une offre à proposer ?', AppIcons.offer, 'Quelle offre lui proposer ?'),
      _Sugg('Sa dernière fois ?', AppIcons.history, 'Quelle est la dernière interaction ?'),
      _Sugg('Quel ton adopter ?', AppIcons.voice, 'Quel ton dois-je adopter avec lui ?'),
      _Sugg('Un petit geste ?', AppIcons.gift, 'Quel geste commercial proposer ?'),
      _Sugg(
        '🎯 ${ia.offreRecommandee}',
        AppIcons.sparkle,
        'Pourquoi recommander : ${ia.offreRecommandee} ?',
      ),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final s = chips[i];
            return InkWell(
              onTap: disabled ? null : () => onTap(s.prompt),
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hi(s.icon, size: 12, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(s.label, style: const TextStyle(color: AppColors.textLight, fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Sugg {
  final String label;
  final AppIcon icon;
  final String prompt;
  _Sugg(this.label, this.icon, this.prompt);
}

// ─── Champ de saisie ─────────────────────────────────────────────

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmit;
  const _Input({required this.controller, required this.enabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(color: AppColors.dark),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                hintText: enabled ? 'Posez-moi une question…' : 'Une seconde, je réfléchis…',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: enabled ? AppColors.primary : AppColors.darkSurface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onSubmit(controller.text) : null,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Hi(AppIcons.send, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
