import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync_test/features/authentication/providers/auth_provider.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => TermsScreenState();
}

class TermsScreenState extends ConsumerState<TermsScreen> {
  final ScrollController termsScrollController = ScrollController();
  bool hasScrolledToBottomOfTerms = false;

  @override
  void initState() {
    super.initState();
    termsScrollController.addListener(_checkScrollPosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialScrollCheck();
  }

  void _initialScrollCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (termsScrollController.hasClients) {
        if (termsScrollController.position.maxScrollExtent <= 0) {
          setState(() {
            hasScrolledToBottomOfTerms = true;
          });
        }
      }
    });
  }

  void _checkScrollPosition() {
    if (termsScrollController.position.pixels >=
        termsScrollController.position.maxScrollExtent - 50) {
      setState(() {
        hasScrolledToBottomOfTerms = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SelectionArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 350,
                child: SingleChildScrollView(
                  controller: termsScrollController,
                  child: Column(
                    mainAxisSize: .max,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .center,
                    children: [
                      Text("Terms and Conditions"),

                      const SizedBox(height: 20),

                      Text("Please review and accept our terms to continue."),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity * 0.8,
                        child: ElevatedButton(
                          onPressed: hasScrolledToBottomOfTerms
                              ? () => ref.read(authProvider.notifier).signIn()
                              : null,
                          child: const Text("Accept Terms"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity * 0.8,
                        child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: Text("Decline"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
