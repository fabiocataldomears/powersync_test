import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => WelcomeScreenState();
}

class WelcomeScreenState extends ConsumerState<WelcomeScreen> {
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
                child: Column(
                  mainAxisSize: .max,
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .center,
                  children: [
                    // Mears logo
                    // Image.asset(
                    //   Assets.images.mearsLogo.path,
                    //   width: Get.width * 0.5,
                    //   fit: BoxFit.contain,
                    // ),

                    // const SizedBox(height: 20),
                    Text("Welcome!"),

                    const SizedBox(height: 20),

                    Text("Let's get started"),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity * 0.8,
                      child: ElevatedButton(
                        child: Text("Get Started"),
                        onPressed: () => GoRouter.of(context).push("/terms"),
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
