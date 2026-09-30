/// Route path definitions for the Lahjti application.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String tutor = '/tutor';
  static const String tutorConversation = '/tutor/conversation';
  static const String learning = '/learning';
  static const String vocabulary = '/vocabulary';
  static const String vocabularyPractice = '/vocabulary/practice';
  static const String exams = '/exams';
  static const String examsSession = '/exams/session';
  static const String examsResult = '/exams/result';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String subscription = '/subscription';
  static const String teacherHome = '/teacher/home';
  static const String admin = '/admin';
  static const String teacherClassDetails = '/teacher/classes/:classId';
  static const String teacherStudentDetails = '/teacher/students/:studentId';
  static const String studentHome = '/student/home';
  static const String studentProgress = '/student/progress';
  static const String studentGames = '/student/games';
  static const String games = '/games';
  static const String gamePlay = '/student/games/:gameId';
  static const String gamePlayDirect = '/games/:gameId';
}
