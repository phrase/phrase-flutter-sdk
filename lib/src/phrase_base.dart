import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrase/src/phrase_api.dart';
import 'phrase_impl.dart';

export 'phrase_api.dart' show PhraseHost;

class Phrase {
  static PhraseImpl? _impl;

  static void setup(
    String distribution,
    String environment, {
    bool checkForUpdates = true,
    String? customAppVersion,
    PhraseHost host = PhraseHost.eu,
  }) {
    if (distribution.isEmpty || environment.isEmpty) {
      phraseLog("Distribution and environment can't be empty");
    }
    if (customAppVersion != null && !verifySemver(customAppVersion)) {
      phraseLog(
          "WARNING: Provided customAppVersion doesn't comply with semver specification: `$customAppVersion`");
      customAppVersion = null;
    }
    _impl = PhraseImpl(
      distribution,
      environment,
      checkForUpdates,
      customAppVersion,
      host,
    );
  }

  static void onLocale(Locale locale) async => _impl?.onLocale(locale);

  static Future<void> updateTranslations(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    String localeCode = Intl.canonicalizedLocale(currentLocale.toString());
    return _impl?.loadFromApi(localeCode, true) ?? Future.value();
  }

  static String? getText(
    String locale,
    String key, [
    Map<String, dynamic> args = const {},
  ]) =>
      _impl?.getText(locale, key, args);
}
