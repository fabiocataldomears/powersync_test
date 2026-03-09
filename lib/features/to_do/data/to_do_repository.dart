import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync_test/core/database/powersync.dart';
import 'package:powersync_test/features/to_do/domain/user_model.dart';
import 'package:uuid/uuid.dart';

class TodoRepository {
  final PowerSyncDatabase _db;
  TodoRepository(this._db);

  // The reactive stream of users/todos
  Stream<List<UserModel>> watchUsers() {
    return _db
        .watch('''
      SELECT 
        u.id, u.first_name, u.created_at, u.user_id, 
        c.favorite_color 
      FROM users u
      LEFT JOIN combined_user_data c ON c.user_id = u.user_id
      ORDER BY u.first_name
    ''')
        .map((result) {
          return result.rows.map((row) {
            final map = Map<String, dynamic>.fromIterables(
              result.columnNames,
              row,
            );
            return UserModel.fromRow(map);
          }).toList();
        });
  }

  Future<void> addUser(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final userId = const Uuid().v4();
    await _db.execute(
      'INSERT INTO users (id, first_name, created_at, user_id) VALUES (?, ?, ?, ?)',
      [id, name.trim(), createdAt, userId],
    );
  }

  Future<void> updateUser(String id, String newName) async {
    await _db.execute('UPDATE users SET first_name = ? WHERE id = ?', [
      newName.trim(),
      id,
    ]);
  }

  Future<void> deleteUser(String id) async {
    await _db.execute('DELETE FROM users WHERE id = ?', [id]);
  }

  // Expose the sync status stream
  Stream<SyncStatus> watchStatus() => _db.statusStream;
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  // We watch the dbProvider we just created above
  final database = ref.watch(dbProvider);
  return TodoRepository(database);
});

final todoListProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(todoRepositoryProvider).watchUsers();
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(todoRepositoryProvider).watchStatus();
});
