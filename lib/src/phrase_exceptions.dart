class PhraseException implements Exception {
  final String message;
  PhraseException(this.message);
  @override
  String toString() => 'PhraseException: $message';
}

class PhraseApiException extends PhraseException {
  PhraseApiException(String message) : super(message);
}
