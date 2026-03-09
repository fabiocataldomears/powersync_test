import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'connector.dart';
import 'schema.dart';

/// Global PowerSync database instance — initialized once at app start.
late PowerSyncDatabase db;

Future<void> openPowerSyncDatabase() async {
  debugPrint('[DB] openPowerSyncDatabase() called');

  late final String dbPath;
  try {
    debugPrint('[DB] Resolving application documents directory...');
    final docsDir = await getApplicationDocumentsDirectory();
    dbPath = join(docsDir.path, 'powersync_users.db');
    debugPrint('[DB] Database path: $dbPath');
  } catch (e, st) {
    debugPrint('[DB] ERROR resolving documents directory: $e\n$st');
    rethrow;
  }

  try {
    debugPrint('[DB] Creating PowerSyncDatabase instance...');
    db = PowerSyncDatabase(schema: schema, path: dbPath);
    debugPrint('[DB] Calling db.initialize()...');
    await db.initialize();
    debugPrint('[DB] db.initialize() completed successfully');
  } catch (e, st) {
    debugPrint('[DB] ERROR during database initialization: $e\n$st');
    rethrow;
  }

  db = PowerSyncDatabase(schema: schema, path: dbPath);
  await db.initialize();
  _connectInBackground();
}

void _connectInBackground() {
  debugPrint('[PowerSync] Starting background connection...');
  db
      .connect(connector: AppConnector())
      .then((_) {
        debugPrint('[PowerSync] connect() resolved');
      })
      .catchError((e) {
        debugPrint('[PowerSync] connect() error (offline mode active): $e');
      });

  // Log sync status changes
  db.statusStream.listen((status) {
    debugPrint(
      '[PowerSync] Status changed — '
      'connected: ${status.connected}, '
      'lastSyncedAt: ${status.lastSyncedAt}, '
      'hasSynced: ${status.hasSynced}',
    );
  });
}

final dbProvider = Provider<PowerSyncDatabase>((ref) {
  return db;
});
