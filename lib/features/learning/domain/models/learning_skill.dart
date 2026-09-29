import 'package:flutter/material.dart';

/// Supported language learning skills tracked by the adaptive learning engine.
enum LearningSkill {
  speaking,
  listening,
  vocabulary,
  grammar,
  reading,
  pronunciation,
  fluency,
  comprehension,
}

extension LearningSkillX on LearningSkill {
  String get nameArabic {
    switch (this) {
      case LearningSkill.speaking:
        return 'المحادثة والتحدث';
      case LearningSkill.listening:
        return 'الاستماع والفهم';
      case LearningSkill.vocabulary:
        return 'المفردات والكلمات';
      case LearningSkill.grammar:
        return 'القواعد والتراكيب';
      case LearningSkill.reading:
        return 'القراءة والنصوص';
      case LearningSkill.pronunciation:
        return 'النطق ومخارج الحروف';
      case LearningSkill.fluency:
        return 'الطلاقة وسرعة الاستجابة';
      case LearningSkill.comprehension:
        return 'الاستيعاب العام';
    }
  }

  String get nameEnglish {
    switch (this) {
      case LearningSkill.speaking:
        return 'Speaking';
      case LearningSkill.listening:
        return 'Listening';
      case LearningSkill.vocabulary:
        return 'Vocabulary';
      case LearningSkill.grammar:
        return 'Grammar';
      case LearningSkill.reading:
        return 'Reading';
      case LearningSkill.pronunciation:
        return 'Pronunciation';
      case LearningSkill.fluency:
        return 'Fluency';
      case LearningSkill.comprehension:
        return 'Comprehension';
    }
  }

  IconData get icon {
    switch (this) {
      case LearningSkill.speaking:
        return Icons.record_voice_over_rounded;
      case LearningSkill.listening:
        return Icons.hearing_rounded;
      case LearningSkill.vocabulary:
        return Icons.menu_book_rounded;
      case LearningSkill.grammar:
        return Icons.auto_stories_rounded;
      case LearningSkill.reading:
        return Icons.article_rounded;
      case LearningSkill.pronunciation:
        return Icons.graphic_eq_rounded;
      case LearningSkill.fluency:
        return Icons.speed_rounded;
      case LearningSkill.comprehension:
        return Icons.psychology_rounded;
    }
  }
}
