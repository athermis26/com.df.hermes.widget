enum ProfilConseiller { callCenter, agence, digital, superviseur }

enum StatutConseiller { disponible, enTraitement, pause }

class Conseiller {
  final String id;
  final String nom;
  final ProfilConseiller profil;
  final String agence;

  const Conseiller({
    required this.id,
    required this.nom,
    required this.profil,
    required this.agence,
  });
}
