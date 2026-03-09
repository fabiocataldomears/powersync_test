import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/features/authentication/providers/auth_provider.dart';
import 'package:powersync_test/home_screen.dart';
import 'package:powersync_test/terms_screen.dart';
import 'package:powersync_test/to_do_screen.dart';
import 'package:powersync_test/welcome_screen.dart';
import 'package:flutter/material.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final bool isAuthenticated = authState.isAuthenticated;
      final bool isLoggingIn =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/terms';

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/welcome';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
      GoRoute(path: '/to-do', builder: (context, state) => const ToDoScreen()),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
