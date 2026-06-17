import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class Helpers {
  static const String trayIconPath = 'assets/icon/tray_icon.ico';
  static const String trayIconPngPath = 'assets/icon/tray_icon.png';

  static Future<void> positionWindowBottomRight() async {
    final windowSize = await windowManager.getSize();

    double screenWidth = 1920;
    double screenHeight = 1080;
    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      screenWidth = primaryDisplay.size.width;
      screenHeight = primaryDisplay.size.height;
    } catch (_) {}

    final x = screenWidth - windowSize.width - 20;
    final y = screenHeight - windowSize.height - 60;
    await windowManager.setPosition(Offset(x, y));
  }

  static Future<void> initSystemTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? trayIconPath : trayIconPngPath,
    );
    await trayManager.setToolTip('HERMÈS · CRM 360° Orange CI');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show_window', label: 'Ouvrir HERMÈS'),
          MenuItem(key: 'hide_window', label: 'Mettre de côté'),
          MenuItem.separator(),
          MenuItem(key: 'simulate_call', label: 'Simuler un appel entrant'),
          MenuItem.separator(),
          MenuItem(key: 'switch_profile', label: 'Changer de profil'),
          MenuItem(key: 'quit_app', label: 'Fermer complètement'),
        ],
      ),
    );
  }
}
