// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../services/maids_provider.dart';
// import 'bookings_page.dart';

// class HomePage extends ConsumerWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final maids = ref.watch(maidAccountProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Available Maids")),
//       body: ListView.builder(
//         itemCount: maids.,
//         itemBuilder: (context, index) {
//           final maid = maids[index];
//           return Card(
//             child: ListTile(
//               title: Text(maid.name),
//               subtitle: Text(
//                   "Skills: ${maid.skills.join(', ')}\nRating: ${maid.rating}"),
//               trailing: maid.isAvailable
//                   ? ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const BookingsPage(),
//                           ),
//                         );
//                       },
//                       child: const Text("Book"),
//                     )
//                   : const Text("Unavailable",
//                       style: TextStyle(color: Colors.red)),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
