import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _supabase => Supabase.instance.client;

/// Backend connector responsible for:
///  1. Providing credentials so PowerSync can stream changes from your server.
///  2. Uploading local (offline) mutations to your backend when connectivity
///     is restored.
class AppConnector extends PowerSyncBackendConnector {
  static const _powerSyncEndpoint =
      'https://69a844447c4f8b306a18c12e.powersync.journeyapps.com';

  /// Development token gerado no PowerSync Dashboard.
  static const _devToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiJtb25kYXkgdG9rZW4iLCJpYXQiOjE3NzMwNTg0NTYsImlzcyI6Imh0dHBzOi8vcG93ZXJzeW5jLWFwaS5qb3VybmV5YXBwcy5jb20iLCJhdWQiOiJodHRwczovLzY5YTg0NDQ0N2M0ZjhiMzA2YTE4YzEyZS5wb3dlcnN5bmMuam91cm5leWFwcHMuY29tIiwiZXhwIjoxNzczMTAxNjU2fQ.NFS8aarwt63-FCh1d2qjTN06EVrFKFfbqI50iLxuDLoVfh-qNl7S9wJNo26Wn6oyWsdNCAlnT4c2KMLcQMe--lGsvUSBEnS9PgaH3lfSfX-Ny15rD0d_aEO6Pgo4YIiHqkg_HQAtpUpKrKxphpsIN1ZEHsdwtTfjaoY7hy5iO8QRXMsaUbMIsL49igeWQqzLG1IKWO5o-lhFhb0RTI-3O0oI7_gJb-m3yWNLuO9PbKlVG6K8F2E0ORjcF-roaQEr1e0Ztc_JcuQk9RPZlSYSSbs5GpseC5BWkXFTfAu2CuMrz9wsVIdYJmeJerAJ3pzgTJdeeGPStUQ92zvMuvqTHQ';

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    return PowerSyncCredentials(
      endpoint: _powerSyncEndpoint,
      token: _devToken,
    );
  }

  /// Sends local mutations (INSERT/UPDATE/DELETE) to Supabase.
  /// Called automatically by PowerSync whenever the device is online
  /// and there are pending local changes.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    debugPrint('[PowerSync] uploadData — ${transaction.crud.length} operation(s):');

    try {
      for (final op in transaction.crud) {
        debugPrint('[PowerSync]   op=${op.op.name} table=${op.table} id=${op.id} data=${op.opData}');

        // Read-only tables managed by server-side triggers or direct Supabase
        // writes — PowerSync must never upload changes for these.
        const readOnlyTables = {'users', 'combined_user_and_repair', 'combined_user_data'};
        if (readOnlyTables.contains(op.table)) {
          debugPrint('[PowerSync]   skipping read-only table: ${op.table}');
          continue;
        }

        // All remaining writable tables (e.g. repair_request) use UUID/text PKs.
        final id = op.id;

        switch (op.op) {
          case UpdateType.put:
            // INSERT or full REPLACE
            await _supabase.from(op.table).upsert({
              'id': id,
              ...?op.opData,
            });
          case UpdateType.patch:
            // UPDATE (partial)
            await _supabase
                .from(op.table)
                .update(op.opData!)
                .eq('id', id);
          case UpdateType.delete:
            await _supabase.from(op.table).delete().eq('id', id);
        }
      }

      await transaction.complete();
      debugPrint('[PowerSync] uploadData — transaction sent to Supabase ✓');
    } catch (e, st) {
      debugPrint('[PowerSync] uploadData ERROR — will retry: $e\n$st');
      // Do NOT call transaction.complete() on error — PowerSync will keep
      // the transaction in the queue and retry automatically.
      rethrow;
    }
  }
}
