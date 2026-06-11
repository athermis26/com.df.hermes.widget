import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/window_controller.dart';
import '../mock/mock_data.dart';
import 'hi.dart';

class BubbleView extends StatelessWidget {
  const BubbleView({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = mockNotifications.where((n) => !n.lue).length;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onTap: () => HermesWindow.instance.toPanel(),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Hi(AppIcons.agent, color: Colors.white, size: 28),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.dark, width: 2),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
