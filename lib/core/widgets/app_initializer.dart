import 'package:bookmyservice/core/presentation/customer/customer_welcome_page.dart';
import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:bookmyservice/core/widgets/navigation_wrapper.dart';
import 'package:bookmyservice/services/customer_provider.dart';
import 'package:bookmyservice/services/service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_account_provider.dart';
import '../../services/authentication_provider.dart';
import '../../services/bookings_provider.dart';
import '../../services/maids_provider.dart';
import '../../services/notification_service.dart';
import '../../services/user_provider.dart';

class AppInitializer extends ConsumerStatefulWidget {
  final String appConfig;
  const AppInitializer({Key? key, required this.appConfig}) : super(key: key);
  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(maidServiceProvider);
    final maids = ref.watch(maidAccountProvider);
    final authState = ref.watch(authStateProvider);
    final bookings = ref.watch(bookingsProvider);
    final userDetails = ref.watch(userProvider);
    final customerData = ref.watch(customerDataProvider);
    final appAccount = ref.watch(appAccountProvider);

    final isLoading = services.isEmpty &&
        maids.isEmpty &&
        authState.isLoading &&
        bookings.isLoading;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.teal,
          ),
        ),
      );
    }

    if (widget.appConfig != AppConstants.CUSTOMER_APP) {
      saveFCMToken(userDetails?.id ?? '', 'users');
    }

    if (widget.appConfig == AppConstants.CUSTOMER_APP) {
      debugPrint("Customer App Config Detected");
      customerData.whenData(
        (customer) {
          if (customer != null) {
            debugPrint("customer data found, saving FCM token");
            // Navigate to customer details page if no customer data exists
            saveFCMToken(customer.id, 'customers');
          }
        },
      );
    }

    return widget.appConfig == AppConstants.ADMIN_APP
        ? const NavigationWrapper()
        : const CustomerWelcomePage();
  }

  saveFCMToken(String adminId, String collection) async {
    // Implement your FCM token saving logic here
    // This is just a placeholder function
    debugPrint("FCM Token saved for $adminId in collection: $collection");
    if (adminId.isNotEmpty) {
      await NotificationService.saveAndSubscribeToken(
        userId: adminId,
        collection: collection,
      );
    }
  }
}
