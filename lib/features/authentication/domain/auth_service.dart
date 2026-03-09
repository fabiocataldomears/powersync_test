import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final Auth0 _auth0;

  static const String domain = 'mearsenable.uk.auth0.com';
  static const String clientId = '2dDG26BF5h09ARM4GKM0kkR0UlR3BfBb';

  AuthService() : _auth0 = Auth0(domain, clientId);

  CredentialsManager get _credentialsManager => _auth0.credentialsManager;

  Future<Credentials?> login() async {
    return await _auth0.webAuthentication(scheme: 'myapp').login();
  }

  Future<void> logout() async {
    await _credentialsManager.clearCredentials();
    await _auth0.webAuthentication(scheme: 'myapp').logout();
  }

  Future<bool> hasValidSession() async {
    return await _credentialsManager.hasValidCredentials();
  }
}

final authServiceProvider = Provider((ref) => AuthService());
