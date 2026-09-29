import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/features/auth/domain/models/auth_user.dart';
import 'package:lahjti/features/onboarding/domain/models/age_group.dart';
import 'package:lahjti/features/onboarding/domain/models/experience_level.dart';
import 'package:lahjti/features/onboarding/domain/models/learning_goal.dart';
import 'package:lahjti/features/onboarding/domain/models/native_language.dart';
import 'package:lahjti/features/onboarding/domain/models/supported_language.dart';
import 'package:lahjti/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:lahjti/features/school/domain/models/school_role.dart';

void main() {
  group('OnboardingNotifier Unit Tests', () {
    late OnboardingNotifier notifier;

    setUp(() {
      notifier = OnboardingNotifier();
    });

    test('1. Initial state has step 0 and native Arabic by default', () {
      expect(notifier.state.currentStepIndex, 0);
      expect(notifier.state.data.nativeLanguage, NativeLanguage.arabic);
      expect(notifier.state.canProceed, isFalse);
    });

    test('2. Target language selection enables canProceed and advances', () {
      const lang = SupportedLanguage(
        id: 'es',
        nameEn: 'Spanish',
        nameAr: 'الإسبانية',
        flagEmoji: '🇪🇸',
      );

      notifier.selectTargetLanguage(lang);
      expect(notifier.state.data.targetLanguage, lang);
      expect(notifier.state.canProceed, isTrue);

      notifier.nextStep();
      expect(notifier.state.currentStepIndex, 1);
    });

    test('3. Age selection updates state', () {
      notifier.goToStep(1);
      expect(notifier.state.canProceed, isFalse);

      notifier.selectAgeGroup(AgeGroup.age19_25);
      expect(notifier.state.data.ageGroup, AgeGroup.age19_25);
      expect(notifier.state.canProceed, isTrue);
    });

    test('4. Native language selection updates state', () {
      notifier.goToStep(2);
      expect(notifier.state.canProceed, isTrue); // Arabic is default

      notifier.selectNativeLanguage(NativeLanguage.english);
      expect(notifier.state.data.nativeLanguage, NativeLanguage.english);
    });

    test('5. Goal selection updates state', () {
      notifier.goToStep(3);
      expect(notifier.state.canProceed, isFalse);

      const goal = LearningGoal(id: 'travel', icon: '✈️');
      notifier.selectLearningGoal(goal);
      expect(notifier.state.data.learningGoal, goal);
      expect(notifier.state.canProceed, isTrue);
    });

    test('6. Experience level selection updates state', () {
      notifier.goToStep(4);
      expect(notifier.state.canProceed, isFalse);

      notifier.selectExperienceLevel(ExperienceLevel.intermediate);
      expect(notifier.state.data.experienceLevel, ExperienceLevel.intermediate);
      expect(notifier.state.canProceed, isTrue);
    });

    test('7. Registered user saves to OnboardingData', () {
      final user = AuthUser(
        id: 'u123',
        email: 'test@lahjti.com',
        fullName: 'Abbas User',
        createdAt: DateTime.now(),
      );

      notifier.setRegisteredUser(user);
      expect(notifier.state.data.registeredUserId, 'u123');
      expect(notifier.state.data.registeredEmail, 'test@lahjti.com');
      expect(notifier.state.data.registeredName, 'Abbas User');
    });

    test('8. Tutor selection updates state', () {
      notifier.goToStep(6);
      expect(notifier.state.canProceed, isFalse);

      notifier.selectTutor('abbas');
      expect(notifier.state.data.selectedTutorId, 'abbas');
      expect(notifier.state.canProceed, isTrue);
    });

    test('9. Back navigation preserves all accumulated state', () {
      const lang = SupportedLanguage(
        id: 'en',
        nameEn: 'English',
        nameAr: 'الإنجليزية',
        flagEmoji: '🇬🇧',
      );
      notifier.selectTargetLanguage(lang);
      notifier.nextStep(); // Step 1

      notifier.selectAgeGroup(AgeGroup.age26_35);
      notifier.nextStep(); // Step 2

      notifier.selectNativeLanguage(NativeLanguage.arabic);
      notifier.nextStep(); // Step 3

      // Go back twice
      notifier.previousStep();
      notifier.previousStep();

      expect(notifier.state.currentStepIndex, 1);
      expect(notifier.state.data.targetLanguage, lang);
      expect(notifier.state.data.ageGroup, AgeGroup.age26_35);
      expect(notifier.state.data.nativeLanguage, NativeLanguage.arabic);
    });

    test('10. School Teacher state updates and step validation', () {
      notifier.selectSchoolRole(SchoolRole.teacher);
      expect(notifier.state.data.isSchool, isTrue);
      expect(notifier.state.data.isSchoolTeacher, isTrue);
      expect(notifier.state.totalInteractiveSteps, 2);
      expect(notifier.state.canProceed, isFalse); // Code not entered yet

      // Enter school code
      notifier.setSchoolDetails(schoolCode: 'SCH-1001', schoolName: 'Al-Rowad');
      expect(notifier.state.canProceed, isTrue);

      notifier.nextStep(); // Step 1: Teacher Setup
      expect(notifier.state.currentStepIndex, 1);
      expect(notifier.state.canProceed, isFalse); // Details not filled

      notifier.setTeacherDetails(
        fullName: 'Ahmad Teacher',
        subject: 'English',
        gradesTaught: ['Grade 8'],
      );
      expect(notifier.state.canProceed, isTrue);

      notifier.nextStep(); // Step 2: Completion
      expect(notifier.state.isCompletionStep, isTrue);
    });

    test('11. School Student state updates and step validation', () {
      notifier.selectSchoolRole(SchoolRole.student);
      expect(notifier.state.data.isSchool, isTrue);
      expect(notifier.state.data.isSchoolStudent, isTrue);
      expect(notifier.state.totalInteractiveSteps, 9);
      expect(notifier.state.canProceed, isFalse);

      notifier.setSchoolDetails(schoolCode: 'SCH-1001', schoolName: 'Al-Rowad');
      expect(notifier.state.canProceed, isTrue);

      notifier.nextStep(); // Step 1: Student Class Info
      expect(notifier.state.currentStepIndex, 1);
      expect(notifier.state.canProceed, isFalse);

      notifier.setStudentClassDetails(grade: 'Grade 10', classSection: 'A');
      expect(notifier.state.canProceed, isTrue);
    });
  });
}
