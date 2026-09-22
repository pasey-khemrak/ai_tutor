import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_theme_controller.dart';
import '../core/config/app_config.dart';
import '../core/localization/app_language_controller.dart';
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
        return ValueListenableBuilder<Locale>(
          valueListenable: AppLanguageController.currentLocale,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: AppLocalizations(locale).appName,
              themeMode: themeMode,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: routeGuard.resolveInitialRoute(),
              onGenerateRoute: (settings) {
                return AppRoutes.onGenerateRoute(settings, guard: routeGuard);
              },
            );
          },
        );
      },
    );
  }
}
