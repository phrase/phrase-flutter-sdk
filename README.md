# Phrase Over the Air SDK for Flutter

Publish your translations faster and simpler than ever before. Stop waiting for the next deployment and start publishing all your translations in real-time directly in Phrase.

Head over to the Phrase Help Center to learn about this feature and how to use it in your apps: https://support.phrase.com/hc/en-us/articles/5804059067804

## Instructions

With the SDK, the app regularly checks for updated translations and downloads them in the background.

Example [app](https://github.com/phrase/flutter_sdk_example)

### Requirements

This library depends on 0.18.0 or greater of Flutter's [intl](https://pub.dev/packages/intl) library. Follow [their guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization) to add localizations support to the app.

### Installation

Add Phrase to the pubspec.yaml:


```yaml
dependencies:
  phrase: ^2.5.2
  ...
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter
  ...

flutter:
  generate: true
  ...
```

Like in the `intl` library, code generation is used to process ARB files. Run this command to update:
```
flutter pub run phrase
```

Using build_runner:
```
flutter pub run build_runner watch
```

### Usage

Initialize Phrase in the `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/phrase_localizations.dart';
import 'package:phrase/phrase.dart';

void main() {
  Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      //..
      localizationsDelegates: PhraseLocalizations.localizationsDelegates,
      supportedLocales: PhraseLocalizations.supportedLocales,
    );
  }
}
```

Access messages with:
```dart
Text(AppLocalizations.of(context)!.helloWorld);
```

### Update behavior
OTA translations are updated every time the app launches. To disable this:
```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", checkForUpdates: false);
```

To update manually:
```dart
Phrase.updateTranslations(context).then((_) => print("Done!"));
```

### Custom app version
The SDK uses the app version by default to return a release which matches the release constraints for the min and max version. The app version must use semantic versioning otherwise no translation update will be returned. In case app does not use semantic versioning, the app version can be manually overridden: it is possible to manually override the app version:

```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", customAppVersion: "1.2.3");
```

### Configure US data center

Phrase US data center is also supported. The US data center can be selected by passing the relevant API hostname parameter in the SDK configuration:

```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", host: PhraseHost.us);
```
