import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync_test/features/authentication/providers/auth_notifier.dart';
import 'package:powersync_test/features/to_do/to_do_screen.dart';
import 'package:powersync_test/home_screen.dart';
import 'package:powersync_test/terms_screen.dart';
import 'package:powersync_test/welcome_screen.dart';

/// A [ChangeNotifier] that bridges Riverpod auth state into a [Listenable]
/// for [GoRouter.refreshListenable]. The router re-runs its redirect logic
/// every time [notifyListeners] is called.
class _RouterNotifier extends ChangeNotifier {
  AuthState _authState;

  _RouterNotifier(this._authState);

  void update(AuthState newState) {
    _authState = newState;
    notifyListeners();
  }

  bool get isLoading => _authState.isLoading;
  bool get isAuthenticated => _authState.isAuthenticated;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  final notifier = _RouterNotifier(ref.read(authNotifier));
  ref.listen<AuthState>(authNotifier, (_, next) => notifier.update(next));
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      if (notifier.isLoading) return null;

      final bool isAuthenticated = notifier.isAuthenticated;
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
