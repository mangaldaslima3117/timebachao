import 'package:bookmyservice/core/presentation/customer/customer_booking_page.dart';
import 'package:bookmyservice/models/booking_model.dart';
import 'package:bookmyservice/services/authentication_provider.dart';
import 'package:bookmyservice/services/bookings_provider.dart';
import 'package:bookmyservice/services/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../services/category_provider.dart';
import '../../../services/customer_provider.dart';
import '../../widgets/booking_status_card.dart';
import 'customer_profile_page.dart';

class CustomerWelcomePage extends ConsumerStatefulWidget {
  const CustomerWelcomePage({super.key});

  @override
  ConsumerState<CustomerWelcomePage> createState() =>
      _CustomerWelcomePageState();
}

class _CustomerWelcomePageState extends ConsumerState<CustomerWelcomePage> {
  String selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();

    // ref.watch(customerDataProvider).whenData((customer) async {
    //   if (customer != null && customer.id.isNotEmpty) {
    //     await NotificationService.saveAndSubscribeToken(
    //       userId: customer.id,
    //       collection: 'customers',
    //     );
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final customerNameAsync = ref.watch(customerDataProvider);
    final service = ref.watch(maidServiceProvider);
    final bookingAsync = ref.watch(bookingsProvider);
    final categoryAsync = ref.watch(categoryStreamProvider);
    final servicesAsync = ref.watch(maidServiceStreamProvider);

    ref.watch(categoryProvider);


    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: customerNameAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (customerName) => CustomScrollView(
            slivers: [
              SliverAppBar(
                leading: Container(), // Hide the back button
                title: Text(
                  'Welcome, ${customerName?.name ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                pinned: true,
                expandedHeight: 160.0,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1,
                  centerTitle: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/women-door-clean.png', // Place your generated logo here
                        height: 100,
                        //width: 80,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: const Text(
                          'Your cleanliness starts here !',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Image.asset(
                        'assets/images/women_cleaning.png', // Place your generated logo here
                        height: 100,
                        width: 120,
                      )
                    ],
                  ),
                  background: Container(
                    //color: Colors.blue.shade100,
                    //child: const Center(child: Icon(Icons.cleaning_services, size: 80)),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(
                          25,
                        ),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.account_circle_outlined),
                    onPressed: () {
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerProfilePage(),
                        ),
                      );
                    },
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.logout),
                  //   onPressed: () async {
                  //     await FirebaseAuth.instance.signOut();
                  //     Navigator.pushNamedAndRemoveUntil(
                  //         context, '/login', (route) => false);
                  //   },
                  // ),
                ],
              ),
              // const SliverToBoxAdapter(
              //   child: Center(
              //     child: Padding(
              //       padding: EdgeInsets.all(16.0),
              //       child: Text(
              //         'Here is your latest booking status:',
              //         style: TextStyle(
              //           fontSize: 14,
              //           color: Colors.grey,
              //         ), // Use headlineSmall for better scaling
              //       ),
              //     ),
              //   ),
              // ),

              // --- Latest Booking Status with "NEW" indicator ---
              const SliverToBoxAdapter(
                child: BookingStatusCard(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 8,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                  child: Text(
                    'House Cleaning Services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              // Chips for categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                  child: categoryAsync.when(
                    data: (categories) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final category = isAll
                              ? CategoryModel(id: 'all', name: 'All')
                              : categories[index - 1];

                          final isSelected = selectedCategoryId == category.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(category.name),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  selectedCategoryId = category.id;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ),
              ),
              servicesAsync.when(
                data: (services) {
                  final filteredList = selectedCategoryId == 'all'
                      ? services
                      : services
                          .where((s) => s.categoryId == selectedCategoryId)
                          .toList();

                  if (filteredList.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No services available for this category."),
                      )),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final singleService = filteredList[index];

                          double discountPercent = 0;
                          if (singleService.discountPrice > 0 &&
                              singleService.minPrice > 0 &&
                              singleService.discountPrice <
                                  singleService.minPrice) {
                            discountPercent = ((singleService.minPrice -
                                        singleService.discountPrice) /
                                    singleService.minPrice) *
                                100;
                          }

                          return GestureDetector(
                            onTap: () {},
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          singleService.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 8),
                                        singleService.discountPrice > 0
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '₹${singleService.discountPrice.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '₹${singleService.minPrice.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade400,
                                                      fontSize: 14,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      decorationColor:
                                                          Colors.red.shade600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                '₹${singleService.minPrice.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                  if (discountPercent > 0)
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade300,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${discountPercent.toStringAsFixed(0)}% OFF',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: filteredList.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3 / 2.5,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $err'),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 10,
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16,
                    ),
                    child: Text(
                      'More Services Coming Soon !',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.teal.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 50,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final customer = await ref.read(customerDetailsProvider);

              // Action for new booking
              BookingModel booking = BookingModel.getDefaultBookingModel();
              if (customer.value != null) {
                debugPrint('CUSTOMER INFO');
                debugPrint(customer.value!.toMap().toString());
                booking.customerAddress = customer.value!.address;
                booking.customerInfo = customer.value!;
              }

              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerBookingPage(),
                ),
              );
            },
            // icon: const Image(
            //   image: AssetImage(
            //       'assets/images/bookings_icon.png'), // Replace with your icon path
            //   width: 24,
            //   height: 24,
            // ),
            label: const Text(
              'Book Now',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            //backgroundColor: Colors.teal, // Optional
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 1,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
