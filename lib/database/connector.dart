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
  static const _devToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InBvd2Vyc3luYy1kZXYtMzIyM2Q0ZTMifQ.eyJzdWIiOiIwNTAzIiwiaWF0IjoxNzcyNzAxMTE1LCJpc3MiOiJodHRwczovL3Bvd2Vyc3luYy1hcGkuam91cm5leWFwcHMuY29tIiwiYXVkIjoiaHR0cHM6Ly82OWE4NDQ0NDdjNGY4YjMwNmExOGMxMmUucG93ZXJzeW5jLmpvdXJuZXlhcHBzLmNvbSIsImV4cCI6MTc3Mjc0NDMxNX0.aMvAR7ohlkzyYTGpr6Du7wQMtBdk5CZWfYFgiu9a0ZI_LWvvFb_NZGik6jKR11DIHjv8s8x_cs01RY14V-6I0nre1f5KV5Bi25LBdheZODsAF3NPAnnJq8fgT9a1Ilc9v3aocp9e-zv9iDrRN_K8bx2mXrcKe48CIbY8nIVTVwxzH-rB-z3grgaLciX7iNB463Y4V2AwFXOalcIv5fE-hQzZlJBblBAuzPzUO6FLYQK30ItZ0D5aZBPSsz8eHjEsv2u-vkhmcsyurm4kpBdxWTY077MNPMqooxCkXGsNDyCW3BnRB5kXXPCEHmU2T_A9LvfCTGjHek7MSPs_71XjMA';

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
