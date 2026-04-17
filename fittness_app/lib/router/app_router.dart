import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/register_screen.dart';
import '../screens/scheda_detail_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final status = auth.status;
        final loc = state.matchedLocation;
        final onSplash = loc == '/';
        final onAuthPage = loc == '/login' || loc == '/register';

        if (status == AuthStatus.unknown) return onSplash ? null : '/';
        if (status == AuthStatus.unauthenticated) {
          return onAuthPage ? null : '/login';
        }
        if (status == AuthStatus.authenticated && (onSplash || onAuthPage)) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (ctx, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (ctx, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (ctx, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'quiz',
              builder: (ctx, state) => const QuizScreen(),
            ),
            GoRoute(
              path: 'scheda/:id',
              builder: (ctx, state) => SchedaDetailScreen(
                id: int.parse(state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: 'profile',
              builder: (ctx, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (ctx, state) => Scaffold(
        body: Center(child: Text('Errore: ${state.error}')),
      ),
    );
  }
}

extension RouterCtx on BuildContext {
  AuthProvider get authProvider => read<AuthProvider>();
}
