import 'dart:convert';

import 'phrase_exceptions.dart';

class AppResourceBundle {
  const AppResourceBundle(/*this.locale, */ this.resources, this.resourceIds);

  //final LocaleInfo locale; TODO
  final Map<String, dynamic> resources;
  final Iterable<String> resourceIds;

  //String translationFor(Message message) => resources[message.resourceId] as String;

  static AppResourceBundle parse(String arbRaw) {
    Map<String, dynamic> resources;
    try {
      resources = json.decode(arbRaw);
    } on FormatException catch (e) {
      throw PhraseException(
          'The arb file has the following formatting issue: \n${e.toString()}');
    }
    var ids = resources.keys
        .where((String key) => !key.startsWith('@'))
        .toList(growable: false);
    return AppResourceBundle(resources, ids);
  }
}

class Message {
  Message(
    Map<String, dynamic> bundle,
    this.resourceId,
    bool isResourceAttributeRequired,
  )   : assert(resourceId.isNotEmpty),
        value = _value(bundle, resourceId),
        description =
            _description(bundle, resourceId, isResourceAttributeRequired),
        placeholders =
            _placeholders(bundle, resourceId, isResourceAttributeRequired),
        _pluralMatch = _pluralRE.firstMatch(_value(bundle, resourceId));

  static final RegExp _pluralRE = RegExp(r'\s*\{([\w\s,]*),\s*plural\s*,');

  final String resourceId;
  final String value;
  final String? description;
  final List<Placeholder> placeholders;
  final RegExpMatch? _pluralMatch;

  bool get isPlural => _pluralMatch != null && _pluralMatch!.groupCount == 1;

  bool get placeholdersRequireFormatting =>
      placeholders.any((Placeholder p) => p.requiresFormatting);

  Placeholder getCountPlaceholder() {
    assert(isPlural);
    final countPlaceholderName = _pluralMatch![1]!;
    return placeholders.firstWhere(
      (Placeholder p) => p.name == countPlaceholderName,
      orElse: () {
        throw PhraseException(
            'Cannot find the $countPlaceholderName placeholder in plural message "$resourceId".');
      },
    );
  }

  static String _value(Map<String, dynamic> bundle, String resourceId) {
    final dynamic value = bundle[resourceId];
    if (value == null) {
      throw PhraseException(
          'A value for resource "$resourceId" was not found.');
    }
    if (value is! String) {
      throw PhraseException('The value of "$resourceId" is not a string.');
    }
    return bundle[resourceId] as String;
  }

  static Map<String, dynamic>? _attributes(
    Map<String, dynamic> bundle,
    String resourceId,
    bool isResourceAttributeRequired,
  ) {
    final dynamic attributes = bundle['@$resourceId'];
    if (isResourceAttributeRequired) {
      if (attributes == null) {
        throw PhraseException(
            'Resource attribute "@$resourceId" was not found. Please '
            'ensure that each resource has a corresponding @resource.');
      }
    }

    if (attributes != null && attributes is! Map<String, dynamic>) {
      throw PhraseException(
          'The resource attribute "@$resourceId" is not a properly formatted Map. '
          'Ensure that it is a map with keys that are strings.');
    }

    final RegExpMatch? pluralRegExp =
        _pluralRE.firstMatch(_value(bundle, resourceId));
    final bool isPlural = pluralRegExp != null && pluralRegExp.groupCount == 1;
    if (attributes == null && isPlural) {
      throw PhraseException(
          'Resource attribute "@$resourceId" was not found. Please '
          'ensure that plural resources have a corresponding @resource.');
    }

    return attributes as Map<String, dynamic>?;
  }

  static String? _description(
    Map<String, dynamic> bundle,
    String resourceId,
    bool isResourceAttributeRequired,
  ) {
    final Map<String, dynamic>? resourceAttributes = _attributes(
      bundle,
      resourceId,
      isResourceAttributeRequired,
    );
    if (resourceAttributes == null) {
      return null;
    }

    final dynamic value = resourceAttributes['description'];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw PhraseException(
          'The description for "@$resourceId" is not a properly formatted String.');
    }
    return value;
  }

  static List<Placeholder> _placeholders(
    Map<String, dynamic> bundle,
    String resourceId,
    bool isResourceAttributeRequired,
  ) {
    final Map<String, dynamic>? resourceAttributes = _attributes(
      bundle,
      resourceId,
      isResourceAttributeRequired,
    );
    if (resourceAttributes == null) {
      return <Placeholder>[];
    }
    final dynamic value = resourceAttributes['placeholders'];
    if (value == null) {
      return <Placeholder>[];
    }
    if (value is! Map<String, dynamic>) {
      throw PhraseException(
          'The "placeholders" attribute for message $resourceId, is not '
          'properly formatted. Ensure that it is a map with string valued keys.');
    }
    final Map<String, dynamic> allPlaceholdersMap = value;
    return allPlaceholdersMap.keys.map<Placeholder>((String placeholderName) {
      final dynamic value = allPlaceholdersMap[placeholderName];
      if (value is! Map<String, dynamic>) {
        throw PhraseException(
            'The value of the "$placeholderName" placeholder attribute for message '
            '"$resourceId", is not properly formatted. Ensure that it is a map '
            'with string valued keys.');
      }
      return Placeholder(resourceId, placeholderName, value);
    }).toList();
  }
}

class Placeholder {
  Placeholder(
    this.resourceId,
    this.name,
    Map<String, dynamic> attributes,
  )   : example = _stringAttribute(resourceId, name, attributes, 'example'),
        type =
            _stringAttribute(resourceId, name, attributes, 'type') ?? 'Object',
        format = _stringAttribute(resourceId, name, attributes, 'format'),
        optionalParameters = _optionalParameters(resourceId, name, attributes);

  final String resourceId;
  final String name;
  final String? example;
  final String type;
  final String? format;
  final List<OptionalParameter> optionalParameters;

  bool get requiresFormatting =>
      <String>['DateTime', 'double', 'int', 'num'].contains(type);
  bool get isNumber => <String>['double', 'int', 'num'].contains(type);
  bool get hasValidNumberFormat => _validNumberFormats.contains(format);
  bool get hasNumberFormatWithParameters =>
      _numberFormatsWithNamedParameters.contains(format);
  bool get isDate => 'DateTime' == type;
  bool get hasValidDateFormat => _validDateFormats.contains(format);

  static String? _stringAttribute(
    String resourceId,
    String name,
    Map<String, dynamic> attributes,
    String attributeName,
  ) {
    final dynamic value = attributes[attributeName];
    if (value == null) {
      return null;
    }
    if (value is! String || (value).isEmpty) {
      throw PhraseException(
        'The "$attributeName" value of the "$name" placeholder in message $resourceId '
        'must be a non-empty string.',
      );
    }
    return value;
  }

  static List<OptionalParameter> _optionalParameters(
    String resourceId,
    String name,
    Map<String, dynamic> attributes,
  ) {
    final dynamic value = attributes['optionalParameters'];
    if (value == null) {
      return <OptionalParameter>[];
    }
    if (value is! Map<String, dynamic>) {
      throw PhraseException(
          'The "optionalParameters" value of the "$name" placeholder in message '
          '$resourceId is not a properly formatted Map. Ensure that it is a map '
          'with keys that are strings.');
    }
    final optionalParameterMap = value;
    return optionalParameterMap.keys
        .map<OptionalParameter>((String parameterName) => OptionalParameter(
              parameterName,
              optionalParameterMap[parameterName],
            ))
        .toList();
  }
}

class OptionalParameter {
  const OptionalParameter(this.name, this.value);

  final String name;
  final Object value;
}

const Set<String> _validNumberFormats = <String>{
  'compact',
  'compactCurrency',
  'compactSimpleCurrency',
  'compactLong',
  'currency',
  'decimalPattern',
  'decimalPercentPattern',
  'percentPattern',
  'scientificPattern',
  'simpleCurrency',
};

const Set<String> _numberFormatsWithNamedParameters = <String>{
  'compact',
  'compactCurrency',
  'compactSimpleCurrency',
  'compactLong',
  'currency',
  'decimalPercentPattern',
  'simpleCurrency',
};

const Set<String> _validDateFormats = <String>{
  'd',
  'E',
  'EEEE',
  'LLL',
  'LLLL',
  'M',
  'Md',
  'MEd',
  'MMM',
  'MMMd',
  'MMMEd',
  'MMMM',
  'MMMMd',
  'MMMMEEEEd',
  'QQQ',
  'QQQQ',
  'y',
  'yM',
  'yMd',
  'yMEd',
  'yMMM',
  'yMMMd',
  'yMMMEd',
  'yMMMM',
  'yMMMMd',
  'yMMMMEEEEd',
  'yQQQ',
  'yQQQQ',
  'H',
  'Hm',
  'Hms',
  'j',
  'jm',
  'jms',
  'jmv',
  'jmz',
  'jv',
  'jz',
  'm',
  'ms',
  's',
};
