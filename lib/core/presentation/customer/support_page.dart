import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/app_account_provider.dart';// adjust import path as needed

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(appAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support & Legal"),
      ),
      body: account == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text("Contact Support"),
                  subtitle: Text(account.supportPhone),
                  leading: const Icon(Icons.phone),
                  onTap: () {
                    // Optional: implement phone dialer
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text("Email Support"),
                  subtitle: Text(account.supportEmail),
                  leading: const Icon(Icons.email),
                  onTap: () {
                    // Optional: implement email launch
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text("Legal"),
                  leading: const Icon(Icons.gavel),
                  onTap: () {
                    // Navigate to legal page
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text("Terms and Conditions"),
                  leading: const Icon(Icons.description),
                  onTap: () {
                    // Navigate to terms and conditions page
                  },
                ),
                const Divider(),
              ],
            ),
    );
  }
}
