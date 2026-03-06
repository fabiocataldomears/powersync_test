import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

/// Backend connector responsible for:
///  1. Providing credentials so PowerSync can stream changes from your server.
///  2. Uploading local (offline) mutations to your backend when connectivity
///     is restored.
class AppConnector extends PowerSyncBackendConnector {
  static const _powerSyncEndpoint =
      'https://69a844447c4f8b306a18c12e.powersync.journeyapps.com';

  /// Development token gerado no PowerSync Dashboard.
  /// ⚠️  Apenas para testes — nunca use token fixo em produção.
  static const _devToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiJmcmlkYXkiLCJpYXQiOjE3NzI3OTUxMTUsImlzcyI6Imh0dHBzOi8vcG93ZXJzeW5jLWFwaS5qb3VybmV5YXBwcy5jb20iLCJhdWQiOiJodHRwczovLzY5YTg0NDQ0N2M0ZjhiMzA2YTE4YzEyZS5wb3dlcnN5bmMuam91cm5leWFwcHMuY29tIiwiZXhwIjoxNzcyODM4MzE1fQ.D7_tMVEzpWX34pxMSAGd2EHXyLC27Kiu93WJCpEeO0VFfIkNwklc7PyAvc7sSI9qBX-DJUO-E710yzoI-Z9B5bvrW5K0p_TkLJROP2nwtuR676i7c0KYkmYJ_rEcWgGxaMYqWhBIhPQBIb-O0b64pd79KGgpdXzVFE5S-M6uyeT4RrivfgOFYiH0BmBsea0ul86rilrf48-Ogy5I4n27cinMM6kSMrY-Nq9aXOp24umgxBfs0UmTqD7XQyqu35S9d1cCbHickgMYLvNcAouv9oa7KYWaHERrcaAqyCmhygkcSE0zmKGogFlNzG8-upzwkd9AZroNSe6xGVntnAe55Q';

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

        // Read-only tables managed by server-side triggers — never upload.
        const readOnlyTables = {'combined_user_data'};
        if (readOnlyTables.contains(op.table)) {
          debugPrint('[PowerSync]   skipping read-only table: ${op.table}');
          continue;
        }

        // Parse id to int because Supabase column is bigint.
        final numericId = int.tryParse(op.id) ?? op.id;

        switch (op.op) {
          case UpdateType.put:
            // INSERT or full REPLACE
            await _supabase.from(op.table).upsert({
              'id': numericId,
              ...?op.opData,
            });
          case UpdateType.patch:
            // UPDATE (partial)
            await _supabase
                .from(op.table)
                .update(op.opData!)
                .eq('id', numericId);
          case UpdateType.delete:
            await _supabase.from(op.table).delete().eq('id', numericId);
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
