import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/app_icons.dart';
import '../core/client_selection.dart';
import '../core/conseiller_state.dart';
import '../core/panel_nav.dart';
import '../core/screen_pop.dart';
import '../core/theme/app_colors.dart';
import '../core/window_controller.dart';
import '../mock/mock_data.dart';
import '../models/client.dart';
import '../models/conseiller.dart';
import '../page/tabs/actions_tab.dart';
import '../page/tabs/ai_tab.dart';
import '../page/tabs/notifications_tab.dart';
import '../page/tabs/search_tab.dart';
import '../page/tabs/vue360_tab.dart';
import 'hi.dart';

class PanelView extends StatefulWidget {
  const PanelView({super.key});

  @override
  State<PanelView> createState() => _PanelViewState();
}

class _PanelViewState extends State<PanelView> {
  static const _tabs = <_TabDef>[
    _TabDef('Recherche', AppIcons.tabSearch),
    _TabDef('Assistant', AppIcons.tabAi),
    _TabDef('Actions', AppIcons.tabActions),
    _TabDef('Activité', AppIcons.tabNotifs),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark,
          border: Border.all(color: Colors.white12),
        ),
        child: ValueListenableBuilder<Client?>(
          valueListenable: ClientSelection.instance.current,
          builder: (_, client, _) {
            final firstTab = client != null
                ? Vue360Tab(
                    key: ValueKey('vue360-${client.id}'),
                    client: client,
                    onBack: ClientSelection.instance.clear,
                  )
                : const SearchTab();
            return ValueListenableBuilder<int>(
              valueListenable: PanelNav.instance.tabIndex,
              builder: (_, idx, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PanelHeader(),
                  Expanded(
                    child: IndexedStack(
                      index: idx,
                      children: [
                        firstTab,
                        const AiTab(),
                        const ActionsTab(),
                        const NotificationsTab(),
                      ],
                    ),
                  ),
                  _BottomNav(
                    index: idx,
                    tabs: _tabs,
                    onTap: PanelNav.instance.goTo,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final AppIcon icon;
  const _TabDef(this.label, this.icon);
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Row(
          children: [
            const Hi(AppIcons.agent, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HERMES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  _ConseillerLine(),
                ],
              ),
            ),
            _IconBtn(
              icon: AppIcons.callIncoming,
              tooltip: 'Simuler un appel entrant',
              onTap: () => ScreenPop.instance.simulateIncomingCall(context),
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

class _ConseillerLine extends StatelessWidget {
  const _ConseillerLine();

  static ({Color color, String label}) _statut(StatutConseiller s) {
    switch (s) {
      case StatutConseiller.disponible:
        return (color: AppColors.success, label: 'Disponible');
      case StatutConseiller.enTraitement:
        return (color: AppColors.warning, label: 'En ligne avec un client');
      case StatutConseiller.pause:
        return (color: AppColors.textMuted, label: 'En pause');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StatutConseiller>(
      valueListenable: ConseillerState.instance.statut,
      builder: (_, s, _) {
        final info = _statut(s);
        final prenom = mockConseiller.nom.split(' ').first;
        return Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              'Bonjour $prenom · ${info.label}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
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

class _BottomNav extends StatelessWidget {
  final int index;
  final List<_TabDef> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == index;
          final t = tabs[i];
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hi(
                    t.icon,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
