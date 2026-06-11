import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hermes_widget/page/home_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/helpers.dart';
import 'core/theme/app_colors.dart';
import 'core/window_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Lancement au démarrage (best-effort)
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
    if (!await launchAtStartup.isEnabled()) {
      await launchAtStartup.enable();
    }
  } catch (e) {
    debugPrint('launch_at_startup indisponible: $e');
  }

  // Démarre en mode panneau
  final windowOptions = WindowOptions(
    size: HermesWindow.panelSize,
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPreventClose(true);
    await Helpers.positionWindowBottomRight();
    await windowManager.show();
    await windowManager.focus();
  });

  await Helpers.initSystemTray();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.dark,
    );
    return MaterialApp(
      title: 'Hermes Widget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme().apply(
          bodyColor: AppColors.textLight,
          displayColor: AppColors.textLight,
        ),
      ),
      home: const HomePage(),
    );
  }
}
