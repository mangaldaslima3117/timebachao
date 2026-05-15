import 'package:flutter/material.dart';

class BookingNotFoundWidget extends StatelessWidget {
  const BookingNotFoundWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.2),
            // 🖼️ Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    'assets/images/cleaning home page.jpg',
                  ), // Replace with your image path
                  fit: BoxFit.fill,
                ),
              ),
              width: 200,
              height: 200,
            ),
    
            const SizedBox(height: 20),
    
            // 📝 Text
            const Text(
              'Your Bookings will appear here',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      );
  }
}