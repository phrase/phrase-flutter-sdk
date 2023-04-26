import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:synchronized/synchronized.dart';

import 'phrase_api.dart';
import 'phrase_arb.dart';
import 'phrase_chef.dart';
import 'phrase_diskcache.dart';
import 'phrase_prefs.dart';

const String _kSdkVersion = "1.0.5"; //must match version in pubspec.yaml

final RegExp _kSemverRegexp = RegExp(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[a-zA-Z\d][-a-zA-Z.\d]*)?(\+[a-zA-Z\d][-a-zA-Z.\d]*)?$");
bool verifySemver(String ver) => _kSemverRegexp.hasMatch(ver);

class PhraseImpl {
  PhraseImpl(
    this._distribution,
    this._environment,
    this._checkForUpdates,
    this._customAppVersion,
    this._host,
  );

  final String _distribution;
  final String _environment;
  final bool _checkForUpdates;
  final String? _customAppVersion;
  final PhraseHost _host;

  final PhraseDiskCache _disk = PhraseDiskCache();
  final PhrasePrefs _prefs = PhrasePrefs();
  final PhraseApi _api = PhraseApi();
  final PhraseChef _chef = PhraseChef();
  final Map<String, AppResourceBundle> _map = <String, AppResourceBundle>{};
  final Lock _lockApi = Lock();

  static String _hash(String s) => sha512.convert(utf8.encode(s)).toString();
  static String _localeHash(
    String distribution,
    String environment,
    String locale,
  ) =>
      _hash("$distribution-$environment-$locale");

  void onLocale(Locale locale) async {
    _map.clear();
    String localeCode = Intl.canonicalizedLocale(locale.toString());
    bool hasCache = await _loadCache(localeCode);
    if (_checkForUpdates) loadFromApi(localeCode, hasCache);
  }

  Future<bool> _loadCache(String localeCode) async {
    String fn = _localeHash(_distribution, _environment, localeCode);
    try {
      String? contents = await _disk.read(fn);
      if (contents != null) {
        AppResourceBundle arb = AppResourceBundle.parse(contents);
        _map[localeCode] = arb;
        phraseLog("Loaded cache for `$localeCode`");
        return true;
      } else {
        phraseLog("Cache for `$localeCode` not found");
      }
    } catch (e) {
      phraseLog("_loadCache failed with $e");
    }
    return false;
  }

  Future<void> loadFromApi(String localeCode, bool hasCache) =>
      _lockApi.synchronized(() async {
        String localeHash =
            _localeHash(_distribution, _environment, localeCode);
        String uuid = await _prefs.getUUID();
        String? sdkVersion = _kSdkVersion;
        String? lastUpdate = await _prefs.getLastUpdate();
        String? currentVersion =
            hasCache ? await _prefs.getVersion(localeHash) : null;
        String? appVersion = _customAppVersion ?? await _getAppVersion();
        try {
          PhraseApiResult response = await _api.getTranslations(
            _distribution,
            _environment,
            _host,
            localeCode,
            uuid,
            sdkVersion,
            lastUpdate,
            currentVersion,
            appVersion,
          );
          if (response is PhraseApiResultSuccess) {
            AppResourceBundle arb = AppResourceBundle.parse(response.arb);
            _map[localeCode] = arb;
            await _disk.write(localeHash, response.arb);
            await _prefs.setLastUpdate();
            await _prefs.setVersion(localeHash, response.version);
            phraseLog("OTA update for `$localeCode`: OK");
          } else if (response is PhraseApiResultNotModified) {
            phraseLog("OTA update for `$localeCode`: NOT MODIFIED");
          }
        } catch (e) {
          phraseLog("OTA update for `$localeCode`: ERROR: $e");
        }
      });

  Future<String?> _getAppVersion() async {
    try {
      String version = (await PackageInfo.fromPlatform()).version;
      if (!verifySemver(version)) {
        phraseLog(
            "WARNING: App version doesn't comply with semver specification: `$version`");
        return null;
      }
      return version;
    } catch (e) {
      return null;
    }
  }

  String? getText(
    String locale,
    String key, [
    Map<String, dynamic> args = const {},
  ]) {
    try {
      final arb = _map[locale];
      if (arb == null) {
        return null;
      } else {
        return _chef.cook(locale, arb, key, args);
      }
    } catch (e) {
      return null;
    }
  }
}

void phraseLog(String s) {
  if (kDebugMode) debugPrint("PHRASE OTA: $s");
}
