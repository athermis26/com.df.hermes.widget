import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'helpers.dart';

enum WindowMode { bubble, panel }

/// Pilote la fenêtre Flutter Desktop pour basculer entre :
///   • mode **bulle**   – pastille flottante 72×72 en bas-droite
///   • mode **panneau** – widget déployé 390×640
///
/// On expose un [ValueNotifier] pour que l'UI réagisse au changement.
class HermesWindow {
  HermesWindow._();
  static final instance = HermesWindow._();

  static const Size bubbleSize = Size(72, 72);
  static const Size panelSize = Size(440, 720);

  final ValueNotifier<WindowMode> mode = ValueNotifier(WindowMode.panel);

  Future<void> setMode(WindowMode m) async {
    if (mode.value == m) return;
    mode.value = m;
    final target = m == WindowMode.bubble ? bubbleSize : panelSize;
    await windowManager.setSize(target);
    await Helpers.positionWindowBottomRight();
    if (kDebugMode) debugPrint('[HermesWindow] mode → $m');
  }

  Future<void> toBubble() => setMode(WindowMode.bubble);
  Future<void> toPanel() => setMode(WindowMode.panel);
  Future<void> toggle() =>
      setMode(mode.value == WindowMode.bubble ? WindowMode.panel : WindowMode.bubble);
}
