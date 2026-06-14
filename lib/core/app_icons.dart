import 'package:hugeicons/hugeicons.dart';

/// Alias du type d'icône HugeIcons (un graphe SVG sérialisé).
typedef AppIcon = List<List<dynamic>>;

/// Registre central — toutes les icônes du widget passent par ici.
/// Pour changer un visuel, on ne touche qu'à ce fichier.
class AppIcons {
  AppIcons._();

  // ── Header / navigation / fenêtre ───────────────────────────
  static const AppIcon agent = HugeIcons.strokeRoundedCustomerService;
  static const AppIcon callIncoming = HugeIcons.strokeRoundedCallIncoming01;
  static const AppIcon minimize = HugeIcons.strokeRoundedMinusSign;
  static const AppIcon close = HugeIcons.strokeRoundedCancel01;
  static const AppIcon back = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIcon chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const AppIcon chevronDown = HugeIcons.strokeRoundedArrowDown01;
  static const AppIcon chevronUp = HugeIcons.strokeRoundedArrowUp01;

  // ── Onglets ─────────────────────────────────────────────────
  static const AppIcon tabSearch = HugeIcons.strokeRoundedSearch01;
  static const AppIcon tabAi = HugeIcons.strokeRoundedSparkles;
  static const AppIcon tabActions = HugeIcons.strokeRoundedEnergy;
  static const AppIcon tabNotifs = HugeIcons.strokeRoundedNotification03;

  // ── Recherche ───────────────────────────────────────────────
  static const AppIcon phone = HugeIcons.strokeRoundedCall02;
  static const AppIcon user = HugeIcons.strokeRoundedUserCircle;
  static const AppIcon idCard = HugeIcons.strokeRoundedAddressBook;
  static const AppIcon contract = HugeIcons.strokeRoundedDocumentAttachment;
  static const AppIcon searchOff = HugeIcons.strokeRoundedSearchRemove;
  static const AppIcon block = HugeIcons.strokeRoundedBlocked;
  static const AppIcon shieldVip = HugeIcons.strokeRoundedShield01;

  // ── Vue 360 ─────────────────────────────────────────────────
  static const AppIcon alertRecurrence = HugeIcons.strokeRoundedAlert02;
  static const AppIcon identity = HugeIcons.strokeRoundedUserCircle;
  static const AppIcon scoring = HugeIcons.strokeRoundedChartLineData01;
  static const AppIcon consumption = HugeIcons.strokeRoundedSignalFull02;
  static const AppIcon contracts = HugeIcons.strokeRoundedFiles01;
  static const AppIcon billing = HugeIcons.strokeRoundedReceiptText;
  static const AppIcon smartphone = HugeIcons.strokeRoundedSmartPhone01;
  static const AppIcon landline = HugeIcons.strokeRoundedCall;
  static const AppIcon wifi = HugeIcons.strokeRoundedWifi01;
  static const AppIcon tv = HugeIcons.strokeRoundedTv01;
  static const AppIcon wallet = HugeIcons.strokeRoundedWallet01;
  static const AppIcon openExternal = HugeIcons.strokeRoundedLinkSquare01;

  // ── Assistant IA ────────────────────────────────────────────
  static const AppIcon sparkle = HugeIcons.strokeRoundedSparkles;
  static const AppIcon info = HugeIcons.strokeRoundedInformationCircle;
  static const AppIcon summarize = HugeIcons.strokeRoundedFileChartColumn;
  static const AppIcon churn = HugeIcons.strokeRoundedChartDown;
  static const AppIcon offer = HugeIcons.strokeRoundedTag01;
  static const AppIcon history = HugeIcons.strokeRoundedClock01;
  static const AppIcon voice = HugeIcons.strokeRoundedVoice;
  static const AppIcon gift = HugeIcons.strokeRoundedGift;
  static const AppIcon send = HugeIcons.strokeRoundedSent;

  // ── Actions rapides ─────────────────────────────────────────
  static const AppIcon sim = HugeIcons.strokeRoundedSimcard01;
  static const AppIcon coins = HugeIcons.strokeRoundedCoins01;
  static const AppIcon walletAction = HugeIcons.strokeRoundedMoneyBag01;
  static const AppIcon lock = HugeIcons.strokeRoundedLock;
  static const AppIcon unlock = HugeIcons.strokeRoundedSquareUnlock01;
  static const AppIcon password = HugeIcons.strokeRoundedLockPassword;
  static const AppIcon sendToMobile = HugeIcons.strokeRoundedSendToMobile;
  static const AppIcon antenna = HugeIcons.strokeRoundedAntenna;
  static const AppIcon power = HugeIcons.strokeRoundedPower;
  static const AppIcon disturb = HugeIcons.strokeRoundedShieldBan;
  static const AppIcon refresh = HugeIcons.strokeRoundedRefresh;
  static const AppIcon checkCircle = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIcon errorCircle = HugeIcons.strokeRoundedAlertCircle;
  static const AppIcon profilBadge = HugeIcons.strokeRoundedUserStar01;
  static const AppIcon noUser = HugeIcons.strokeRoundedUserCircle;
  static const AppIcon userOk = HugeIcons.strokeRoundedUserCircle02;

  // ── Notifs / file / chrono ──────────────────────────────────
  static const AppIcon sla = HugeIcons.strokeRoundedTimer01;
  static const AppIcon assigned = HugeIcons.strokeRoundedUserStar01;
  static const AppIcon transferred = HugeIcons.strokeRoundedSquareArrowLeftRight;
  static const AppIcon retour = HugeIcons.strokeRoundedReplay;
  static const AppIcon dmt = HugeIcons.strokeRoundedClock01;
  static const AppIcon queue = HugeIcons.strokeRoundedUserMultiple;
  static const AppIcon next = HugeIcons.strokeRoundedNext;
  static const AppIcon play = HugeIcons.strokeRoundedPlay;
  static const AppIcon stop = HugeIcons.strokeRoundedStop;
  static const AppIcon allGood = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIcon statusOk = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIcon statusBusy = HugeIcons.strokeRoundedHeadsetConnected;
  static const AppIcon statusPause = HugeIcons.strokeRoundedPauseCircle;

  // ── Appel entrant ───────────────────────────────────────────
  static const AppIcon callAccept = HugeIcons.strokeRoundedCall;
  static const AppIcon callReject = HugeIcons.strokeRoundedCallEnd01;

  // ── Broadcast ───────────────────────────────────────────────
  static const AppIcon megaphone = HugeIcons.strokeRoundedMegaphone02;

  // ── Menus / actions globales ────────────────────────────────
  static const AppIcon moreVertical = HugeIcons.strokeRoundedMoreVertical;
  static const AppIcon logout = HugeIcons.strokeRoundedLogout03;
  static const AppIcon switchUser = HugeIcons.strokeRoundedExchange01;
  static const AppIcon createCase = HugeIcons.strokeRoundedFilePlus;
  static const AppIcon themeDark = HugeIcons.strokeRoundedMoon02;
  static const AppIcon themeLight = HugeIcons.strokeRoundedSun02;

  // ── Sources Digital / canaux ─────────────────────────────────
  static const AppIcon sourcePhone = HugeIcons.strokeRoundedCall02;
  static const AppIcon sourceEmail = HugeIcons.strokeRoundedMail01;
  static const AppIcon sourceWhatsapp = HugeIcons.strokeRoundedWhatsapp;
  static const AppIcon sourceFacebook = HugeIcons.strokeRoundedFacebook01;
  static const AppIcon sourceTwitter = HugeIcons.strokeRoundedTwitter;
  static const AppIcon sourceAccueil = HugeIcons.strokeRoundedBuilding01;
}
