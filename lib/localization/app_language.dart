import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  static const supportedLocales = [Locale('de'), Locale('en')];
  static const _preferenceKey = 'app.language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isGerman => _locale.languageCode == 'de';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_preferenceKey);
    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final resolvedCode = savedCode ?? deviceCode;
    await setLocaleCode(resolvedCode, persist: false);
  }

  Future<void> setLocaleCode(String code, {bool persist = true}) async {
    final normalizedCode = code.toLowerCase();
    final nextLocale = normalizedCode == 'de'
        ? const Locale('de')
        : const Locale('en');
    final changed = nextLocale != _locale;
    _locale = nextLocale;
    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, _locale.languageCode);
    }
    if (changed) notifyListeners();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required AppLanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLanguageController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope not found in context');
    return scope!.notifier!;
  }
}

extension AppLanguageContext on BuildContext {
  AppLanguageController get languageController =>
      AppLanguageScope.controllerOf(this);

  bool get isGerman => languageController.isGerman;

  String tr(String de, String en) => isGerman ? de : en;
}
