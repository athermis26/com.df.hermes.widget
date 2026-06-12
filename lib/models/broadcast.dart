enum BroadcastSeverity { info, warning, danger }

class BroadcastMessage {
  final String id;
  final BroadcastSeverity severity;
  final String text;

  const BroadcastMessage({
    required this.id,
    required this.severity,
    required this.text,
  });
}
