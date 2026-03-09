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
  static const _devToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiJtb25kYXkiLCJpYXQiOjE3NzMwNDg0NjIsImlzcyI6Imh0dHBzOi8vcG93ZXJzeW5jLWFwaS5qb3VybmV5YXBwcy5jb20iLCJhdWQiOiJodHRwczovLzY5YTg0NDQ0N2M0ZjhiMzA2YTE4YzEyZS5wb3dlcnN5bmMuam91cm5leWFwcHMuY29tIiwiZXhwIjoxNzczMDkxNjYyfQ.fuxnCv77g-TNI7UGJUCroynmSd7z96BkLzT8VjK-Jxb1aUb-Utif7RlTUN6ozFbVCj94bBxB9OGlyixshjid7MYgVz_i4HTCC8bxRvZISgquFLd3vD46TJ9LRL_uS6Z2rVhJkRrhEYSiU24lpDG4zFEonREoEL6UiawOCpWDdz0BQRtQXJeg36AO6mwNYZOZvR2hHpEbR0qXIo1fWWQOGEFNItD2LBs9TeI78-4aeOVAwz0EZFAp5_peMbl8e-JOIx8bTHKJmS4JjJq2jPzP2ErEOfDucqYzaIErPmz9dnER4fqlOaD17SmX4MCCFEP4V79Xj8_5eRla1C4MeS5I9w';

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
