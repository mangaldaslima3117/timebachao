import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/authentication_provider.dart';
import '../maid/maid_login_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/Time Bachao.png', // Place your generated logo here
                  height: 200,
                ),
                const SizedBox(height: 16),
                // App Name
                Text(
                  'Time Bachao',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 32),

                // Google Sign-In Button
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.login),
                //   label: const Text("Sign in with Google"),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.teal,
                //     foregroundColor: Colors.white,
                //     minimumSize: const Size.fromHeight(50),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   onPressed: () async {
                //     final result = await authService.signInWithGoogle();
                //     if (result == null) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //             content: Text("Login failed or cancelled")),
                //       );
                //     }
                //   },
                // ),
                GestureDetector(
                  onTap: () async {
                    final result = await authService.signInWithGoogle();
                    if (result == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Login failed or cancelled")),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_g.png',
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Login as Admin",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login as Maid
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MaidLoginPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Login as Maid",
                      style: TextStyle(color: Colors.teal)),
                ),

                const SizedBox(height: 10),

                // Login as Customer
                OutlinedButton(
                  onPressed: () {
                    // Functionality to be implemented
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Login as Customer",
                      style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
