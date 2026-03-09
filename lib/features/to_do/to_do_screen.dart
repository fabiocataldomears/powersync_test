import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/core/widgets/sync_status_icon.dart';
import 'package:powersync_test/features/authentication/providers/auth_provider.dart';
import 'package:powersync_test/features/repair_request/data/repair_request_repository.dart';

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
    final authState = ref.watch(authProvider);
    final userId = authState.auth0UserId;
    final requestsAsync = ref.watch(repairRequestListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Making a repair"),
        actions: const [SyncStatusIcon(), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SelectionArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
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
                              hintText: "Enter a repair request...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: userId == null
                              ? null
                              : () {
                                  if (_nameController.text.isNotEmpty) {
                                    ref
                                        .read(repairRequestRepositoryProvider)
                                        .addRepairRequest(
                                          userId,
                                          _nameController.text,
                                        );
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
                      child: requestsAsync.when(
                        data: (requests) => requests.isEmpty
                            ? const Center(
                                child: Text("No repair requests yet."),
                              )
                            : ListView.builder(
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final req = requests[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(req.description),
                                      subtitle: Text(req.status),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => ref
                                            .read(repairRequestRepositoryProvider)
                                            .deleteRepairRequest(req.id),
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

