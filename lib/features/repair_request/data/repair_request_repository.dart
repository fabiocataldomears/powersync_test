import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync_test/core/database/powersync.dart';
import 'package:powersync_test/features/authentication/providers/auth_provider.dart';
import 'package:powersync_test/features/repair_request/domain/repair_request_model.dart';
import 'package:uuid/uuid.dart';

class RepairRequestRepository {
  final PowerSyncDatabase _db;
  RepairRequestRepository(this._db);

  Stream<List<RepairRequestModel>> watchRepairRequests(String userId) {
    return _db
        .watch(
          'SELECT * FROM repair_request WHERE user_id = ? ORDER BY created_at DESC',
          parameters: [userId],
        )
        .map((result) => result.rows.map((row) {
              final map = Map<String, dynamic>.fromIterables(
                result.columnNames,
                row,
              );
              return RepairRequestModel.fromRow(map);
            }).toList());
  }

  Future<void> addRepairRequest(String userId, String description) async {
    final id = const Uuid().v4();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    await _db.execute(
      'INSERT INTO repair_request (id, user_id, description, status, created_at) VALUES (?, ?, ?, ?, ?)',
      [id, userId, description.trim(), 'pending', createdAt],
    );
  }

  Future<void> deleteRepairRequest(String id) async {
    await _db.execute('DELETE FROM repair_request WHERE id = ?', [id]);
  }
}

final repairRequestRepositoryProvider = Provider<RepairRequestRepository>(
  (ref) => RepairRequestRepository(ref.watch(dbProvider)),
);

/// Reactive stream of repair requests for the currently logged-in user.
/// Emits an empty list when no user is authenticated.
final repairRequestListProvider =
    StreamProvider<List<RepairRequestModel>>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.auth0UserId));
  if (userId == null) return const Stream.empty();
  return ref.read(repairRequestRepositoryProvider).watchRepairRequests(userId);
});
