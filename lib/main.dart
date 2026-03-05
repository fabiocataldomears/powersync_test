import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'database/powersync.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cioieazmebjgoqcwpntm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpb2llYXptZWJqZ29xY3dwbnRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1MzUxMDcsImV4cCI6MjA4ODExMTEwN30.8IPJj34L3g8zOchfF8vuz8w0RSwzzRaR25rEAawSuN4',
  );

  await openDatabase();
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerSync Users',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UsersPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users CRUD page
// ─────────────────────────────────────────────────────────────────────────────

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final Stream<List<UserModel>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = db
        .watch('''
          SELECT
            u.id,
            u.first_name,
            u.created_at,
            u.user_id,
            c.favorite_color
          FROM users u
          LEFT JOIN combined_user_data c ON c.user_id = u.user_id
          ORDER BY u.first_name
        ''')
        .map((result) {
      debugPrint('[DB] _watchUsers — ${result.rows.length} row(s) found');
      return result.rows.map((row) {
        final map = Map<String, dynamic>.fromIterables(result.columnNames, row);
        return UserModel.fromRow(map);
      }).toList();
    });
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> _addUser(String name) async {
    // Use millisecond timestamp as id — compatible with Supabase bigint columns.
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final userId = const Uuid().v4(); // proper UUID for the user_id column
    await db.execute(
      'INSERT INTO users (id, first_name, created_at, user_id) VALUES (?, ?, ?, ?)',
      [id, name.trim(), createdAt, userId],
    );
  }

  Future<void> _updateUser(String id, String newName) async {
    await db.execute(
      'UPDATE users SET first_name = ? WHERE id = ?',
      [newName.trim(), id],
    );
  }

  Future<void> _deleteUser(String id) async {
    await db.execute('DELETE FROM users WHERE id = ?', [id]);
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showNameDialog(
    BuildContext context, {
    String? existingName,
    required Future<void> Function(String name) onConfirm,
  }) async {
    final controller = TextEditingController(text: existingName);
    final isEdit = existingName != null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit name' : 'New user'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name ',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(ctx).pop();
            await onConfirm(name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              await onConfirm(name);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Users'),
        actions: [
          _SyncStatusIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('[DB] StreamBuilder error: ${snapshot.error}\n${snapshot.stackTrace}');
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No users yet.\nTap + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return Dismissible(
                key: ValueKey(user.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm deletion'),
                      content: Text(
                          'Remove "${user.name}"? This action will be synchronized.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => _deleteUser(user.id),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorFromName(user.favoriteColor),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    user.favoriteColor != null
                        ? 'Favorite color: ${user.favoriteColor}'
                        : 'ID: ${user.id.substring(0, 8)}…',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit name',
                    onPressed: () => _showNameDialog(
                      context,
                      existingName: user.name,
                      onConfirm: (name) => _updateUser(user.id, name),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add user',
        onPressed: () => _showNameDialog(
          context,
          onConfirm: _addUser,
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync status indicator (top-right corner of AppBar)
// ─────────────────────────────────────────────────────────────────────────────

Color _colorFromName(String? name) {
  switch (name?.toLowerCase()) {
    case 'red':    return Colors.red;
    case 'blue':   return Colors.blue;
    case 'green':  return Colors.green;
    case 'yellow': return Colors.yellow.shade700;
    case 'purple': return Colors.purple;
    case 'orange': return Colors.orange;
    case 'pink':   return Colors.pink;
    default:       return Colors.deepPurple;
  }
}

class _SyncStatusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: db.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final connected = status?.connected ?? false;
        final hasPending = status?.hasSynced == false;

        return Tooltip(
          message: connected
              ? (hasPending ? 'Synchronizing…' : 'Synchronized')
              : 'Offline – changes saved locally',
          child: Icon(
            connected
                ? (hasPending ? Icons.sync : Icons.cloud_done_outlined)
                : Icons.cloud_off_outlined,
            color: connected ? Colors.green : Colors.orange,
          ),
        );
      },
    );
  }
}
