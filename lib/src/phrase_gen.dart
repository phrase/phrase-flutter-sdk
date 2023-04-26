import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'phrase_arb.dart';
import 'phrase_exceptions.dart';

class PhraseConfig {
  String inputFolder;
  String templateFile;
  String outputFolder;
  String targetFile;
  String flutterOutputFileName;

  PhraseConfig(
    this.inputFolder,
    this.templateFile,
    this.outputFolder,
    this.targetFile,
    this.flutterOutputFileName,
  );
}

//inspired by /flutter/packages/flutter_tools/lib/src/localizations/gen_l10n.dart
class PhraseGen {
  static const String _kOutputFileName = 'phrase_localizations.dart';
  static final String _projectFolder = Directory.current.path;

  static Future<PhraseConfig> _getConfig() async {
    var yamlFile = File(path.join(_projectFolder, 'l10n.yaml'));
    if (!await yamlFile.exists()) {
      throw PhraseException("'l10n.yaml' not found.");
    }
    var l10nYaml = yaml.loadYaml(await yamlFile.readAsString());
    var arbDir = l10nYaml['arb-dir'] ?? path.join('lib', 'l10n');
    var templateArbFile = l10nYaml['template-arb-file'] ?? 'app_en.arb';
    var flutterOutputFileName =
        l10nYaml['output-localization-file'] ?? 'app_localizations.dart';

    var isSynthetic = l10nYaml['synthetic-package'] != false;
    String outputDir;
    if (isSynthetic) {
      outputDir = path.join('.dart_tool', 'flutter_gen', 'gen_l10n');
    } else {
      outputDir = l10nYaml['output-dir'] ?? arbDir;
    }
    return PhraseConfig(arbDir, path.join(arbDir, templateArbFile), outputDir,
        path.join(outputDir, _kOutputFileName), flutterOutputFileName);
  }

  static Future<void> generate() async {
    PhraseConfig config = await _getConfig();
    var templateFile = File(path.join(_projectFolder, config.templateFile));
    var codegen = _generateFromArb(
        await templateFile.readAsString(), config.flutterOutputFileName);
    File genFile = File(path.join(_projectFolder, config.targetFile));
    await genFile.create(recursive: true);
    await genFile.writeAsString(codegen, mode: FileMode.writeOnly, flush: true);
    print("'$_kOutputFileName' has been successfully created");
  }

  static String _generateFromArb(String arbRaw, String flutterOutputFileName) {
    var buf = StringBuffer();
    buf.writeln("import '$flutterOutputFileName';");
    buf.writeln(
        "import 'package:flutter_localizations/flutter_localizations.dart';");
    buf.writeln("import 'package:flutter/foundation.dart';");
    buf.writeln("import 'package:flutter/widgets.dart';");
    buf.writeln("import 'package:phrase/phrase.dart';");
    buf.writeln('');
    buf.writeln(
        'class _PhraseLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {');
    buf.writeln('\tconst _PhraseLocalizationsDelegate();');
    buf.writeln('\t@override');
    buf.writeln(
        '\tFuture<AppLocalizations> load(Locale locale) => AppLocalizations.delegate.load(locale).then((fallback) => PhraseLocalizations(locale.toString(), fallback)).whenComplete(() => Phrase.onLocale(locale));');
    buf.writeln('\t@override');
    buf.writeln(
        '\tbool isSupported(Locale locale) => AppLocalizations.supportedLocales.contains(locale);');
    buf.writeln('\t@override');
    buf.writeln(
        '\tbool shouldReload(_PhraseLocalizationsDelegate old) => false;');
    buf.writeln('}');
    buf.writeln('');
    buf.writeln('class PhraseLocalizations extends AppLocalizations {');
    buf.writeln(
        '\tPhraseLocalizations(String locale, AppLocalizations fallback) : _fallback = fallback, super(locale);');
    buf.writeln('\tfinal AppLocalizations _fallback;');
    buf.writeln('');
    buf.writeln(
        '\tstatic const LocalizationsDelegate<AppLocalizations> delegate = _PhraseLocalizationsDelegate();');
    buf.writeln(
        '\tstatic const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[');
    buf.writeln('\t\tdelegate,');
    buf.writeln('\t\tGlobalMaterialLocalizations.delegate,');
    buf.writeln('\t\tGlobalCupertinoLocalizations.delegate,');
    buf.writeln('\t\tGlobalWidgetsLocalizations.delegate,');
    buf.writeln('\t];');
    buf.writeln(
        '\tstatic const List<Locale> supportedLocales = AppLocalizations.supportedLocales;');
    buf.writeln('');

    var arb = AppResourceBundle.parse(arbRaw);
    var messages = arb.resourceIds
        .map((id) => Message(arb.resources, id, false))
        .toList(growable: false);
    for (var message in messages) {
      var id = message.resourceId;
      buf.writeln('\t@override');
      if (message.placeholders.isEmpty) {
        buf.writeln(
            "\tString get $id => Phrase.getText(localeName, '$id') ?? _fallback.$id;");
      } else {
        var params = _generateMethodParameters(message).join(', ');
        var values = message.placeholders
            .map((placeholder) => placeholder.name)
            .join(', ');
        var args = message.placeholders
            .map((placeholder) => '\'${placeholder.name}\':${placeholder.name}')
            .join(', ');
        buf.writeln(
            "\tString $id($params) => Phrase.getText(localeName, '$id', {$args}) ?? _fallback.$id($values);");
      }
    }
    buf.writeln('}');
    return buf.toString();
  }

  // 'int' -> 'num' since Flutter 2.10.0
  // see https://github.com/flutter/flutter/pull/93228/commits/5d3fc8f68ae6947593a61426976bcb53d1191735
  static List<String> _generateMethodParameters(Message message) {
    assert(message.placeholders.isNotEmpty);
    final countPlaceholder =
        message.isPlural ? message.getCountPlaceholder() : null;
    return message.placeholders.map((Placeholder placeholder) {
      final type = placeholder == countPlaceholder ? 'num' : placeholder.type;
      return '$type ${placeholder.name}';
    }).toList();
  }
}

Builder phraseBuilder(BuilderOptions options) => PhraseBuilder();

class PhraseBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        r'$package$': [
          '.dart_tool/flutter_gen/gen_l10n/${PhraseGen._kOutputFileName}'
        ]
      };

  static final _globArb = Glob('lib/**.arb');

  @override
  Future<void> build(BuildStep buildStep) async {
    try {
      PhraseConfig config = await PhraseGen._getConfig();
      await for (final input in buildStep.findAssets(_globArb)) {
        if (path.equals(input.path, config.templateFile)) {
          var codegen = PhraseGen._generateFromArb(
              await buildStep.readAsString(input),
              config.flutterOutputFileName);
          AssetId output =
              AssetId(buildStep.inputId.package, config.targetFile);
          await buildStep.writeAsString(output, codegen);
          return;
        }
      }
    } catch (e) {
      return;
    }
  }
}
