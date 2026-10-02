import 'package:flutter/material.dart';

import '../core/localization/app_language_controller.dart';
import '../features/visual_tutor/presentation/visual_tutor_design.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageController.currentLocale,
      builder: (context, locale, _) {
        final isKhmer = locale.languageCode == 'km';
        return Semantics(
          button: true,
          label: isKhmer ? 'ប្តូរទៅភាសាអង់គ្លេស' : 'Switch to Khmer',
          child: InkWell(
            key: const Key('language-switcher-button'),
            onTap: AppLanguageController.toggleLanguage,
            borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: VisualTutorColors.shellElevated,
                borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
                border: Border.all(
                  color: VisualTutorColors.cyan.withValues(alpha: .35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 15,
                    color: VisualTutorColors.cyan,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isKhmer ? 'ខ្មែរ' : 'EN',
                    style: const TextStyle(
                      color: VisualTutorColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamilyFallback: VisualTutorTypography.fontFallback,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
