import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final Ref ref;
  AuthRepository(this.ref);

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Creates or updates a record in the 'users' table using the Auth0 user_id.
  /// The Supabase 'id' is auto-generated; 'user_id' is the unique Auth0 sub.
  Future<void> upsertUser({
    required String auth0Id,
    String? email,
  }) async {
    await _supabase.from('users').upsert(
      {
        'user_id': auth0Id,
        'user_email': email,
      },
      onConflict: 'user_id',
    );
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref));
