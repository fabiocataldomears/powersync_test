import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync_test/features/authentication/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added an AppBar for a cleaner look, though buttons are in the body as requested
      appBar: AppBar(title: const Text("Home")),
      body: SafeArea(
        child: SelectionArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // Stretch for uniform buttons
                  children: [
                    const Text(
                      "Welcome!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      onPressed: () => GoRouter.of(context).push('/to-do'),
                      icon: const Icon(Icons.list_alt),
                      label: const Text("To Do's Test"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () {
                        // Trigger the logout logic in your provider
                        ref.read(authProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Log Out"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        foregroundColor: Colors.red,
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
