import 'package:flutter/material.dart';

import '../core/app_theme_controller.dart';
import '../core/config/app_config.dart';
import '../core/localization/app_localizations.dart';
import '../core/routing/app_routes.dart';
import '../core/routing/auth_route_guard.dart';
import '../core/theme/app_theme.dart';

class AiTutorApp extends StatelessWidget {
  const AiTutorApp({super.key, this.config});

  final AppConfig? config;

  @override
  Widget build(BuildContext context) {
    final resolvedConfig = config ?? AppConfig.current;
    final routeGuard = AuthRouteGuard(
      config: resolvedConfig,
      session: appAuthSession,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppLocalizations(const Locale('en')).appName,
          themeMode: themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          initialRoute: routeGuard.resolveInitialRoute(),
          onGenerateRoute: (settings) {
            return AppRoutes.onGenerateRoute(settings, guard: routeGuard);
          },
        );
      },
    );
  }
}
