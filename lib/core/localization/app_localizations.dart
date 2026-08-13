import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('km')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String get appName => locale.languageCode == 'km' ? 'Rean AI' : 'Rean AI';
  String get loading =>
      locale.languageCode == 'km' ? 'កំពុងផ្ទុក...' : 'Loading...';
  String get retry => locale.languageCode == 'km' ? 'សាកល្បងម្តងទៀត' : 'Retry';
  String get emptyStateTitle =>
      locale.languageCode == 'km' ? 'មិនទាន់មានទិន្នន័យ' : 'Nothing here yet';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
