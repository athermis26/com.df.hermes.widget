import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/screen_pop.dart';
import '../core/window_controller.dart';
import '../widgets/bubble_view.dart';
import '../widgets/panel_view.dart';

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
    return ValueListenableBuilder<WindowMode>(
      valueListenable: HermesWindow.instance.mode,
      builder: (_, mode, child) {
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
  }
}