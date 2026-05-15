import 'package:bookmyservice/core/presentation/maid/services/current_maid_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../maid_login_page.dart';
import '../page/about_page.dart';
import '../page/maid_bookings_page.dart';
import '../page/maid_earnings_page.dart';
import '../page/maid_profile_page.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentMaidProvider);

    return Drawer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MaidProfilePage(),
                  ),
                );
              },
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Container(
                  decoration: const BoxDecoration(),
                  width: double.infinity,
                  child: user != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (user.profilePictureUrl != null)
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    NetworkImage(user.profilePictureUrl!),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              user.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            ListTile(
              leading: Image.asset(
                'assets/images/bookings_icon.png', // Ensure this is in your assets folder
                width: 24,
                height: 24,
              ),
              title: const Text('Bookings'),
              onTap: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (_) => const MaidBookingsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Image.asset(
                'assets/images/inr_image.png', // Ensure this is in your assets folder
                width: 24,
                height: 24,
              ),
              title: const Text(
                'Earnings',
              ),
              onTap: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MaidEarningsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.info,
                color: Colors.teal,
              ),
              title: const Text('About'),
              onTap: () {
                Navigator.pushReplacement(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text('Logout'),
              onTap: () {
                ref.read(currentMaidProvider.notifier).logout();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MaidLoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
