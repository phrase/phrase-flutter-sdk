import 'package:intl/intl.dart' as intl;

import 'phrase_arb.dart';

class PhraseChef {
  //throws exceptions
  String? cook(
    String locale,
    AppResourceBundle arb,
    String key, [
    Map<String, dynamic> args = const {},
  ]) {
    final message = Message(arb.resources, key, false);
    if (message.isPlural) {
      return _cookPlural(locale, message, args);
    } else if (message.placeholders.isNotEmpty) {
      return _cookPlaceholders(locale, message, message.value, args);
    } else {
      return message.value;
    }
  }

  String? _cookPlaceholders(
    String locale,
    Message message,
    String? buffer, [
    Map<String, dynamic> args = const {},
  ]) {
    if (buffer == null) return null;
    final countPlaceholder =
        message.isPlural ? message.getCountPlaceholder() : null;
    var placeholders = message.placeholders;
    for (var i = 0; i < placeholders.length; i++) {
      final placeholder = placeholders[i];
      final value = args[placeholder.name];
      final optionals = {
        for (final parameter in placeholder.optionalParameters)
          parameter.name: parameter.value
      }; // ignore: prefer_for_elements_to_map_fromiterable
      String result;
      if (placeholder.isDate) {
        result = intl.DateFormat(placeholder.format, locale)
            .format(value as DateTime);
      } else if (placeholder.isNumber || placeholder == countPlaceholder) {
        final oName = optionals['name'] as String?;
        final oSymbol = optionals['symbol'] as String?;
        final oDecimalDigits = optionals['decimalDigits'] as int?;
        final oCustomPattern = optionals['customPattern'] as String?;
        switch (placeholder.format) {
          case 'compact':
            result = intl.NumberFormat.compact(locale: locale).format(value);
            break;
          case 'compactCurrency':
            result = intl.NumberFormat.compactCurrency(
              locale: locale,
              name: oName,
              symbol: oSymbol,
              decimalDigits: oDecimalDigits,
            ).format(value);
            break;
          case 'compactSimpleCurrency':
            result = intl.NumberFormat.compactSimpleCurrency(
              locale: locale,
              name: oName,
              decimalDigits: oDecimalDigits,
            ).format(value);
            break;
          case 'compactLong':
            result =
                intl.NumberFormat.compactLong(locale: locale).format(value);
            break;
          case 'currency':
            result = intl.NumberFormat.currency(
              locale: locale,
              name: oName,
              symbol: oSymbol,
              decimalDigits: oDecimalDigits,
              customPattern: oCustomPattern,
            ).format(value);
            break;
          case 'decimalPattern':
            result = intl.NumberFormat.decimalPattern().format(value);
            break;
          case 'decimalPercentPattern':
            result = intl.NumberFormat.decimalPercentPattern(
              locale: locale,
              decimalDigits: oDecimalDigits,
            ).format(value);
            break;
          case 'percentPattern':
            result = intl.NumberFormat.percentPattern().format(value);
            break;
          case 'scientificPattern':
            result = intl.NumberFormat.scientificPattern().format(value);
            break;
          case 'simpleCurrency':
            result = intl.NumberFormat.simpleCurrency(
              locale: locale,
              name: oName,
              decimalDigits: oDecimalDigits,
            ).format(value);
            break;
          default:
            result = value.toString();
        }
      } else {
        result = value.toString();
      }
      buffer = buffer?.replaceAll('{${placeholder.name}}', result);
    }
    return buffer;
  }

  String? _cookPlural(
    String locale,
    Message message, [
    Map<String, dynamic> args = const {},
  ]) {
    const pluralIds = ['=0', '=1', '=2', 'few', 'many', 'other'];

    var easyMessage = message.value;
    for (final placeholder in message.placeholders) {
      easyMessage = easyMessage.replaceAll(
          '{${placeholder.name}}', '#${placeholder.name}#');
    }
    var cookedPlurals = pluralIds
        .map((key) => _extractPlural(easyMessage, key))
        .map((extracted) => message.placeholders.fold<String?>(
              extracted,
              (extracted, placeholder) => extracted?.replaceAll(
                  '#${placeholder.name}#', '{${placeholder.name}}'),
            ))
        .map((normalized) => _cookPlaceholders(
              locale,
              message,
              normalized,
              args,
            ))
        .toList(growable: false);

    int howMany = args[message.getCountPlaceholder().name];
    return intl.Intl.pluralLogic(
      howMany,
      locale: locale,
      zero: cookedPlurals[0],
      one: cookedPlurals[1],
      two: cookedPlurals[2],
      few: cookedPlurals[3],
      many: cookedPlurals[4],
      other: cookedPlurals[5],
    );
  }

  String? _extractPlural(String easyMessage, String pluralKey) {
    final expRE = RegExp('($pluralKey)\\s*{([^}]+)}');
    final match = expRE.firstMatch(easyMessage);
    if (match != null && match.groupCount == 2) {
      return match.group(2)!;
    } else {
      return null;
    }
  }
}
