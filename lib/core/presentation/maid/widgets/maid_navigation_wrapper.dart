import 'package:flutter/material.dart';

import '../page/maid_bookings_page_old.dart';
import '../page/maid_profile_page.dart';

class MaidNavigationWrapper extends StatefulWidget {
  const MaidNavigationWrapper({super.key});

  @override
  State<MaidNavigationWrapper> createState() => _MaidNavigationWrapperState();
}

class _MaidNavigationWrapperState extends State<MaidNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MaidBookingsPage(),
    MaidProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> _titles = [
    'Bookings',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_titles[_selectedIndex]),
      //   centerTitle: true,
      // ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        //backgroundColor: Colors.teal,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal.shade500,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
