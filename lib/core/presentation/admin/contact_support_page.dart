import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/authentication_provider.dart';

class ContactSupportPage extends ConsumerWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 80, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text(
                      "This email is not associated with any app.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.email ?? "Unknown Email",
                      style: const TextStyle(fontSize: 16, color: Colors.teal),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "If you believe this is an error, please contact support for assistance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    // ElevatedButton.icon(
                    //   onPressed: () {
                    //     _sendSupportEmail(user?.email);
                    //   },
                    //   icon: const Icon(Icons.email),
                    //   label: const Text("Contact Support"),
                    // ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, top: 10),
              child: Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _sendSupportEmail(String? email) async {
  //   final Uri emailUri = Uri(
  //     scheme: 'mailto',
  //     path: 'support@yourapp.com',
  //     queryParameters: {
  //       'subject': 'App Account Association Issue',
  //       'body':
  //           'Hello,\n\nMy email ($email) is not linked to any app account. Please assist.\n\nThanks.'
  //     },
  //   );

  //   if (await canLaunchUrl(emailUri)) {
  //     await launchUrl(emailUri);
  //   } else {
  //     throw 'Could not launch email client.';
  //   }
  // }
}
