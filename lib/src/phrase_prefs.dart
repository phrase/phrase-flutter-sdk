import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PhrasePrefs {
  static const String _kKeyUuid = "phrase_uuid";
  static const String _kKeyLastUpdate = "phrase_last_update";
  String _keyTranslationVer(String localeHash) => "phrase_version_$localeHash";

  Future<String?> _get(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _put(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String> getUUID() async {
    String? uuid = await _get(_kKeyUuid);
    if (uuid != null) return uuid;
    uuid = const Uuid().v4();
    await _put(_kKeyUuid, uuid);
    return uuid;
  }

  Future<String?> getLastUpdate() => _get(_kKeyLastUpdate);
  Future<void> setLastUpdate() => _put(_kKeyLastUpdate,
      (DateTime.now().millisecondsSinceEpoch / 1000).round().toString());
  Future<String?> getVersion(String localeHash) =>
      _get(_keyTranslationVer(localeHash));
  Future<void> setVersion(String localeHash, String version) =>
      _put(_keyTranslationVer(localeHash), version);
}
