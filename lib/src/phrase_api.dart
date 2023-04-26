import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'phrase_exceptions.dart';

const _kEuBaseUrl = 'ota.phraseapp.com';
const _kUsBaseUrl = 'ota.us.app.phrase.com';

enum PhraseHost { eu, us }

class PhraseApiResult {
  PhraseApiResult._();
  factory PhraseApiResult.success(String version, String arb) =
      PhraseApiResultSuccess;
  factory PhraseApiResult.notModified() = PhraseApiResultNotModified;
}

class PhraseApiResultSuccess extends PhraseApiResult {
  PhraseApiResultSuccess(this.version, this.arb) : super._();
  final String version;
  final String arb;
}

class PhraseApiResultNotModified extends PhraseApiResult {
  PhraseApiResultNotModified() : super._();
}

class PhraseApi {
  String _getBaseUrlForHost(PhraseHost host) {
    switch (host) {
      case PhraseHost.eu:
        return _kEuBaseUrl;
      case PhraseHost.us:
        return _kUsBaseUrl;
    }
  }

  Future<StreamedResponse> _get(Uri uri) {
    Request req = Request("GET", uri)..followRedirects = false;
    Client baseClient = Client();
    return baseClient.send(req);
  }

  Future<PhraseApiResult> getTranslations(
    String distribution,
    String environment,
    PhraseHost host,
    String locale,
    String uuid,
    String? sdkVersion,
    String? lastUpdate,
    String? currentVersion,
    String? appVersion,
  ) async {
    Map<String, dynamic> params = <String, dynamic>{};
    params['client'] = 'flutter';
    params['sdk_version'] = sdkVersion;
    params['unique_identifier'] = uuid;
    if (lastUpdate != null) params['last_update'] = lastUpdate;
    if (currentVersion != null) params['current_version'] = currentVersion;
    if (appVersion != null) params['app_version'] = appVersion;

    var uri = Uri.https(
      _getBaseUrlForHost(host),
      '/$distribution/$environment/$locale/arb',
      params,
    );
    if (kDebugMode) debugPrint('OTA Request URL: $uri');

    String? version;
    while (true) {
      StreamedResponse response = await _get(uri);
      int code = response.statusCode;
      if (code == 304) {
        return PhraseApiResult.notModified();
      } else if (code >= 300 && code <= 399) {
        uri = Uri.parse(response.headers['location']!);
        version = uri.queryParameters['version'];
        continue;
      } else if (code == 200) {
        if (version == null) throw PhraseApiException("Missing version");
        var arb = await response.stream.bytesToString(utf8);
        return PhraseApiResult.success(version, arb);
      } else {
        throw PhraseApiException("Unexpected response code: $code");
      }
    }
  }
}
