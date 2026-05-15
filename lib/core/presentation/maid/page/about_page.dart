import 'package:bookmyservice/core/presentation/admin/maid_skills_page.dart';
import 'package:bookmyservice/core/presentation/admin/services_page.dart';
import 'package:bookmyservice/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/authentication_provider.dart';
import '../../../widgets/commone_profile_page.dart';
import '../widgets/custom_drawer.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final userDetails = ref.watch(userProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "About",
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
                    title: 'Support',
                    onTap: () {},
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  SettingsTile(
                    title: 'Terms of Conditions',
                    onTap: () {},
                  ),
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  SettingsTile(
                    title: 'Legal',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.32,
          ),
          // Logout Button at Bottom
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text(
                    'Jhadu Poocha App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    'V 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
