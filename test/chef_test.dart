import 'package:phrase/src/phrase_arb.dart';
import 'package:phrase/src/phrase_chef.dart';
import 'package:test/test.dart';

String _rawSimple = '{"textSimple": "Simple Text"}';

String _rawParams = '{'
        '"textWithParams": "Text with parameters: {amount} {comment}",'
        '"@textWithParams": {' +
    '"description": "Text with different placeholders",' +
    '"placeholders": {' +
    '"amount": {' +
    '"type": "int",' +
    '"format": "compactCurrency",' +
    '"optionalParameters": {' +
    '"decimalDigits": 2' +
    '}' +
    '},' +
    '"comment": {' +
    '"type": "String"' +
    '}' +
    '}' +
    '}}';

String _rawPlural = '{'
    '"textPlural": "{howMany,plural, =0{No clicks}=1{{howMany} click}=2{{howMany} clicks}few{{howMany} clicks}many{{howMany} clicks}other{{howMany} clicks}}",'
    '"@textPlural": {'
    '"description": "Text with plural",'
    '"placeholders": {'
    '"howMany": {}'
    '}'
    '}}';

String _rawPluralRu = '{'
    '"textPlural": "{howMany,plural, =0{Нет нажатий}=1{{howMany} нажатие}=2{{howMany} нажатия}few{{howMany} нажатия}many{{howMany} нажатий}other{{howMany} нажатий}}",'
    '"@textPlural": {'
    '"description": "Text with plural",'
    '"placeholders": {'
    '"howMany": {}'
    '}'
    '}}';

void main() {
  final PhraseChef chef = PhraseChef();

  test('Cook simple', () {
    var arb = AppResourceBundle.parse(_rawSimple);
    String? actual = chef.cook("en", arb, "textSimple");
    expect(actual, "Simple Text");
  });

  test('Cook placeholders', () {
    var arb = AppResourceBundle.parse(_rawParams);
    String? actual =
        chef.cook("en", arb, "textWithParams", {'amount': 1, 'comment': "A"});
    expect(actual, "Text with parameters: USD1.00 A");
  });

  test('Fail placeholders', () {
    var arb = AppResourceBundle.parse(_rawParams);
    try {
      chef.cook("en", arb, "textWithParams", {'amount': "A", 'comment': "A"});
    } catch (e) {
      if (e is NoSuchMethodError) {
      } // ok
      else {
        rethrow;
      }
    }
  });

  test('Cook plural', () {
    var arb = AppResourceBundle.parse(_rawPlural);
    expect(chef.cook("en", arb, "textPlural", {'howMany': 0}), "No clicks");
    expect(chef.cook("en", arb, "textPlural", {'howMany': 1}), "1 click");
    expect(chef.cook("en", arb, "textPlural", {'howMany': 5}), "5 clicks");

    var arbRu = AppResourceBundle.parse(_rawPluralRu);
    expect(chef.cook("ru", arbRu, "textPlural", {'howMany': 0}), "Нет нажатий");
    expect(chef.cook("ru", arbRu, "textPlural", {'howMany': 1}), "1 нажатие");
    expect(chef.cook("ru", arbRu, "textPlural", {'howMany': 2}), "2 нажатия");
    expect(chef.cook("ru", arbRu, "textPlural", {'howMany': 5}), "5 нажатий");
    expect(chef.cook("ru", arbRu, "textPlural", {'howMany': 21}), "21 нажатие");
  });
}
