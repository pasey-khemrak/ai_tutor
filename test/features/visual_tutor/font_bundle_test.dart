import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/visual_tutor_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production bundle contains Latin, Khmer, and math fallback fonts',
    () async {
      for (final asset in <String>[
        'assets/fonts/NotoSans-Regular.ttf',
        'assets/fonts/NotoSansKhmer-Regular.ttf',
        'assets/fonts/NotoSansMath-Regular.ttf',
      ]) {
        final bytes = await rootBundle.load(asset);
        expect(bytes.lengthInBytes, greaterThan(1000), reason: asset);
      }

      expect(
        AppTheme.fontFallback,
        containsAll(<String>['Noto Sans', 'Noto Sans Khmer', 'Noto Sans Math']),
      );
      expect(
        VisualTutorTypography.fontFallback,
        containsAll(<String>['Noto Sans', 'Noto Sans Khmer', 'Noto Sans Math']),
      );
    },
  );
}
