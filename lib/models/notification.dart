enum NotifType { slaWarning, caseAssigned, caseTransferred, retourFile, info }

class AppNotification {
  final String id;
  final NotifType type;
  final String titre;
  final String message;
  final DateTime date;
  final String? clientIdLie;
  final bool lue;

  const AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.date,
    this.clientIdLie,
    this.lue = false,
  });
}
