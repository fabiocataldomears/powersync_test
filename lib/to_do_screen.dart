import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/core/widgets/sync_status_icon.dart';
import 'package:powersync_test/features/to_do/data/to_do_repository.dart';

class ToDoScreen extends ConsumerStatefulWidget {
  const ToDoScreen({super.key});

  @override
  ConsumerState<ToDoScreen> createState() => ToDoScreenState();
}

class ToDoScreenState extends ConsumerState<ToDoScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("To Do List"),
        actions: const [SyncStatusIcon(), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SelectionArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment
                  .topCenter, // Changed to topCenter for better list scrolling
              child: SizedBox(
                width: 350,
                child: Column(
                  children: [
                    // --- Input Section ---
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: "Enter user name...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            if (_nameController.text.isNotEmpty) {
                              ref
                                  .read(todoRepositoryProvider)
                                  .addUser(_nameController.text);
                              _nameController.clear();
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- List Section ---
                    Expanded(
                      child: usersAsync.when(
                        data: (users) => ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Card(
                              child: ListTile(
                                title: Text(user.firstName),
                                subtitle: Text(user.id),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => ref
                                      .read(todoRepositoryProvider)
                                      .deleteUser(user.id),
                                ),
                              ),
                            );
                          },
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => Center(child: Text("Error: $e")),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
