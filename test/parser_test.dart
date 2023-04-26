import 'package:phrase/src/phrase_arb.dart';
import 'package:phrase/src/phrase_exceptions.dart';
import 'package:test/test.dart';

void main(){
  test('Simple ARB ', () {
    String raw = '{"textSimple": "Simple Text","textWithParams": "Text with parameters: {amount} {comment}"}';
    var arb = AppResourceBundle.parse(raw);
    expect(arb.resources['textSimple'], 'Simple Text');
    expect(arb.resources['textWithParams'], 'Text with parameters: {amount} {comment}');
  });

  test('Illegal ARB', () {
    String raw = 'asd';
    try {
      AppResourceBundle.parse(raw);
    }catch(e){
      if(e is PhraseException) {}// ok
      else throw e;
    }
  });


}

