# Hermes Widget — POC Compagnon

Widget de bureau Flutter (Windows) pour les conseillers Orange Côte d'Ivoire,
en complément de l'application web **HERMES** (Vue 360 client).

> **POC sans backend réel.** Toutes les données et l'IA sont mockées avec une
> latence simulée (300–800 ms). Le widget est conçu pour qu'un branchement
> backend se limite à remplacer les implémentations dans `lib/core/services.dart`.

---

## 1. Lancer le POC

Prérequis : Flutter 3.38+, Visual Studio 2022 avec la charge *« Desktop
development with C++ »* (Windows).

```bash
flutter pub get
flutter run -d windows
```

Le widget s'affiche **en bas à droite de l'écran**, sans barre de titre,
**toujours au-dessus** des autres fenêtres. Il se relance automatiquement
au démarrage de Windows (via `launch_at_startup`).

---

## 2. Comportement de la fenêtre

| Mode | Taille | Action pour y aller |
|------|--------|--------------------|
| **Panneau** (par défaut) | 390 × 640 | Clic sur la bulle |
| **Bulle** | 72 × 72 (badge notifs) | Bouton ➖ dans le header |
| **Masqué** | – | Bouton ✕ dans le header (l'app reste dans le tray) |

**Tray** (icône en bas à droite de l'écran) :
clic gauche = afficher/cacher · clic droit = menu (Afficher · Masquer ·
Simuler appel entrant · Quitter).

---

## 3. Scénario phare — « Screen-pop & gain DMT »

C'est **le parcours à dérouler en présentation**. Il illustre le gain
**DMT 15 → 10 min** visé par le projet.

1. Cliquer **📞 Simuler appel entrant** (header du panneau *ou* menu tray).
   → Overlay « appel entrant » avec ondes pulsantes, infos client, **Décrocher**.
2. **Décrocher** →
   - statut conseiller bascule sur **En traitement** (puce orange dans le header)
   - le **chrono DMT démarre** (00:00 → cible 10:00)
   - la **Mini Vue 360** du client s'ouvre automatiquement.
3. Sur la Vue 360 (selon le client tiré) :
   - bandeau rouge clignotant *« Nᵉ contact aujourd'hui »* si récurrent,
   - barres de **scoring** (CSI / NPS) + badges Payeur / Valeur,
   - **consommation** avec barre data colorée par seuil + mini-graphe M-1 vs M,
   - **contrats** repliables, **facturation** si postpayé.
4. Onglet **IA** (la nav reste visible) → contexte client auto, cliquer la chip
   **« Résume la situation »** → réponse contextuelle en **streaming mot à mot**.
   Puis *« Quelle offre proposer ? »* → recommandation issue de `IaInsights`.
5. Onglet **Actions** → *Remboursement crédit (≤ 1 000)* → bottom sheet de
   confirmation → loader → ✓ vert (~85 % succès, sinon rouge + *Réessayer*).
6. Retour Vue 360 → bouton **« Ouvrir Vue 360 complète dans HERMES »**
   → snackbar deep-link `→ Ouverture HERMES web : /client/CLI-001/vue360`.
7. Onglet **Notifs** → **Fin prise en charge** → chrono stoppe, statut repasse
   *Disponible*.

---

## 4. Tour rapide des 4 onglets

### A — Recherche (`SearchTab`)
- Saisie debouncée 300 ms. Cherche par **numéro**, **nom**, **id client**,
  **réf contrat**.
- Cas démo : `koua`, `traore`, `elephant`, `0707123456`, `CTR-FIB-90041`,
  `0799999999` (🔴 blacklist), `0111111111` (🟠 VIP protégé), `xyz`
  (« aucun résultat »).
- Clic sur un résultat → **Vue 360** (prend la place de l'onglet Recherche
  tant que le client est sélectionné — la nav reste visible).

### B — Mini Vue 360 (`Vue360Tab`)
Cartes repliables : Identité, Scoring, Consommation, Contrats, Facturation
(si postpayé). Bandeau récurrence en haut. Bouton sticky « Ouvrir HERMES »
en bas (snackbar deep-link).

### C — Assistant IA (`AiTab`)
Chat contextuel. **Suggestions chips** : résumé, churn, offre, dernière
interaction, ton, geste commercial + une chip dynamique avec
`client.ia.offreRecommandee`. Réponses pré-écrites **streamées
mot à mot** (effet typing). Changer de client réinitialise la conversation.

### D — Actions rapides (`ActionsTab`)
Liste filtrée selon `mockConseiller.profil` (Call Center par défaut ;
passer en `superviseur` débloque les remboursements 10k, débloquer OM,
suspendre/remettre en service).
Actions **sensibles** → bouton *« Confirmer dans HERMES »* (deep-link)
au lieu de l'exécution locale.

### E — Notifications & file (`NotificationsTab`)
- **Statut conseiller** : toggle 3 segments (Disponible / En traitement / Pause).
- **Chrono DMT** : `mm:ss` qui tick à la seconde, barre verte → orange (8 min)
  → rouge (10 min).
- **File d'attente** : compteur + bouton *Client suivant* (pioche un mock,
  démarre la prise en charge, ouvre la Vue 360).
- **Liste de notifs** : SLA / case assigné / transféré / retour file. Clic
  → sélectionne le client lié et ouvre la Vue 360.

---

## 5. Jeux de données démo (`lib/mock/mock_data.dart`)

| ID | Client | Profil | Points d'intérêt |
|----|--------|--------|------------------|
| CLI-001 | Kouadio ASSI | B2C prépayé, Mass Market | 3ᵉ contact du jour, data quasi épuisée, OrangeMoney |
| CLI-002 | Mariam TRAORÉ | B2C postpayé Premium VIP | Fibre 500 Mbps + Mobile + TV, facture impayée 45 000 FCFA |
| CLI-003 | SCI ELEPHANT BTP | B2B PME | Fibre Pro 1 Gbps + flotte 20 lignes, 1 contrat suspendu |

Numéros restreints démo : `0799999999` (blacklist) · `0111111111` (VIP protégé).

3 notifications mockées (SLA / case assigné / retour file) + 7 clients
fictifs en file d'attente.

---

## 6. Architecture & points d'extension

```
lib/
├── core/                       ← état applicatif & services partagés
│   ├── client_selection.dart   ← ValueNotifier<Client?> (sélection courante)
│   ├── conseiller_state.dart   ← statut + chrono DMT
│   ├── panel_nav.dart          ← index d'onglet observable
│   ├── window_controller.dart  ← bascule bulle / panneau
│   ├── screen_pop.dart         ← orchestrateur appel entrant
│   ├── services.dart           ← * point d'injection
│   └── helpers.dart, formatters.dart, theme/
├── models/                     ← Client, Scoring, Conso, Contrat, IaInsights…
├── repositories/
│   ├── client_repository.dart  ← interface
│   └── mock_client_repository.dart
├── services/
│   └── ai_assistant_service.dart  ← interface + mock streaming
├── mock/                       ← mock_data.dart, mock_actions.dart
├── widgets/                    ← panel_view, bubble_view, incoming_call_dialog
└── page/
    ├── home_page.dart          ← bascule bulle ↔ panneau, listeners tray
    └── tabs/                   ← search, vue360, ai, actions, notifications
```

**Brancher le vrai backend** se résume à éditer `lib/core/services.dart` :

```dart
class AppServices {
  static final ClientRepository  clientRepository  = HermesClientRepository(...); // ESB Booster
  static final AiAssistantService aiAssistantService = AnthropicAiService(...);    // ou LLM interne
}
```

Tous les onglets passent par `AppServices` — aucune autre modification
n'est requise dans l'UI.

---

## 7. Charte visuelle

Palette `lib/core/theme/app_colors.dart` :
- **Primary** Orange `#FF7900`
- Fond `#1A1A1A`, surface `#242424`
- Accents fonctionnels : success `#32C832` · warning `#FFB400` ·
  danger `#CD3C14` · info `#4BB4E6`

Coins arrondis 10–16 px, ombres douces, transitions 180–250 ms,
typographie compacte (10–13 px) pour densité d'information.

---

## 8. Hors périmètre du POC (rappel)

Pas de SSO/AD, pas d'appels ESB Booster réels, pas de traitement complet
de case, pas de persistance distante. Les actions sensibles renvoient au
web HERMES via deep-link simulé (snackbar).
