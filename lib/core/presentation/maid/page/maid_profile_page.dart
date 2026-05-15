import 'package:bookmyservice/core/presentation/maid/services/current_maid_provider.dart';
import 'package:bookmyservice/core/presentation/maid/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/authentication_provider.dart';
import '../../../widgets/commone_profile_page.dart';
import '../widgets/maids_account_widget.dart';

class MaidProfilePage extends ConsumerWidget {
  const MaidProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(authServiceProvider);
    final userDetails = ref.watch(currentMaidProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // App Info Section\

          if (userDetails != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (userDetails.profilePictureUrl != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        NetworkImage(userDetails.profilePictureUrl!),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Name: ${userDetails.name}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Email: ${userDetails.email}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                // Text(
                //   'Account Created: ${userDetails.?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                //   style: const TextStyle(fontSize: 16),
                // ),
              ],
            ),
          // const Expanded(
          //   child: Padding(
          //     padding: EdgeInsets.all(24.0),
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Text(
          //           "Welcome to Time Bachao App !",
          //           style: TextStyle(
          //             fontSize: 20,
          //             fontWeight: FontWeight.bold,
          //           ),
          //           textAlign: TextAlign.center,
          //         ),
          //         SizedBox(height: 16),
          //         Text(
          //           "Your trusted maid & cleaning services app.\nEasily connect with professionals around you.",
          //           style: TextStyle(fontSize: 16),
          //           textAlign: TextAlign.center,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SettingsTile(
                    title: 'Account Details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MaidsAccountWidget(
                            maid: userDetails,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // SettingsTile(
                  //   title: 'Maid Skills',
                  //   onTap: () {
                  //     // Navigator.push(
                  //     //   context,
                  //     //   MaterialPageRoute(
                  //     //     builder: (_) => const MaidSkillsPage(),
                  //     //   ),
                  //     // );
                  //   },
                  // ),
                ],
              ),
            ),
          ),

          // Logout Button at Bottom
        ],
      ),
    );
  }
}
