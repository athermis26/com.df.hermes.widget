import 'dart:math';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../mock/mock_data.dart';
import '../models/client.dart';
import '../widgets/incoming_call_dialog.dart';
import 'client_selection.dart';
import 'conseiller_state.dart';
import 'window_controller.dart';

/// Simule un screen-pop comme s'il était poussé par Genesys / Dimelo :
///   1. Force l'affichage du widget (panneau, au premier plan).
///   2. Pioche un client aléatoirement dans le mock.
///   3. Affiche l'overlay « appel entrant ».
///   4. Sur décrochage : sélection du client + démarrage DMT + Vue 360.
class ScreenPop {
  ScreenPop._();
  static final instance = ScreenPop._();

  final _rand = Random();
  bool _open = false;

  Future<void> simulateIncomingCall(BuildContext context) async {
    if (_open) return; // évite les doubles déclenchements
    _open = true;
    try {
      // 1. Sortir de mode bulle si besoin + remonter au premier plan
      if (HermesWindow.instance.mode.value == WindowMode.bubble) {
        await HermesWindow.instance.toPanel();
      }
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);

      // 2. Pioche un client
      final Client client = mockClients[_rand.nextInt(mockClients.length)];

      if (!context.mounted) return;

      // 3. Overlay appel entrant
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (_) => IncomingCallDialog(client: client),
      );

      // 4. Décrochage → on enchaîne sur la Vue 360 + chrono DMT
      if (accepted == true) {
        ClientSelection.instance.select(client);
        ConseillerState.instance.demarrerPriseEnCharge();
      }
    } finally {
      _open = false;
    }
  }
}
