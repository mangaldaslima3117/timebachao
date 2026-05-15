import 'package:bookmyservice/core/presentation/admin/maid_skills_page.dart';
import 'package:bookmyservice/core/presentation/admin/services_page.dart';
import 'package:bookmyservice/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/authentication_provider.dart';
import '../../widgets/commone_profile_page.dart';
import 'admin_slots_page.dart';
import 'app_account_page.dart';
import 'services_categories_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final userDetails = ref.watch(userProvider);

    return Scaffold(
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
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(userDetails.photoUrl),
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
                    title: 'App Details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppAccountPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  if (userDetails != null &&
                      userDetails.role.roleType.toLowerCase() == 'admin')
                    SettingsTile(
                      title: 'Services',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesPage(),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 1),
                  if (userDetails != null &&
                      userDetails.role.roleType.toLowerCase() == 'admin')
                    SettingsTile(
                      title: 'Service Categories',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServiceCategoriesPage(),
                          ),
                        );
                      },
                    ),
                  const Divider(height: 1),
                  SettingsTile(
                    title: 'Maid Skills',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MaidSkillsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SettingsTile(
                    title: 'Manage Slots',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSlotPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.06,
          ),
          // Logout Button at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Container(
                decoration: const BoxDecoration(),
                width: MediaQuery.of(context).size.width * 0.4,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () async {
                    await authService.signOut();
                    // if (context.mounted) {
                    //   Navigator.pushReplacementNamed(context, '/login');
                    // }
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
