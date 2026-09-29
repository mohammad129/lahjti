import '../../../learning/domain/models/learner_context.dart';
import '../../domain/models/voice_session_state.dart';
import '../../domain/repositories/tutor_conversation_repository.dart';

/// Implementation of [TutorConversationRepository] that handles conversational
/// turns with Abbas and Dunya personas for tests and offline development.
class TutorConversationRepositoryImpl implements TutorConversationRepository {
  const TutorConversationRepositoryImpl();

  @override
  Future<VoiceMessage> generateTutorResponse({
    required String userText,
    required String targetLanguageCode,
    required String tutorId,
    required List<VoiceMessage> history,
    String nativeLanguage = 'arabic',
    String ageGroup = 'adult',
    String learningGoal = 'conversation',
    String difficulty = 'a1',
    bool isSessionStart = false,
    LearnerContext? learnerContext,
  }) async {
    final isAbbas = tutorId == 'abbas';
    final trimmed = userText.trim();

    // 1. Session start opening greeting
    if (isSessionStart) {
      return VoiceMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            isAbbas
                ? "Hey there! I'm Abbas, your practice partner. Ready to speak some English today? Tell me, how was your morning?"
                : "Hello! I'm Dunya, and I'm very excited to practice with you today. How is your day going so far?",
        explanationArabic:
            isAbbas
                ? "أهلاً وسهلاً يا بطل! جاهزين لنتدرب ونحكي مع بعض براحتنا 🔥"
                : "أهلاً وسهلاً فيك! أنا دنيا ورح نتدرب سوا خطوة بخطوة بكل هدوء 🌟",
        shouldCorrect: false,
        encouragement: isAbbas ? 'يلا نبدأ!' : 'بداية موفقة!',
        nextDifficulty: 'same',
        timestamp: DateTime.now(),
      );
    }

    String replyText;
    String? explanationArabic;
    String? correctedAnswer;
    List<String> detectedErrors = [];
    bool shouldCorrect = false;
    String? encouragement;

    // Check for repeated mistake in recent history
    final hadPastTenseMistakeInHistory = history.any(
      (m) =>
          m.text.toLowerCase().contains('go yesterday') ||
          (m.correctedAnswer != null && m.correctedAnswer!.contains('went')),
    );

    if (hadPastTenseMistakeInHistory &&
        (trimmed.toLowerCase().contains('go yesterday') ||
            trimmed.toLowerCase().contains('goed'))) {
      replyText =
          isAbbas
              ? "Haha, I see you're still determined with 'go'! Remember: 'I went yesterday.' Now tell me, what did you see there?"
              : "We are almost there! Remember to use 'I went yesterday.' Let's try saying it together!";
      correctedAnswer = "I went yesterday.";
      explanationArabic =
          isAbbas
              ? "يا رجل 😂 لسه بنحاول مع نفس الجملة! الماضي من go هو went، ما في هروب منها 😉"
              : "ولا يهمك، التكرار هو سر التعلم! تذكر دائمًا (went) للماضي 🌟";
      detectedErrors = ['Repeated past tense mistake: use "went"'];
      shouldCorrect = true;
      encouragement = isAbbas ? 'قربنا نتقنها 100%' : 'خطوة بخطوة عم نتقدم!';
    } else if (trimmed.toLowerCase().contains('go yesterday') ||
        trimmed.toLowerCase().contains('goed')) {
      replyText =
          isAbbas
              ? "Oh nice! You mean: 'I went yesterday.' Where did you go exactly?"
              : "Great effort! Just remember: 'I went yesterday.' Where did you go?";
      correctedAnswer = "I went yesterday.";
      explanationArabic =
          isAbbas
              ? "استنى استنى 😂 الفعل لازم يكون بالماضي (went) لأنك حكيت عن أمس 👍"
              : "محاولة ممتازة! بس تذكر إن الفعل بالماضي بصير (went) لما تحكي عن أمس 🌟";
      detectedErrors = ['Past tense: use "went" instead of "go"'];
      shouldCorrect = true;
      encouragement = isAbbas ? 'محاولة حلوة ومعنى واضح!' : 'رائع، استمر!';
    } else if (trimmed.toLowerCase().contains('hello') ||
        trimmed.toLowerCase().contains('hi')) {
      replyText =
          isAbbas
              ? "Hey! Awesome greeting! Tell me, what did you do today?"
              : "Hello there! Wonderful to talk with you. How is your day going?";
      explanationArabic =
          isAbbas
              ? "تحية ممتازة وبداية حلوة! حاول تجاوب بجملة كاملة 👌"
              : "تحية لطيفة ومتقنة! خلينا نكمل ونتدرب 🌟";
      encouragement = 'أحسنت!';
    } else {
      replyText =
          isAbbas
              ? "That sounds really interesting! Tell me more about why you like that."
              : "That's lovely! You are expressing your thoughts very clearly. What else happened?";
      explanationArabic =
          isAbbas
              ? "كلامك مفهوم وممتاز! كمل واحكيلي تفاصيل أكتر 🔥"
              : "ممتاز جدًا! طلاقتك عم تتحسن مع كل جملة 👏";
      encouragement = 'استمر، أداء رائع!';
    }

    return VoiceMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: replyText,
      explanationArabic: explanationArabic,
      correctedAnswer: correctedAnswer,
      detectedErrors: detectedErrors,
      shouldCorrect: shouldCorrect,
      encouragement: encouragement,
      nextDifficulty: 'same',
      timestamp: DateTime.now(),
    );
  }
}
