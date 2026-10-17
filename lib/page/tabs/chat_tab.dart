import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../mock/mock_chat.dart';
import '../../models/conseiller.dart';
import '../../widgets/hi.dart';

/// Chat communautaire HERMÈS — mocké, mais animé par un simulateur
/// qui injecte régulièrement des messages pour donner l'illusion d'une
/// vraie activité d'équipe.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  String _activeChannelId = mockChatChannels.first.id;
  final Map<String, List<ChatMessage>> _messages = {
    for (final c in mockChatChannels)
      c.id: List<ChatMessage>.from(mockChatMessages[c.id] ?? const []),
  };
  final Map<String, int> _unread = {
    for (final c in mockChatChannels) c.id: c.unread,
  };

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _rand = Random();
  Timer? _simulator;
  int _msgCounter = 0;

  @override
  void initState() {
    super.initState();
    _unread[_activeChannelId] = 0;
    _simulator = Timer.periodic(const Duration(seconds: 9), (_) => _simulate());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _simulator?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _simulate() {
    if (!mounted) return;
    final channel = mockChatChannels[_rand.nextInt(mockChatChannels.length)];
    final author = mockChatAuthors[_rand.nextInt(mockChatAuthors.length)];
    final text = mockChatSimulatedSnippets[
        _rand.nextInt(mockChatSimulatedSnippets.length)];
    final msg = ChatMessage(
      id: 'sim${DateTime.now().microsecondsSinceEpoch}',
      channelId: channel.id,
      author: author,
      text: text,
      sentAt: DateTime.now(),
    );
    setState(() {
      _messages[channel.id]!.add(msg);
      if (channel.id != _activeChannelId) {
        _unread[channel.id] = (_unread[channel.id] ?? 0) + 1;
      }
    });
    if (channel.id == _activeChannelId) _scrollToBottom();
  }

  void _selectChannel(String id) {
    if (id == _activeChannelId) return;
    setState(() {
      _activeChannelId = id;
      _unread[id] = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final agent = Session.instance.current.value;
    final me = ChatAuthor(
      id: agent?.id ?? 'me',
      nom: agent?.nom ?? 'Vous',
      profil: agent?.profil ?? ProfilConseiller.callCenter,
      agence: agent?.agence ?? '—',
    );
    final msg = ChatMessage(
      id: 'me${_msgCounter++}',
      channelId: _activeChannelId,
      author: me,
      text: text,
      sentAt: DateTime.now(),
      fromMe: true,
    );
    setState(() {
      _messages[_activeChannelId]!.add(msg);
      _input.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages[_activeChannelId] ?? const <ChatMessage>[];
    return Container(
      color: P.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChannelsSidebar(
            activeId: _activeChannelId,
            unread: _unread,
            onSelect: _selectChannel,
          ),
          Expanded(
            child: Column(
              children: [
                _ChannelHeader(
                  channel: mockChatChannels
                      .firstWhere((c) => c.id == _activeChannelId),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          itemCount: messages.length,
                          itemBuilder: (_, i) =>
                              _MessageBubble(message: messages[i]),
                        ),
                ),
                _Composer(controller: _input, onSend: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar des salons ───────────────────────────────────────────

class _ChannelsSidebar extends StatelessWidget {
  final String activeId;
  final Map<String, int> unread;
  final void Function(String) onSelect;
  const _ChannelsSidebar({
    required this.activeId,
    required this.unread,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(right: BorderSide(color: P.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              'Salons',
              style: TextStyle(
                color: P.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 2),
              children: [
                for (final c in mockChatChannels)
                  _ChannelTile(
                    channel: c,
                    active: c.id == activeId,
                    unread: unread[c.id] ?? 0,
                    onTap: () => onSelect(c.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final ChatChannel channel;
  final bool active;
  final int unread;
  final VoidCallback onTap;
  const _ChannelTile({
    required this.channel,
    required this.active,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.12) : null,
          border: Border(
            left: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppColors.primary : P.text,
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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

// ─── Header du salon courant ─────────────────────────────────────

class _ChannelHeader extends StatelessWidget {
  final ChatChannel channel;
  const _ChannelHeader({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(bottom: BorderSide(color: P.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            channel.name,
            style: TextStyle(
              color: P.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            channel.description,
            style: TextStyle(color: P.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Bulle de message ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    final bubbleColor = me ? AppColors.primary : P.surface;
    final textColor = me ? Colors.white : P.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!me) _Avatar(initials: _initials(message.author.nom)),
          if (!me) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!me)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      message.author.nom,
                      style: TextStyle(
                        color: P.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10),
                      topRight: const Radius.circular(10),
                      bottomLeft: Radius.circular(me ? 10 : 2),
                      bottomRight: Radius.circular(me ? 2 : 10),
                    ),
                    border: me ? null : Border.all(color: P.borderSoft),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 11.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                  child: Text(
                    _hhmm(message.sentAt),
                    style: TextStyle(color: P.muted, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          if (me) const SizedBox(width: 6),
          if (me) _Avatar(initials: _initials(message.author.nom), me: true),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool me;
  const _Avatar({required this.initials, this.me = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: me ? AppColors.primary : P.borderStrong,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Composer ─────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(top: BorderSide(color: P.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(color: P.text, fontSize: 11.5),
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Écrire un message…',
                hintStyle: TextStyle(color: P.muted, fontSize: 11.5),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: P.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: P.borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: P.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Hi(AppIcons.send, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hi(AppIcons.tabChat, color: P.muted, size: 22),
          const SizedBox(height: 6),
          Text(
            'Aucun message pour le moment',
            style: TextStyle(color: P.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
