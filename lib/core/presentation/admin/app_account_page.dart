import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/address_model.dart';
import '../../../services/app_account_provider.dart';
import '../../widgets/edit_address_dialog.dart';

class AppAccountPage extends ConsumerWidget {
  const AppAccountPage({super.key});

  Future<void> _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter new $title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  _showEditAddressDialog(
      BuildContext context, WidgetRef ref, AddressModel currentAddress) {
    showDialog(
      context: context,
      builder: (context) => EditAddressDialog(
        initialAddress: currentAddress,
        onSave: (updatedAddress) {
          final currentAccount = ref.read(appAccountProvider);
          if (currentAccount != null) {
            ref.read(appAccountProvider.notifier).updateAccountFields(
                  name: currentAccount.name,
                  address: updatedAddress,
                  supportEmail: currentAccount.supportEmail,
                  supportPhone: currentAccount.supportPhone,
                );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(appAccountProvider);
    final notifier = ref.read(appAccountProvider.notifier);

    if (account == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Account Details")),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _editableField(
            label: 'App Name',
            value: account.name,
            onTap: () => _showEditDialog(
              context: context,
              title: 'Name',
              initialValue: account.name,
              onSave: (newValue) {
                notifier.updateAccountFields(
                  name: newValue,
                  address: account.address,
                  supportEmail: account.supportEmail, // updated
                  supportPhone: account.supportPhone,
                );
              },
            ),
          ),
          _editableField(
            label: 'Support Email',
            value: account.supportEmail,
            onTap: () => _showEditDialog(
              context: context,
              title: 'Email',
              initialValue: account.supportEmail,
              onSave: (newValue) {
                notifier.updateAccountFields(
                  name: account.name,
                  address: account.address,
                  supportEmail: newValue, // updated
                  supportPhone: account.supportPhone,
                );
              },
            ),
          ),
          _editableField(
            label: 'Support Phone',
            value: account.supportPhone,
            onTap: () => _showEditDialog(
              context: context,
              title: 'Support Phone',
              initialValue: account.supportPhone,
              onSave: (newValue) {
                notifier.updateAccountFields(
                  name: account.name,
                  address: account.address,
                  supportEmail: account.supportEmail, // updated
                  supportPhone: newValue,
                );
              },
            ),
          ),
          _editableField(
            label: 'Company Address',
            value: account.address
                .toString(), // Add a method in AddressModel for display
            onTap: () => _showEditAddressDialog(context, ref, account.address),
          ),
          // _editableField(
          //   label: 'Address',
          //   value: account.address,
          //   onTap: () => _showEditDialog(
          //     context: context,
          //     title: 'Address',
          //     initialValue: account.address,
          //     onSave: (newValue) {
          //       notifier.updateAccountFields(
          //         name: account.name,
          //         address: newValue,
          //         supportEmail: account.supportEmail, // updated
          //         supportPhone: account.address,
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _editableField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onTap,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
