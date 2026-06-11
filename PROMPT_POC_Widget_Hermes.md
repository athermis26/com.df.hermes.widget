# Prompt — POC Widget compagnon HERMES (Flutter Desktop)
Ok Maintenant que nous avons notre base,

> Objectif : générer une **simulation (POC)** d'un widget de bureau, **avec des données simulées (mock)**, sans backend réel.

---

## 1. Contexte

Je construis un **widget compagnon** pour les conseillers clients d'Orange Côte d'Ivoire, en complément de l'application web HERMES (Vue 360 client). Ce widget **ne remplace pas** l'appli web : il sert aux **actions rapides** et à la **consultation d'un coup d'œil**. Tout ce qui est lourd (traitement complet d'un case, gros formulaire, action sensible) ouvre l'écran correspondant dans HERMES web via un deep-link.

Principe de conception : *si une fonction demande plus de 2-3 clics ou un grand formulaire, elle n'est pas dans le widget — elle renvoie vers le web.*

## 2. Stack & contraintes techniques

- **Flutter Desktop** (Windows en cible, mais doit tourner aussi en dev sur macOS/Linux).
- Fenêtre **sans bordure (frameless)**, **toujours au premier plan (always-on-top)**, ancrée **en bas à droite** de l'écran (utiliser `window_manager` ou `bitsdojo_window`).
- Deux états de fenêtre : **réduit** (pastille/bulle flottante ~64×64) et **déployé** (panneau ~380×640).
- POC = **données simulées** dans un `MockRepository` (fichiers JSON locaux ou objets Dart). Aucun appel réseau réel. Prévoir des **délais artificiels** (300-800 ms) pour simuler la latence des APIs.
- Architecture propre : séparer `models/`, `repositories/` (interface + impl mock), `state/` (Provider ou Riverpod), `ui/`. Le passage au vrai backend (APIs via ESB Booster) doit se limiter à remplacer l'implémentation du repository.
- Thème **Orange** : orange principal `#FF7900`, fond sombre `#000000`/`#1A1A1A`, texte clair, accents blancs. Coins arrondis, ombres douces, animations de transition fluides.

## 3. Comportement global du widget

1. **Mode réduit** : bulle flottante en bas à droite. Affiche un badge de notifications non lues. Clic → déploie le panneau.
2. **Mode déployé** : panneau avec une barre supérieure (logo, statut conseiller, bouton réduire/fermer) et une navigation par onglets en bas.
3. **Screen-pop simulé** : un bouton « Simuler appel entrant » déclenche l'ouverture automatique du panneau sur la fiche d'un client mocké (comme si Genesys/Dimelo poussait un contexte). C'est l'usage phare à démontrer.
4. **Deep-link web (simulé)** : tout bouton « Ouvrir dans HERMES » affiche un toast/snackbar du type `→ Ouverture HERMES web : /client/{id}/vue360` (pas d'ouverture réelle de navigateur nécessaire pour le POC, mais le simuler est un plus).

## 4. Fonctionnalités à implémenter (onglets)

### Onglet A — Recherche
- Champ de recherche : par **numéro**, **Nom prénoms**, **identité** ou **référence contrat**.
- Résultats en liste (nom, n°, segment, type B2B/B2C). Clic → ouvre la **mini Vue 360**.
- Gérer l'état « aucun résultat » et une liste **VIP/blacklist** (numéros non recherchables → message dédié).

### Onglet B — Mini Vue 360 (cœur du widget)
Fiche client compacte, scrollable, organisée en cartes repliables :
- **Identité** : nom/raison sociale, type (B2B/B2C), segment, statut d'identification, photo/initiales, n° principal.
- **Scoring** : qualité payeur, segment valeur, score CSI, NPS, dernier passage en boutique. Afficher sous forme de badges/jauges colorés.
- **Récap consommation** (mock, le plus visuel possible) :
  - Solde **crédit d'appel** (FCFA)
  - Volume **Data** restant / consommé (barre de progression + Go restants, date d'expiration)
  - **SMS** restants
  - **Pass actifs** (liste courte)
  - Mini-graphe de consommation mois M vs M-1
- **Contrats** : liste des contrats actifs avec type (Mobile, Fixe, Internet, Fibre, Orange TV, Orange Money) et statut. Clic sur un contrat → détail compact.
- **Facturation** (si postpayé) : dernière facture (montant, échéance, statut payé/impayé), solde dû.
- **Alerte client récurrent** : si le client a contacté > 1 fois aujourd'hui, afficher un **bandeau clignotant** « Nᵉ contact aujourd'hui ».
- Bouton **« Ouvrir Vue 360 complète dans HERMES »** en bas.

### Onglet C — Assistant IA
- Interface de **chat** intégrée au widget (zone messages + champ de saisie).
- L'assistant a **connaissance du client en cours** (contexte injecté) et peut répondre à : « Résume la situation de ce client », « Quels risques de churn ? », « Quelle offre proposer ? », « Explique sa dernière réclamation ».
- Afficher des **suggestions rapides** (chips cliquables) basées sur les données IA du client : recommandation d'offre, risque de churn, **script adaptatif** (ton suggéré selon profil mécontent/fidèle), geste commercial proposé.
- Pour le POC : réponses **simulées** (réponses pré-écrites contextualisées selon le client mocké + effet de typing). Prévoir une interface `AiAssistantService` facile à brancher plus tard sur une vraie API.

### Onglet D — Mes actions rapides
Boutons d'action filtrés par **profil conseiller** (Call Center / Agence / Superviseur). Pour le POC, chaque action ouvre une **mini-confirmation** (bottom sheet) puis simule l'exécution (loader → succès/échec mocké) :
- **SIM Swap**
- **Remboursement de crédit** (≤ 1000 / ≤ 10000)
- **Réactivation Internet Fibre**
- **Bloquer / Débloquer compte Orange Money**
- **Réinitialiser code secret OM**
- **Envoyer lien application MaxIt** / **paramètres APN** par SMS
- **Suspension / Remise en service du compte**

> Les actions vraiment sensibles affichent « Confirmer dans HERMES » et renvoient au web plutôt que de s'exécuter dans le widget.

### Onglet E — Notifications & file
- **File d'attente** (agence) : nombre de clients en attente + bouton « Client suivant » (simulé).
- **Notifications** : relances SLA arrivant à échéance, cases assignés/transférés, retour en file précédente. Chaque notif est cliquable et ouvre le contexte associé.
- **Statut conseiller** : Disponible / En traitement / Pause (toggle) + déclaration **début/fin de prise en charge**.
- **Chrono DMT** de l'interaction en cours, avec repère visuel à l'approche de 10 min (objectif DMT du projet).

## 5. Modèles de données (mock — à générer)

Génère **3 clients fictifs** variés (1 B2C prépayé, 1 B2C postpayé fibre, 1 B2B) avec données cohérentes. Schéma indicatif :

```dart
class Client {
  String id;
  String type;          // "B2C" | "B2B"
  String nom;
  String numeroPrincipal;
  String segment;       // ex: "Premium", "Mass Market"
  String statutIdentification; // "Valide" | "Non identifié"
  int contactsAujourdhui;      // pour l'alerte récurrence
  Scoring scoring;
  Consommation consommation;
  List<Contrat> contrats;
  Facturation? facturation;    // null si prépayé
  List<Interaction> dernieresInteractions;
  IaInsights ia;
}

class Scoring { String qualitePayeur; String segmentValeur; int csi; int nps; DateTime? dernierPassageBoutique; }

class Consommation {
  int creditFcfa;
  double dataRestanteGo; double dataTotaleGo; DateTime? dataExpiration;
  int smsRestants;
  List<String> passActifs;
  Map<String,double> consoParMois; // {"M-1": .., "M": ..}
}

class Contrat { String id; String service; /* Mobile|Fixe|Internet|Fibre|OrangeTV|OrangeMoney */ String statut; String offre; }

class Facturation { double montantDerniereFacture; DateTime echeance; bool paye; double soldeDu; }

class Interaction { String type; /* Réclamation|Demande|Dérangement|Appel */ DateTime date; String statut; String resume; }

class IaInsights { double risqueChurnPct; String offreRecommandee; String tonSuggere; String gesteCommercial; }
```

## 6. Données IA simulées (exemples à intégrer)

- Risque de churn (%) + libellé (faible/moyen/élevé).
- Offre recommandée basée sur l'usage (ex : « Forfait Data 30 Go — conso en hausse de 40 % »).
- Script adaptatif / ton suggéré (ex : client mécontent → ton empathique).
- Geste commercial proposé (ex : « 2 Go offerts »).

## 7. UX / qualité visuelle attendue

- Compact, lisible, hiérarchie claire ; pas de surcharge. Cartes repliables pour ne montrer l'essentiel que par défaut.
- Transitions animées entre bulle et panneau.
- États gérés partout : chargement (skeletons), vide, erreur (message explicite + retry), backend indisponible (simulé).
- Accessibilité clavier minimale (Échap pour réduire, Entrée pour rechercher).

## 8. Hors périmètre du POC (à ne PAS faire)

- Pas de vraie connexion AD/SSO, pas de double authentification (mocker un conseiller connecté).
- Pas de vrais appels ESB Booster / APIs Datamart.
- Pas de traitement complet de case ni de gros formulaires (ceux-ci renvoient au web).
- Pas de persistance distante ; un état en mémoire suffit pour la démo.

## 9. Livrable attendu

- Un projet Flutter Desktop **qui compile et se lance**, fenêtre ancrée en bas à droite.
- Navigation complète entre les 5 onglets + bulle réduite + screen-pop simulé.
- Au moins **les 3 clients mockés** parcourables et l'assistant IA contextuel fonctionnel (réponses simulées).
- Code commenté aux endroits où brancher le vrai backend (repositories, services).
- Un court `README` expliquant comment lancer le POC.

---

### Note de démo
Mets en avant le **scénario phare** : « appel entrant → screen-pop → mini Vue 360 → l'assistant IA suggère une offre → action rapide (remboursement crédit) → bouton vers HERMES web ». C'est ce parcours qui illustre le gain de DMT (15 → 10 min).
