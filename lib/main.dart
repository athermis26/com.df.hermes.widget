import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hermes_widget/page/home_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/helpers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_controller.dart';
import 'core/window_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Applique la palette en fonction du mode initial (sombre par défaut).
  ThemeController.instance.apply();

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
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, isDark, _) {
        final brightness = isDark ? Brightness.dark : Brightness.light;
        final scheme = ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          surface: P.bg,
        );
        return MaterialApp(
          // Key liée au mode → force la reconstruction complète à chaque
          // toggle, garantit la lecture des nouvelles valeurs de P.
          key: ValueKey('theme-${isDark ? 'dark' : 'light'}'),
          title: 'Hermes Widget',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: brightness,
            colorScheme: scheme,
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: TextTheme().apply(
              bodyColor: P.text,
              displayColor: P.text,
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
