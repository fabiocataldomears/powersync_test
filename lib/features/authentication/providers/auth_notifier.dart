import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/features/authentication/data/auth_repository.dart';
import 'package:powersync_test/features/authentication/domain/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? auth0UserId;
  final String? userName;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.auth0UserId,
    this.userName,
  });
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
    if (hasSession) {
      final credentials = await service.getStoredCredentials();
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        auth0UserId: credentials?.user.sub,
        userName: credentials?.user.name,
      );
    } else {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> signIn() async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      final credentials = await ref.read(authServiceProvider).login();
      if (credentials != null) {
        final auth0Id = credentials.user.sub;

        // Upsert profile independently — a Supabase error must NOT prevent login.
        try {
          await ref
              .read(authRepositoryProvider)
              .upsertUser(auth0Id: auth0Id, email: credentials.user.email);
        } catch (e) {
          // Log but keep going — user is authenticated regardless.
          debugPrint('[Auth] upsertUser failed (non-fatal): $e');
          debugPrint('[Auth] auth0Id=$auth0Id email=${credentials.user.email}');
        }

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          auth0UserId: auth0Id,
          userName: credentials.user.name,
        );
      } else {
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      debugPrint('[Auth] signIn failed: $e');
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).logout();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authNotifier = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
