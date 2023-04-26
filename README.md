# Phrase Strings OTA for Flutter

Library for Phrase Strings over-the-air translations.

## Installation

_Important: this library depends on 0.17.0 version of Flutter's [intl library](https://pub.dev/packages/intl).
Please follow [this guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization) to add localizations support to your app._

Add the `phrase` dependency to your pubspec.yaml:

```yaml
dependencies:
  phrase: ^1.0.5
  ...
  intl: ^0.17.0
  flutter_localizations:
    sdk: flutter
  ...

flutter:
  generate: true
  ...
```

Just like `intl` library, `phrase` uses code generation to process your ARB files.

To keep it up-to-date, just run this command:

```bash
$ flutter pub run phrase
```

or if you're using `build_runner`:

```bash
$ flutter pub run build_runner watch
```

## Usage

Initialize Phrase Strings in your `main.dart` file:

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

That's it! You can access your messages just like you did before:

```dart
Text(AppLocalizations.of(context)!.helloWorld);
```

But now your app will check for updated translations in Phrase regularly and download them in the background.

## Customization

### Update behavior

By default, Phrase Strings will update OTA translations every time the app launches.

You can disable this behavior:

```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", checkForUpdates: false);
```

and trigger updates manually:

```dart
Phrase.updateTranslations(context).then((_) => print("Done!"));
```

### Api host

By default phrase uses european host. But we can set it to use the US api host if needed.
To do so, we just have to set it up during initial setup:

```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", host: PhraseHost.us);
```

### Custom app version

The SDK will use the app version by default to return a release which matches the release constraints for the min and max version. The app version has to use semantic versioning otherwise no translation update will be returned. In case your app does not use semantic versioning it is possible to manually override the app version:

```dart
Phrase.setup("[DISTRIBUTION_ID]", "[ENVIRONMENT_ID]", customAppVersion: "1.2.3");
```
