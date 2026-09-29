/// Supported question types within the language evaluation & placement architecture.
enum QuestionType {
  comprehension,
  translation,
  sentenceConstruction,
  vocabulary,
  grammar,
  speaking,
  listening,
  freeResponse;

  /// Distinguishes speech-driven evaluation from text-based interaction.
  bool get isSpeechType =>
      this == QuestionType.speaking || this == QuestionType.listening;
}
