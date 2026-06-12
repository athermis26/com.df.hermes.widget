import '../models/broadcast.dart';

/// Messages broadcast diffusés sur la bande défilante du widget.
/// Modifiables à chaud en vrai — ici câblé en dur pour le POC.
const List<BroadcastMessage> mockBroadcasts = [
  BroadcastMessage(
    id: 'B-001',
    severity: BroadcastSeverity.danger,
    text: 'Panne SMS sur Yopougon depuis 09:15 – équipes en intervention.',
  ),
  BroadcastMessage(
    id: 'B-002',
    severity: BroadcastSeverity.warning,
    text: 'Maintenance Fibre Pro programmée ce soir 22h–23h.',
  ),
  BroadcastMessage(
    id: 'B-003',
    severity: BroadcastSeverity.info,
    text: 'Nouveau forfait Data 30 Go – argumentaire dispo sur HERMES.',
  ),
  BroadcastMessage(
    id: 'B-004',
    severity: BroadcastSeverity.info,
    text: 'Pensez à clôturer vos cases en fin de prise en charge.',
  ),
];
