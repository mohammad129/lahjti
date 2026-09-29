import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/account/presentation/screens/subscription_access_screen.dart';
import '../../features/exams/presentation/screens/exam_result_screen.dart';
import '../../features/exams/presentation/screens/exam_session_screen.dart';
import '../../features/exams/presentation/screens/exams_hub_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learning/presentation/screens/lesson_session_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/school/presentation/screens/educational_games_hub_screen.dart';
import '../../features/school/presentation/screens/game_play_screen.dart';
import '../../features/school/presentation/screens/student_progress_screen.dart';
import '../../features/school/presentation/screens/student_school_home_screen.dart';
import '../../features/school/presentation/screens/teacher_class_details_screen.dart';
import '../../features/school/presentation/screens/teacher_home_screen.dart';
import '../../features/school/presentation/screens/teacher_student_details_screen.dart';
import '../../features/tutor/presentation/screens/tutor_conversation_screen.dart';
import '../../features/vocabulary/presentation/screens/vocabulary_practice_screen.dart';
import '../../features/vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import 'app_routes.dart';

/// Riverpod provider for the GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.welcome,
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        name: 'studentHome',
        builder: (context, state) => const StudentSchoolHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentProgress,
        name: 'studentProgress',
        builder: (context, state) => const StudentProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentGames,
        name: 'studentGames',
        builder: (context, state) => const EducationalGamesHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.games,
        name: 'games',
        builder: (context, state) => const EducationalGamesHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamePlay,
        name: 'gamePlay',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return GamePlayScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: AppRoutes.gamePlayDirect,
        name: 'gamePlayDirect',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return GamePlayScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherHome,
        name: 'teacherHome',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherClassDetails,
        name: 'teacherClassDetails',
        builder: (context, state) {
          final classId = state.pathParameters['classId'] ?? '';
          return TeacherClassDetailsScreen(classId: classId);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherStudentDetails,
        name: 'teacherStudentDetails',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId'] ?? '';
          final classId = state.uri.queryParameters['classId'] ?? '';
          return TeacherStudentDetailsScreen(
            studentId: studentId,
            classId: classId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tutor,
        name: 'tutor',
        builder: (context, state) => const TutorConversationScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorConversation,
        name: 'tutorConversation',
        builder: (context, state) => const TutorConversationScreen(),
      ),
      GoRoute(
        path: AppRoutes.learning,
        name: 'learning',
        builder: (context, state) {
          final lessonId = state.uri.queryParameters['lessonId'];
          return LessonSessionScreen(lessonId: lessonId);
        },
      ),
      GoRoute(
        path: AppRoutes.vocabulary,
        name: 'vocabulary',
        builder: (context, state) => const VocabularyScreen(),
      ),
      GoRoute(
        path: AppRoutes.vocabularyPractice,
        name: 'vocabularyPractice',
        builder: (context, state) => const VocabularyPracticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.exams,
        name: 'exams',
        builder: (context, state) => const ExamsHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.examsSession,
        name: 'examsSession',
        builder: (context, state) => const ExamSessionScreen(),
      ),
      GoRoute(
        path: AppRoutes.examsResult,
        name: 'examsResult',
        builder: (context, state) => const ExamResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionAccessScreen(),
      ),
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
