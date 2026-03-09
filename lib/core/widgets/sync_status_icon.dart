import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync_test/features/to_do/data/to_do_repository.dart';

class SyncStatusIcon extends ConsumerWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);

    return statusAsync.maybeWhen(
      data: (status) {
        final connected = status.connected;
        return Icon(
          connected ? Icons.cloud_done : Icons.cloud_off,
          color: connected ? Colors.green : Colors.orange,
        );
      },
      orElse: () => const Icon(Icons.sync, color: Colors.grey),
    );
  }
}
