import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/conseiller.dart';
import '../models/quick_action.dart';

/// Catalogue des actions rapides du POC.
/// Le filtrage par profil conseiller est fait à l'affichage.
final List<QuickAction> mockActions = [
  QuickAction(
    id: 'sim_swap',
    label: 'Changer la SIM',
    description: 'Remplace la carte SIM de la ligne en quelques secondes.',
    icon: AppIcons.sim,
    color: AppColors.info,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'remb_credit_1k',
    label: 'Recréditer (jusqu\'à 1 000 FCFA)',
    description: 'Un petit geste pour le client – sans validation superviseur.',
    icon: AppIcons.coins,
    color: AppColors.success,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'remb_credit_10k',
    label: 'Recréditer (jusqu\'à 10 000 FCFA)',
    description: 'Pour un geste plus important – validation superviseur requise.',
    icon: AppIcons.walletAction,
    color: AppColors.success,
    allowedProfils: [ProfilConseiller.superviseur],
  ),
  QuickAction(
    id: 'reactiv_fibre',
    label: 'Réactiver la Fibre',
    description: 'Relance le service après une coupure ou un impayé régularisé.',
    icon: AppIcons.wifi,
    color: AppColors.primary,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'bloquer_om',
    label: 'Bloquer le compte Orange Money',
    description: 'Suspend l\'OM en cas de fraude, perte ou demande client.',
    icon: AppIcons.lock,
    color: AppColors.danger,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'debloquer_om',
    label: 'Débloquer le compte Orange Money',
    description: 'Lève la suspension du compte OM.',
    icon: AppIcons.unlock,
    color: AppColors.success,
    allowedProfils: [ProfilConseiller.agence, ProfilConseiller.superviseur],
  ),
  QuickAction(
    id: 'reinit_code_om',
    label: 'Réinitialiser le code OM',
    description: 'Génère un nouveau code secret Orange Money pour le client.',
    icon: AppIcons.password,
    color: AppColors.info,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'sms_maxit',
    label: 'Envoyer MaxIt par SMS',
    description: 'Le lien de téléchargement arrive directement sur son téléphone.',
    icon: AppIcons.sendToMobile,
    color: AppColors.primary,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'sms_apn',
    label: 'Envoyer les paramètres APN',
    description: 'Configuration internet auto-installable, par SMS.',
    icon: AppIcons.antenna,
    color: AppColors.primary,
    allowedProfils: ProfilConseiller.values,
  ),
  QuickAction(
    id: 'suspendre_compte',
    label: 'Suspendre le compte',
    description: 'Action sensible – on continue sur HERMES web.',
    icon: AppIcons.disturb,
    color: AppColors.danger,
    allowedProfils: [ProfilConseiller.superviseur],
    sensitive: true,
    hermesPath: '/client/{id}/actions/suspendre',
  ),
  QuickAction(
    id: 'remise_service',
    label: 'Remettre le compte en service',
    description: 'Action sensible – on continue sur HERMES web.',
    icon: AppIcons.power,
    color: AppColors.warning,
    allowedProfils: [ProfilConseiller.superviseur],
    sensitive: true,
    hermesPath: '/client/{id}/actions/remettre-en-service',
  ),
];
