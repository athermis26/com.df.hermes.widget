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
            return ValueListenableBuilder<List<PanelRoute>>(
              valueListenable: PanelNav.instance.stack,
              builder: (_, stack, _) {
                final route = stack.last;
                Widget body;
                if (route == PanelRoute.assistant) {
                  body = const AiTab();
                } else {
                  body = client != null
                      ? Vue360Tab(
                          key: ValueKey('vue360-${client.id}'),
                          client: client,
                          onBack: TicketSelection.instance.clear,
                        )
                      : const QueueTab();
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
            // Bouton « retour » si on est plus haut dans la pile
            ValueListenableBuilder<List<PanelRoute>>(
              valueListenable: PanelNav.instance.stack,
              builder: (_, st, _) {
                if (st.length <= 1) {
                  return Padding(
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
                  );
                }
                return _IconBtn(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: PanelNav.instance.pop,
                );
              },
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
                          Hi(AppIcons.callReject, size: 13, color: Colors.white),
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
