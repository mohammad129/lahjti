import 'package:flutter/foundation.dart';
import 'subscription_status_enums.dart';

/// Immutable domain model describing subscription and license plans.
@immutable
class SubscriptionPlan {
  final String id;
  final String titleArabic;
  final String titleEnglish;
  final String descriptionArabic;
  final String descriptionEnglish;
  final double priceUsd;
  final String currency;
  final SubscriptionPeriod period;
  final String billingPeriod;
  final int trialDurationDays;
  final List<String> featuresArabic;
  final List<String> featuresEnglish;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.titleArabic,
    required this.titleEnglish,
    required this.descriptionArabic,
    required this.descriptionEnglish,
    required this.priceUsd,
    this.currency = 'USD',
    this.period = SubscriptionPeriod.monthly,
    required this.billingPeriod,
    required this.trialDurationDays,
    required this.featuresArabic,
    required this.featuresEnglish,
    this.isPopular = false,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleArabic : titleEnglish;
  String localizedDescription(bool isArabic) =>
      isArabic ? descriptionArabic : descriptionEnglish;
  List<String> localizedFeatures(bool isArabic) =>
      isArabic ? featuresArabic : featuresEnglish;

  String get formattedPrice =>
      priceUsd == 0 ? '0 USD' : '${priceUsd.toStringAsFixed(0)} USD';

  // Backwards compatibility aliases
  String get priceFormatted => '\$${priceUsd.toStringAsFixed(0)} / month';
  String get priceFormattedAr =>
      '${priceUsd.toStringAsFixed(0)} دولارات شهرياً (\$${priceUsd.toStringAsFixed(0)}/شهر)';
  List<String> get featuresAr => featuresArabic;
  List<String> get featuresEn => featuresEnglish;

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleArabic': titleArabic,
    'titleEnglish': titleEnglish,
    'descriptionArabic': descriptionArabic,
    'descriptionEnglish': descriptionEnglish,
    'priceUsd': priceUsd,
    'currency': currency,
    'period': period.name,
    'billingPeriod': billingPeriod,
    'trialDurationDays': trialDurationDays,
    'featuresArabic': featuresArabic,
    'featuresEnglish': featuresEnglish,
    'isPopular': isPopular,
  };

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String? ?? 'individual_monthly',
      titleArabic: json['titleArabic'] as String? ?? '',
      titleEnglish: json['titleEnglish'] as String? ?? '',
      descriptionArabic: json['descriptionArabic'] as String? ?? '',
      descriptionEnglish: json['descriptionEnglish'] as String? ?? '',
      priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 10.0,
      currency: json['currency'] as String? ?? 'USD',
      period: SubscriptionPeriod.fromString(json['period'] as String?),
      billingPeriod: json['billingPeriod'] as String? ?? 'شهرياً / Monthly',
      trialDurationDays: (json['trialDurationDays'] as num?)?.toInt() ?? 3,
      featuresArabic:
          (json['featuresArabic'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      featuresEnglish:
          (json['featuresEnglish'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  /// Standard Individual Monthly Plan ($10/mo with 3-day trial).
  static const SubscriptionPlan individualMonthly = SubscriptionPlan(
    id: 'lahjti_individual_monthly',
    titleArabic: 'الاشتراك الفردي المميز',
    titleEnglish: 'Individual Premium Plan',
    descriptionArabic: 'وصول شامل لجميع الدروس والمحادثة مع المعلم الذكي',
    descriptionEnglish:
        'Full unlimited access to all lessons and AI conversation tutor',
    priceUsd: 10.0,
    currency: 'USD',
    period: SubscriptionPeriod.monthly,
    billingPeriod: 'شهرياً / Monthly',
    trialDurationDays: 3,
    isPopular: true,
    featuresArabic: [
      '3 أيام تجربة مجانية كاملة',
      'محادثات ذكاء اصطناعي صوتية غير محدودة',
      'تتبع مستوى CEFR وجميع المهارات',
      'مراجعة المفردات بالتكرار المتباعد',
      'جميع الألعاب التعليمية التفاعلية',
    ],
    featuresEnglish: [
      '3-Day full free trial',
      'Unlimited AI voice & conversational turns',
      'CEFR level tracking and skill evaluation',
      'Spaced-repetition vocabulary practice',
      'All 5 interactive educational mini-games',
    ],
  );

  /// School Student License (10-day trial or institutional access).
  static const SubscriptionPlan schoolStudentLicense = SubscriptionPlan(
    id: 'school_student_license',
    titleArabic: 'رخصة الطالب المدرسي',
    titleEnglish: 'School Student License',
    descriptionArabic: 'تعلّم مدرسي مخصص مرتبط بفصلك ومعلمك',
    descriptionEnglish:
        'Curriculum-aligned learning synchronized with your classroom',
    priceUsd: 0.0,
    currency: 'USD',
    period: SubscriptionPeriod.yearly,
    billingPeriod: 'مغطى برخصة المدرسة / Covered by School License',
    trialDurationDays: 10,
    featuresArabic: [
      '10 أيام تجربة مجانية للطلاب',
      'مهام يومية منهجية تتكيف مع مستواك',
      'ألعاب تعليمية تفاعلية تعزز القواعد والمفردات',
      'ربط آمن مع المدرسة دون إعلانات',
    ],
    featuresEnglish: [
      '10-Day free student trial',
      'Curriculum-aligned daily learning tasks',
      'Educational mini-games reinforcing grammar & vocab',
      'Safe school integration with zero ads',
    ],
  );

  /// School Teacher License.
  static const SubscriptionPlan schoolTeacherLicense = SubscriptionPlan(
    id: 'school_teacher_license',
    titleArabic: 'رخصة المعلم المعتمد',
    titleEnglish: 'Certified Teacher License',
    descriptionArabic: 'لوحة تحكم المعلم وإدارة الفصول الدراسية',
    descriptionEnglish: 'Teacher dashboard and student progress oversight',
    priceUsd: 0.0,
    currency: 'USD',
    period: SubscriptionPeriod.yearly,
    billingPeriod: 'حساب مدرسي معتمد / Verified School Portal',
    trialDurationDays: 0,
    featuresArabic: [
      'لوحة المعلم وإدارة الفصول المسندة',
      'متابعة مستوى المهارات التعليمية ونقاط القوة والضعف',
      'حماية خصوصية محادثات الطلاب بشكل كامل',
    ],
    featuresEnglish: [
      'Teacher dashboard for assigned classrooms',
      'Track student skill mastery, strengths, and areas for improvement',
      'Strict student privacy protection (zero AI surveillance)',
    ],
  );
}
