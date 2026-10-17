import '../models/conseiller.dart';

/// Salons disponibles dans le chat communautaire HERMÈS.
class ChatChannel {
  final String id;
  final String name;
  final String description;
  final int unread;
  const ChatChannel({
    required this.id,
    required this.name,
    required this.description,
    this.unread = 0,
  });
}

class ChatAuthor {
  final String id;
  final String nom;
  final ProfilConseiller profil;
  final String agence;
  const ChatAuthor({
    required this.id,
    required this.nom,
    required this.profil,
    required this.agence,
  });
}

class ChatMessage {
  final String id;
  final String channelId;
  final ChatAuthor author;
  final String text;
  final DateTime sentAt;
  final bool fromMe;
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.author,
    required this.text,
    required this.sentAt,
    this.fromMe = false,
  });
}

const mockChatChannels = <ChatChannel>[
  ChatChannel(
    id: 'general',
    name: '#général',
    description: 'Annonces et discussions communes',
    unread: 2,
  ),
  ChatChannel(
    id: 'reseau',
    name: '#réseau-incidents',
    description: 'Coupures, dérangements, pannes en cours',
    unread: 4,
  ),
  ChatChannel(
    id: 'om',
    name: '#orange-money',
    description: 'Transactions, litiges, plafonds',
  ),
  ChatChannel(
    id: 'entraide',
    name: '#entraide-conseillers',
    description: 'Astuces, procédures, partage de cas',
    unread: 1,
  ),
];

const mockChatAuthors = <ChatAuthor>[
  ChatAuthor(id: 'a1', nom: 'Awa Diop', profil: ProfilConseiller.callCenter, agence: 'Plateau'),
  ChatAuthor(id: 'a2', nom: 'Marc Koné', profil: ProfilConseiller.agence, agence: 'Cocody'),
  ChatAuthor(id: 'a3', nom: 'Fatou Sylla', profil: ProfilConseiller.superviseur, agence: 'Siège'),
  ChatAuthor(id: 'a4', nom: 'Ibrahim Touré', profil: ProfilConseiller.digital, agence: 'Plateau'),
  ChatAuthor(id: 'a5', nom: 'Léa Mensah', profil: ProfilConseiller.callCenter, agence: 'Treichville'),
];

/// Messages par salon — déjà ordonnés du plus ancien au plus récent.
final Map<String, List<ChatMessage>> mockChatMessages = {
  'general': [
    ChatMessage(
      id: 'g1',
      channelId: 'general',
      author: mockChatAuthors[2],
      text: 'Bonjour à toutes et tous, n\'oubliez pas le brief qualité à 14h.',
      sentAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 12)),
    ),
    ChatMessage(
      id: 'g2',
      channelId: 'general',
      author: mockChatAuthors[0],
      text: 'Bien noté ✋',
      sentAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 8)),
    ),
    ChatMessage(
      id: 'g3',
      channelId: 'general',
      author: mockChatAuthors[1],
      text: 'Quelqu\'un a le lien du replay de la formation Orange Money ?',
      sentAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
  ],
  'reseau': [
    ChatMessage(
      id: 'r1',
      channelId: 'reseau',
      author: mockChatAuthors[3],
      text: 'Incident fibre signalé sur Cocody — équipe NOC informée.',
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
    ),
    ChatMessage(
      id: 'r2',
      channelId: 'reseau',
      author: mockChatAuthors[2],
      text: 'ETR communiqué : 17h. Merci de temporiser les escalades.',
      sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 35)),
    ),
    ChatMessage(
      id: 'r3',
      channelId: 'reseau',
      author: mockChatAuthors[4],
      text: 'Je reçois beaucoup d\'appels là-dessus, message diffusé aux clients ?',
      sentAt: DateTime.now().subtract(const Duration(minutes: 14)),
    ),
    ChatMessage(
      id: 'r4',
      channelId: 'reseau',
      author: mockChatAuthors[2],
      text: 'Broadcast envoyé via la barre d\'annonces, à relayer aussi en agence.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
  ],
  'om': [
    ChatMessage(
      id: 'o1',
      channelId: 'om',
      author: mockChatAuthors[0],
      text: 'Rappel : pour les transferts > 500 000 F, vérifier le KYC à jour.',
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ChatMessage(
      id: 'o2',
      channelId: 'om',
      author: mockChatAuthors[1],
      text: 'OK, j\'ai eu un litige tout à l\'heure, procédure remontée au back-office.',
      sentAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
    ),
  ],
  'entraide': [
    ChatMessage(
      id: 'e1',
      channelId: 'entraide',
      author: mockChatAuthors[4],
      text: 'Astuce : pour réinitialiser un code PUK, passer par l\'action rapide directement dans la Vue 360.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: 'e2',
      channelId: 'entraide',
      author: mockChatAuthors[3],
      text: 'Top, je ne savais pas que c\'était dispo en self-service côté conseiller 👌',
      sentAt: DateTime.now().subtract(const Duration(minutes: 47)),
    ),
  ],
};

/// Phrases utilisées par le simulateur pour donner l'illusion d'une activité.
const mockChatSimulatedSnippets = <String>[
  'Quelqu\'un sait si l\'outil OM est de nouveau dispo ?',
  'On a un client VIP en attente sur la 3e position, possible de prioriser ?',
  'Je transfère un cas complexe au superviseur dans 2 min.',
  'Bonne reprise après la pause 🙌',
  'Le script d\'objection « offre concurrente » a été mis à jour ce matin.',
  'Petit rappel : la session de coaching est décalée à 16h30.',
  'Fibre rétablie sur Plateau, validé côté NOC.',
];
