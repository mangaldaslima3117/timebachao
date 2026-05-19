import 'package:bookmyservice/core/presentation/customer/customer_booking_page.dart';
import 'package:bookmyservice/models/booking_model.dart';
import 'package:bookmyservice/services/bookings_provider.dart';
import 'package:bookmyservice/services/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../services/authentication_provider.dart';
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

class _CustomerWelcomePageState extends ConsumerState<CustomerWelcomePage>
    with SingleTickerProviderStateMixin {
  String selectedCategoryId = 'all';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onBookNow() async {
    try {
      final customer = await ref.read(customerDetailsProvider.future);
      if (!mounted) return;

      BookingModel booking = BookingModel.getDefaultBookingModel();
      if (customer != null) {
        booking.customerAddress = customer.address;
        booking.customerInfo = customer;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerBookingPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  bool _isOutsideServiceArea(String? address) {
    if (address == null || address.trim().isEmpty) return false;
    return !address.toLowerCase().contains('bhubaneswar');
  }

  String _extractCity(String? address) {
    if (address == null || address.trim().isEmpty) return 'your city';
    final parts = address.split(',');
    if (parts.length >= 2) return parts[parts.length - 2].trim();
    return address.trim();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤️';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final customerNameAsync = ref.watch(customerDataProvider);
    final categoryAsync = ref.watch(categoryStreamProvider);
    final servicesAsync = ref.watch(maidServiceStreamProvider);
    ref.watch(categoryProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: customerNameAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B))),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (customer) {
            final address = customer?.address?.toString() ?? '';
            final outsideBbsr = _isOutsideServiceArea(address);

            return CustomScrollView(
              slivers: [
                // ── SliverAppBar ─────────────────────────────────────────
                // KEY CHANGE: title + actions live in the TOOLBAR (toolbarHeight: 56).
                // Because pinned: true, the toolbar NEVER scrolls away.
                // FlexibleSpaceBar holds only the greeting/tagline content,
                // which gracefully collapses. Location chip + avatar stay put.
                SliverAppBar(
                  leading: const SizedBox.shrink(),
                  automaticallyImplyLeading: false,
                  pinned: true,
                  toolbarHeight: 56,
                  expandedHeight: 240,
                  backgroundColor: const Color(0xFF00695C),
                  surfaceTintColor: const Color(0xFF00695C),
                  elevation: 0,
                  shadowColor: Colors.transparent,

                  // ── Location chip — always visible ─────────────────────
                  title: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerProfilePage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        //mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: Color(0xFF80CBC4)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              address.isEmpty
                                  ? 'Set location'
                                  : address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  titleSpacing: 16,

                  // ── Profile avatar — always visible ────────────────────
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerProfilePage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Colors.white.withOpacity(0.2),
                            child: Text(
                              (customer?.name?.isNotEmpty == true)
                                  ? customer!.name[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Expanded hero — collapses on scroll ────────────────
                  flexibleSpace: FlexibleSpaceBar(
                    expandedTitleScale: 1,
                    collapseMode: CollapseMode.pin,
                    background: _HeroExpandedContent(
                      customer: customer,
                      greeting: _greeting(),
                    ),
                  ),
                ),

                // ── Coming Soon Banner (non-Bhubaneswar) ─────────────────
                if (outsideBbsr)
                  SliverToBoxAdapter(
                    child: _ComingSoonBanner(
                        city: _extractCity(address)),
                  ),

                // ── Booking Status Card ───────────────────────────────────
                const SliverToBoxAdapter(
                  child: BookingStatusCard(),
                ),

                // ── Section title ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Our Services',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2E2B),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tap to explore',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Category Chips ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: categoryAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categories) => ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final category = isAll
                              ? CategoryModel(id: 'all', name: 'All')
                              : categories[index - 1];
                          final isSelected =
                              selectedCategoryId == category.id;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: ChoiceChip(
                                label: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1A2E2B),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF00897B),
                                backgroundColor: Colors.white,
                                elevation: isSelected ? 2 : 0,
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF00897B)
                                      : Colors.grey.shade300,
                                ),
                                onSelected: (_) => setState(
                                  () => selectedCategoryId = category.id,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // ── Service Grid ──────────────────────────────────────────
                servicesAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: Color(0xFF00897B)),
                      ),
                    ),
                  ),
                  error: (err, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: $err'),
                      ),
                    ),
                  ),
                  data: (services) {
                    final filteredList = selectedCategoryId == 'all'
                        ? services
                        : services
                            .where(
                                (s) => s.categoryId == selectedCategoryId)
                            .toList();

                    if (filteredList.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.cleaning_services_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No services in this category yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final svc = filteredList[index];
                            final discountPercent = svc.hasDiscount
                                ? ((svc.mrpPrice - svc.sellingPrice) /
                                        svc.mrpPrice *
                                        100)
                                    .round()
                                : 0;

                            return _ServiceCard(
                              svc: svc,
                              discountPercent: discountPercent,
                            );
                          },
                          childCount: filteredList.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 3.6,
                        ),
                      ),
                    );
                  },
                ),

                // ── Coming Soon Footer ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00897B).withOpacity(0.08),
                            const Color(0xFF00BCD4).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                const Color(0xFF00897B).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'More Services Coming Soon!',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF00695C),
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),

        // ── Book Now FAB ──────────────────────────────────────────────────
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00ACC1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _onBookNow,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 20),
            label: const Text(
              'Book Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Expanded Content
// Only visible when SliverAppBar is NOT fully collapsed.
// Does NOT contain location/profile — those live in the persistent toolbar above.
// Top padding of 64 (= toolbarHeight 56 + 8) ensures content sits
// below the toolbar area and is not occluded.
// ─────────────────────────────────────────────────────────────────────────────
class _HeroExpandedContent extends StatelessWidget {
  final dynamic customer;
  final String greeting;

  const _HeroExpandedContent({
    required this.customer,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 50,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Content starts below: status bar + toolbar (56) + 8px gap.
          // Using Builder to access MediaQuery here inside the Stack.
          Builder(builder: (ctx) {
            final topOffset = MediaQuery.of(ctx).padding.top + 56.0 + 8.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(18, topOffset, 18, 16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + name
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer?.name ?? 'Guest',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline card
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF80CBC4).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🏠',
                            style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A Cleaner Home Awaits!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Trusted professionals at your doorstep',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xBFFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating badge
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  '4.9',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '200+ happy\ncustomers',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          }), // end Builder
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coming Soon Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ComingSoonBanner extends StatelessWidget {
  final String city;

  const _ComingSoonBanner({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC02).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🚀', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coming Soon to $city!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'We\'re expanding! Services will be available in your area soon.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBF360C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Card
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final dynamic svc;
  final int discountPercent;

  const _ServiceCard({required this.svc, required this.discountPercent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildServiceImage(),
                ),

                // Info area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          svc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF1A2E2B),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (svc.hasDiscount) ...[
                                    Text(
                                      '₹${svc.mrpPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        decorationColor:
                                            Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      '₹${svc.finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '₹${svc.finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF00695C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Discount badge
            if (discountPercent > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    '$discountPercent% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceImage() {
    // Uncomment when your service model has imageUrl:
    // final imageUrl = svc.imageUrl as String?;
    // if (imageUrl != null && imageUrl.isNotEmpty) {
    //   return Image.network(
    //     imageUrl,
    //     height: 95,
    //     width: double.infinity,
    //     fit: BoxFit.cover,
    //     errorBuilder: (_, __, ___) => _imagePlaceholder(),
    //   );
    // }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 95,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00897B).withOpacity(0.12),
            const Color(0xFF00BCD4).withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.cleaning_services_rounded,
          color: Color(0xB300897B),
          size: 32,
        ),
      ),
    );
  }
}