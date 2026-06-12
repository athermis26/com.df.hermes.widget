import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/conseiller_state.dart';
import '../core/screen_pop.dart';
import '../core/session.dart';
import '../core/ticket_selection.dart';
import '../core/window_controller.dart';
import '../models/conseiller.dart';
import '../widgets/bubble_view.dart';
import '../widgets/panel_view.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    final visible = await windowManager.isVisible();
    if (visible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'hide_window':
        await windowManager.hide();
        break;
      case 'simulate_call':
        if (!mounted) return;
        await ScreenPop.instance.simulateIncomingCall(context);
        break;
      case 'switch_profile':
        // Déconnexion → repasse sur l'écran de login
        ConseillerState.instance.setStatut(StatutConseiller.disponible);
        TicketSelection.instance.clear();
        Session.instance.logout();
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'quit_app':
        await trayManager.destroy();
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
        exit(0);
    }
  }

  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Conseiller?>(
      valueListenable: Session.instance.current,
      builder: (_, conseiller, _) {
        // Pas connecté → écran de login (toujours en mode panneau)
        if (conseiller == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: const LoginPage(),
          );
        }
        // Connecté → bascule bulle / panneau classique
        return ValueListenableBuilder<WindowMode>(
          valueListenable: HermesWindow.instance.mode,
          builder: (_, mode, _) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                child: mode == WindowMode.bubble
                    ? const BubbleView(key: ValueKey('bubble'))
                    : const PanelView(key: ValueKey('panel')),
              ),
            );
          },
        );
      },
    );
  }
}
