import 'package:flutter/material.dart';

class CurrentBookingsPage extends StatelessWidget {
  const CurrentBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🖼️ Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    'assets/images/maid_bookings.jpg',
                  ), // Replace with your image path
                  fit: BoxFit.fill,
                ),
              ),
              width: 250,
              height: 250,
            ),

            const SizedBox(height: 20),

            // 📝 Text
            const Text(
              'Your current bookings will appear here',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
