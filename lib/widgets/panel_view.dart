import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/app_icons.dart';
import '../core/client_selection.dart';
import '../core/conseiller_state.dart';
import '../core/panel_nav.dart';
import '../core/screen_pop.dart';
import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/ticket_selection.dart';
import '../core/window_controller.dart';
import '../mock/mock_data.dart';
import '../models/client.dart';
import '../models/conseiller.dart';
import '../models/ticket.dart';
import '../page/tabs/ai_tab.dart';
import '../page/tabs/chat_tab.dart';
import '../page/tabs/queue_tab.dart';
import '../page/tabs/vue360_tab.dart';
import 'broadcast_bar.dart';
import 'hi.dart';
import 'notifications_popover.dart';
import 'persistent_search_bar.dart';
import 'search_results_overlay.dart';
import '../core/theme/theme_controller.dart';

class PanelView extends StatefulWidget {
  const PanelView({super.key});

  @override
  State<PanelView> createState() => _PanelViewState();
}

class _PanelViewState extends State<PanelView> {
  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _notifsEntry;

  @override
  void initState() {
    super.initState();
    // Bascule auto vers Vue 360 quand un client est sélectionné depuis
    // ailleurs (file, recherche, screen-pop, notif).
    ClientSelection.instance.current.addListener(_onClientChanged);
  }

  void _onClientChanged() {
    final client = ClientSelection.instance.current.value;
    if (client != null && PanelNav.instance.current.value != PanelRoute.vue360) {
      PanelNav.instance.go(PanelRoute.vue360);
    }
  }

  void _toggleNotifs() {
    if (_notifsEntry != null) {
      _closeNotifs();
      return;
    }
    final renderBox =
        _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final pos = renderBox.localToGlobal(Offset.zero);
    _notifsEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeNotifs,
            ),
          ),
          Positioned(
            top: pos.dy + renderBox.size.height + 4,
            right: 8,
            child: SizedBox(
              width: 320,
              child: NotificationsPopover(onClose: _closeNotifs),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_notifsEntry!);
  }

  void _closeNotifs() {
    _notifsEntry?.remove();
    _notifsEntry = null;
  }

  @override
  void dispose() {
    ClientSelection.instance.current.removeListener(_onClientChanged);
    _notifsEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: P.bg,
          border: Border.all(color: Colors.white12),
        ),
        child: ValueListenableBuilder<Client?>(
          valueListenable: ClientSelection.instance.current,
          builder: (_, client, _) {
            return ValueListenableBuilder<PanelRoute>(
              valueListenable: PanelNav.instance.current,
              builder: (_, route, _) {
                Widget body;
                switch (route) {
                  case PanelRoute.queue:
                    body = const QueueTab();
                    break;
                  case PanelRoute.vue360:
                    body = client != null
                        ? Vue360Tab(
                            key: ValueKey('vue360-${client.id}'),
                            client: client,
                            onBack: TicketSelection.instance.clear,
                          )
                        : const _NoClientPlaceholder();
                    break;
                  case PanelRoute.assistant:
                    body = const AiTab();
                    break;
                  case PanelRoute.chat:
                    body = const ChatTab();
                    break;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(bellKey: _bellKey, onBellTap: _toggleNotifs),
                    const BroadcastBar(),
                    Expanded(
                      child: Stack(
                        children: [
                          body,
                          const Positioned(
                            top: 0, left: 0, right: 0,
                            child: SearchResultsOverlay(),
                          ),
                        ],
                      ),
                    ),
                    _BottomNav(current: route),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GlobalKey bellKey;
  final VoidCallback onBellTap;
  const _TopBar({required this.bellKey, required this.onBellTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        children: [
          _HeaderRow(bellKey: bellKey, onBellTap: onBellTap),
          const PersistentSearchBar(),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final GlobalKey bellKey;
  final VoidCallback onBellTap;
  const _HeaderRow({required this.bellKey, required this.onBellTap});

  void _cloturer() {
    ConseillerState.instance.raccrocher();
    TicketSelection.instance.clear();
  }

  void _changeProfile() {
    TicketSelection.instance.clear();
    ConseillerState.instance.setStatut(StatutConseiller.disponible);
    PanelNav.instance.reset();
    Session.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Évite les overflow lors de la transition panel → bulle
      // (fenêtre rétrécit à 64 px avant le swap de widget).
      if (c.maxWidth < 220) return const SizedBox.shrink();
      return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/icon/master_logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Expanded(child: _ConseillerLine()),
            // Bouton « Clôturer » si appel actif (visible partout)
            ValueListenableBuilder<Ticket?>(
              valueListenable: ConseillerState.instance.activeTicket,
              builder: (_, active, _) {
                if (active == null) return const SizedBox.shrink();
                return Tooltip(
                  message: 'Clôturer l\'interaction en cours',
                  child: InkWell(
                    onTap: _cloturer,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hi(AppIcons.cloturer, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Clôturer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Toggle thème sombre / clair
            ValueListenableBuilder<bool>(
              valueListenable: ThemeController.instance.isDark,
              builder: (_, isDark, _) => _IconBtn(
                icon: isDark ? AppIcons.themeLight : AppIcons.themeDark,
                tooltip: isDark ? 'Passer en thème clair' : 'Passer en thème sombre',
                onTap: ThemeController.instance.toggle,
              ),
            ),
            // Cloche notifications avec badge
            _BellButton(bellKey: bellKey, onTap: onBellTap),
            // Simuler appel entrant
            _IconBtn(
              icon: AppIcons.callIncoming,
              tooltip: 'Simuler un appel entrant',
              onTap: () => ScreenPop.instance.simulateIncomingCall(context),
            ),
            // Menu ⋮
            PopupMenuButton<String>(
              tooltip: 'Plus d\'options',
              color: P.surface,
              icon: const Hi(AppIcons.moreVertical, color: Colors.white, size: 18),
              padding: const EdgeInsets.all(6),
              onSelected: (v) {
                switch (v) {
                  case 'dispo':
                    ConseillerState.instance.setStatut(StatutConseiller.disponible);
                    break;
                  case 'pause':
                    ConseillerState.instance.setStatut(StatutConseiller.pause);
                    break;
                  case 'switch':
                    _changeProfile();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'dispo',
                  height: 36,
                  child: Row(children: [
                    Hi(AppIcons.statusOk, size: 14, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Me rendre disponible',
                        style: TextStyle(color: P.text, fontSize: 12)),
                  ]),
                ),
                PopupMenuItem<String>(
                  value: 'pause',
                  height: 36,
                  child: Row(children: [
                    Hi(AppIcons.statusPause, size: 14, color: P.muted),
                    SizedBox(width: 8),
                    Text('Me mettre en pause',
                        style: TextStyle(color: P.text, fontSize: 12)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'switch',
                  height: 36,
                  child: Row(children: [
                    Hi(AppIcons.switchUser, size: 14, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Changer de profil',
                        style: TextStyle(color: P.text, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            _IconBtn(
              icon: AppIcons.minimize,
              tooltip: 'Réduire en bulle',
              onTap: () => HermesWindow.instance.toBubble(),
            ),
            _IconBtn(
              icon: AppIcons.close,
              tooltip: 'Mettre de côté',
              onTap: () => windowManager.hide(),
            ),
          ],
        ),
      ),
    );
    });
  }
}

class _BellButton extends StatelessWidget {
  final GlobalKey bellKey;
  final VoidCallback onTap;
  const _BellButton({required this.bellKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = mockNotifications.where((n) => !n.lue).length;
    return Tooltip(
      message: 'Vos notifications',
      child: InkWell(
        key: bellKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.all(6),
              child: Hi(AppIcons.tabNotifs, color: Colors.white, size: 18),
            ),
            if (unread > 0)
              Positioned(
                top: 2, right: 2,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConseillerLine extends StatelessWidget {
  const _ConseillerLine();

  static ({Color color, String label}) _statut(StatutConseiller s) {
    switch (s) {
      case StatutConseiller.disponible:
        return (color: AppColors.success, label: 'Disponible');
      case StatutConseiller.enTraitement:
        return (color: AppColors.warning, label: 'En interaction');
      case StatutConseiller.pause:
        return (color: P.muted, label: 'Pause');
    }
  }

  String _profilLabel(ProfilConseiller p) {
    switch (p) {
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StatutConseiller>(
      valueListenable: ConseillerState.instance.statut,
      builder: (_, s, _) {
        final info = _statut(s);
        final agent = Session.instance.current.value;
        final prenom = agent?.nom.split(' ').first ?? 'agent';
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour $prenom',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '${info.label} · ${_profilLabel(agent?.profil ?? ProfilConseiller.callCenter)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  final AppIcon icon;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Hi(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─── BottomNavigation ────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final PanelRoute current;
  const _BottomNav({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: P.surface,
        border: Border(top: BorderSide(color: P.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _NavItem(
            icon: AppIcons.tabQueue,
            label: 'File',
            active: current == PanelRoute.queue,
            onTap: () => PanelNav.instance.go(PanelRoute.queue),
          ),
          _NavItem(
            icon: AppIcons.tabVue360,
            label: 'Vue 360',
            active: current == PanelRoute.vue360,
            onTap: () => PanelNav.instance.go(PanelRoute.vue360),
          ),
          _NavItem(
            icon: AppIcons.tabAi,
            label: 'Assistant',
            active: current == PanelRoute.assistant,
            onTap: () => PanelNav.instance.go(PanelRoute.assistant),
          ),
          _NavItem(
            icon: AppIcons.tabChat,
            label: 'Chat',
            active: current == PanelRoute.chat,
            onTap: () => PanelNav.instance.go(PanelRoute.chat),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : P.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hi(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoClientPlaceholder extends StatelessWidget {
  const _NoClientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: P.bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hi(AppIcons.tabVue360, color: P.muted, size: 28),
          const SizedBox(height: 8),
          Text(
            'Aucun client sélectionné',
            style: TextStyle(
              color: P.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choisissez un client depuis la file d\'attente, la recherche\nou une notification pour afficher la Vue 360.',
            textAlign: TextAlign.center,
            style: TextStyle(color: P.muted, fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => PanelNav.instance.go(PanelRoute.queue),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Aller à la file',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
