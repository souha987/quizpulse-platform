import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

// Screens
import '../../features/visitor/screens/visitor_home_screen.dart';
import '../../features/visitor/screens/visitor_pricing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/join_quiz_screen.dart';
import '../../features/student/screens/qr_scanner_screen.dart';
import '../../features/student/screens/active_quiz_screen.dart';
import '../../features/student/screens/quiz_result_screen.dart';
import '../../features/student/screens/student_history_screen.dart';
import '../../features/student/screens/student_classes_screen.dart';
import '../../features/student/screens/student_class_detail_screen.dart';
import '../../features/student/screens/student_quizzes_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_quizzes_screen.dart';
import '../../features/teacher/screens/quiz_editor_screen.dart';
import '../../features/teacher/screens/teacher_analytics_screen.dart';
import '../../features/teacher/screens/teacher_classes_screen.dart';
import '../../features/teacher/screens/teacher_class_detail_screen.dart';
import '../../features/teacher/screens/teacher_subscription_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_moderation_screen.dart';
import '../../features/admin/screens/admin_finance_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);

    // Attendre le chargement de la session sauvegardée depuis le stockage local
    // afin de préserver l'URL demandée lors d'un rafraîchissement (F5) et ne pas rediriger
    // prématurément vers /login puis vers la racine du tableau de bord.
    if (authState.isLoading) {
      return null;
    }

    final isAuth = authState.isAuthenticated;
    final role = authState.role;
    final path = state.uri.path;

    // Protection des routes Étudiant (avec accès anonyme autorisé pour le passage de quiz démo & PIN, et prévisualisation autorisée pour les enseignants)
    if (path.startsWith('/student')) {
      final isPublicDemoOrPreviewAllowed = path.startsWith('/student/quiz/') || path == '/student/join' || path == '/student/result';
      if (!isAuth && !isPublicDemoOrPreviewAllowed) return '/login';
      if (isAuth && role != UserRole.etudiant && role != UserRole.admin && role != UserRole.visiteur && !isPublicDemoOrPreviewAllowed) {
        return '/teacher';
      }
    }

    // Protection des routes Enseignant
    if (path.startsWith('/teacher')) {
      if (!isAuth) return '/login';
      if (role != UserRole.enseignant && role != UserRole.admin) {
        return '/student';
      }
    }

    // Protection des routes Admin
    if (path.startsWith('/admin')) {
      if (!isAuth) return '/login';
      if (role != UserRole.admin) {
        return '/';
      }
    }

    // Si l'utilisateur est connecté et tente d'aller sur login, register ou verify-email,
    // il est automatiquement redirigé vers son espace dédié (Enseignant, Admin ou Étudiant)
    if (isAuth && (path == '/login' || path == '/register' || path == '/verify-email')) {
      if (role == UserRole.enseignant) return '/teacher';
      if (role == UserRole.admin) return '/admin';
      return '/student';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Visiteur
      GoRoute(
        path: '/',
        builder: (context, state) => const VisitorHomeScreen(),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const VisitorPricingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final queryEmail = state.uri.queryParameters['email'];
          final queryCode = state.uri.queryParameters['code'];
          final extraMap = state.extra is Map ? (state.extra as Map) : null;
          final email = queryEmail ?? extraMap?['email'] as String?;
          final code = queryCode ?? extraMap?['code'] as String?;
          return EmailVerificationScreen(
            initialEmail: email,
            initialCode: code,
          );
        },
      ),

      // Étudiant
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/join',
        builder: (context, state) => const JoinQuizScreen(),
      ),
      GoRoute(
        path: '/student/scan',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'quiz';
          return QrScannerScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/student/quiz/:id',
        builder: (context, state) {
          final quizId = state.pathParameters['id'] ?? '';
          return ActiveQuizScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/student/result',
        builder: (context, state) => const QuizResultScreen(),
      ),
      GoRoute(
        path: '/student/history',
        builder: (context, state) => const StudentHistoryScreen(),
      ),
      GoRoute(
        path: '/student/classes',
        builder: (context, state) => const StudentClassesScreen(),
      ),
      GoRoute(
        path: '/student/classes/:id',
        builder: (context, state) {
          final classId = state.pathParameters['id'] ?? '';
          return StudentClassDetailScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/student/quizzes',
        builder: (context, state) => const StudentQuizzesScreen(),
      ),

      // Enseignant
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/quizzes',
        builder: (context, state) => const TeacherQuizzesScreen(),
      ),
      GoRoute(
        path: '/teacher/quiz/create',
        builder: (context, state) {
          final classId = state.uri.queryParameters['classId'];
          return QuizEditorScreen(initialClassId: classId);
        },
      ),
      GoRoute(
        path: '/teacher/quiz/:id/edit',
        builder: (context, state) {
          final quizId = state.pathParameters['id'] ?? '';
          return QuizEditorScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/teacher/analytics',
        builder: (context, state) => const TeacherAnalyticsScreen(),
      ),
      GoRoute(
        path: '/teacher/quiz/:id/analytics',
        builder: (context, state) {
          final quizId = state.pathParameters['id'] ?? '';
          return TeacherAnalyticsScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/teacher/classes',
        builder: (context, state) => const TeacherClassesScreen(),
      ),
      GoRoute(
        path: '/teacher/classes/:id',
        builder: (context, state) {
          final classId = state.pathParameters['id'] ?? '';
          return TeacherClassDetailScreen(classId: classId);
        },
      ),
      GoRoute(
        path: '/teacher/subscription',
        builder: (context, state) => const TeacherSubscriptionScreen(),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const AdminModerationScreen(),
      ),
      GoRoute(
        path: '/admin/finance',
        builder: (context, state) => const AdminFinanceScreen(),
      ),
    ],
  );
});

