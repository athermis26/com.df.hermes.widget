import 'package:flutter/foundation.dart';

/// Permet à n'importe quel écran (Vue 360, carte ticket…) de demander
/// au tab Assistant de lancer le wizard de création de case.
/// L'AiTab écoute ce notifier et démarre la création quand il s'incrémente.
class AiWizardTrigger {
  AiWizardTrigger._();
  static final instance = AiWizardTrigger._();

  /// Incrémenté à chaque demande de lancement.
  final ValueNotifier<int> createCase = ValueNotifier<int>(0);

  void requestCreateCase() => createCase.value++;
}
