import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/app_icons.dart';
import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../mock/mock_data.dart';
import '../models/conseiller.dart';
import '../widgets/hi.dart';

/// Écran affiché tant qu'aucun conseiller n'est connecté.
/// Propose les 3 profils mock (Call Center, Agence, Digital).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark,
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Bonjour',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Qui êtes-vous aujourd\'hui ?',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: mockConseillers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ProfilCard(conseiller: mockConseillers[i]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'POC – sans authentification réelle',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Row(
          children: [
            const Hi(AppIcons.agent, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'HERMES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            InkWell(
              onTap: () => windowManager.hide(),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Hi(AppIcons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilCard extends StatelessWidget {
  final Conseiller conseiller;
  const _ProfilCard({required this.conseiller});

  ({AppIcon icon, Color color, String label, String desc}) _meta() {
    switch (conseiller.profil) {
      case ProfilConseiller.callCenter:
        return (
          icon: AppIcons.statusBusy,
          color: AppColors.primary,
          label: 'Conseiller Call Center',
          desc: 'Vous prenez les appels entrants.',
        );
      case ProfilConseiller.agence:
        return (
          icon: AppIcons.queue,
          color: AppColors.info,
          label: 'Conseiller Agence',
          desc: 'Vous accueillez les clients en agence.',
        );
      case ProfilConseiller.digital:
        return (
          icon: AppIcons.tabAi,
          color: AppColors.success,
          label: 'Conseiller Digital',
          desc: 'Vous traitez les emails et réseaux sociaux.',
        );
      case ProfilConseiller.superviseur:
        return (
          icon: AppIcons.profilBadge,
          color: AppColors.warning,
          label: 'Superviseur',
          desc: 'Vous supervisez l\'équipe.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta();
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Session.instance.login(conseiller),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Hi(m.icon, color: m.color, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.desc,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${conseiller.nom} · ${conseiller.agence}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: m.color, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Hi(AppIcons.chevronRight, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
