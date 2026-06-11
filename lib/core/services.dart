import '../repositories/client_repository.dart';
import '../repositories/mock_client_repository.dart';
import '../services/ai_assistant_service.dart';

/// Point d'accès central aux services.
/// Pour brancher le vrai backend : remplacer chaque champ par
/// l'implémentation réelle (Booster pour le repo, vrai LLM pour l'IA).
class AppServices {
  AppServices._();
  static final ClientRepository clientRepository = MockClientRepository();
  static final AiAssistantService aiAssistantService = MockAiAssistantService();
}
