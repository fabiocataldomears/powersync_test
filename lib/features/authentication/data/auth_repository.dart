import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  final Ref ref;
  AuthRepository(this.ref);
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref));
