import 'package:bookmyservice/core/presentation/customer/customer_login_page.dart';
import 'package:bookmyservice/models/customer_model.dart';
import 'package:bookmyservice/services/bookings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/authentication_provider.dart';
import '../../../services/customer_provider.dart';
import 'customer_booking_history_page.dart';
import 'customer_details_page.dart';
import 'support_page.dart';

class CustomerProfilePage extends ConsumerWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser!;
    final customerAsync = ref.watch(customerDetailsProvider);
    final authService = ref.watch(authServiceProvider);
    ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.teal,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            25,
          ),
        ),
        // actions: [
        //   // IconButton(
        //   //   icon: const Icon(
        //   //     Icons.edit,
        //   //     color: Colors.white,
        //   //   ),
        //   //   onPressed: () {
        //   //     // TODO: Navigate to edit profile page
        //   //     ScaffoldMessenger.of(context).showSnackBar(
        //   //       const SnackBar(content: Text('Edit profile coming soon...')),
        //   //     );
        //   //   },
        //   // )
        // ],
      ),
      body: FutureBuilder<CustomerModel?>(
        future: ref
            .read(customerProvider.notifier)
            .getCustomerByPhoneNumber(user.phoneNumber!.substring(3)),
        builder: (context, snapshot) {
          final customer = snapshot.data;

          if (customer == null || customer.id.isEmpty) {
            return Container();
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _buildProfileCard(context, customer),
                //const SizedBox(height: 20),
                // const Text(
                //   "Booking History",
                //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 10),
                Card(
                  //color: Colors.grey.shade50,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'My Bookings',
                      style: TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerBookingHistoryPage(
                            customer: customer,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  //color: Colors.grey.shade50,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text(
                      'Support',
                      style: TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportPage(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.12,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Container(
                      decoration: const BoxDecoration(),
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          //backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(
                              width: 1,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          await authService.signOut();
                          // if (context.mounted) {
                          //   Navigator.pushReplacementNamed(context, '/login');
                          // }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CustomerLoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     // TODO: Implement actual support or chat
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('Contacting support...')),
                //     );
                //   },
                //   icon: const Icon(Icons.support_agent),
                //   label: const Text("Contact Support"),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.teal,
                //     foregroundColor: Colors.white,
                //     padding: const EdgeInsets.symmetric(vertical: 14),
                //   ),
                // )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, CustomerModel customer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.teal.shade300,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CustomerDetailsPage(
                        customer: customer,
                      ),
                    ),
                  );
                },
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal.shade100,
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              customer.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(customer.phone),
            Text(customer.email),
            const Divider(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Address : ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                        '${customer.address.houseNumber}, ${customer.address.areaName}, ${customer.address.landmark}, ${customer.address.city}, ${customer.address.state}, ${customer.address.pinCode}, ${customer.address.country}'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
