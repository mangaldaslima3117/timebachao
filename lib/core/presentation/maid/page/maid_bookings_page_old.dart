import 'package:bookmyservice/core/presentation/maid/page/past_bookings_page.dart';
import 'package:flutter/material.dart';

import 'current_bookings_page.dart';

class MaidBookingsPage extends StatelessWidget {
  const MaidBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: Container(),
          title: const Text(
            'Bookings',
            style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'Past',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: const TabBarView(
          children: [
            CurrentBookingsPage(),
            PastBookingsPage(),
          ],
        ),
        // body: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       // 🖼️ Image
        //       Container(
        //         decoration: const BoxDecoration(
        //           image: DecorationImage(
        //             image: const AssetImage(
        //               'assets/images/maid_bookings.jpg',
        //             ), // Replace with your image path
        //             fit: BoxFit.fill,
        //           ),
        //         ),
        //         width: 250,
        //         height: 250,
        //       ),

        //       const SizedBox(height: 20),

        //       // 📝 Text
        //       const Text(
        //         'Your bookings will appear here',
        //         style: TextStyle(
        //           fontSize: 20,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.teal,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
