import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/features/authentication/domain/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;

  AuthState({required this.isAuthenticated, this.isLoading = false});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialSession();
    return AuthState(isAuthenticated: false, isLoading: true);
  }

  Future<void> _checkInitialSession() async {
    final service = ref.read(authServiceProvider);
    final hasSession = await service.hasValidSession();
    state = AuthState(isAuthenticated: hasSession, isLoading: false);
  }

  Future<void> signIn() async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      final credentials = await ref.read(authServiceProvider).login();
      if (credentials != null) {
        state = AuthState(isAuthenticated: true, isLoading: false);
      }
    } catch (e) {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).logout();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
