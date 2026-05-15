import 'package:bookmyservice/core/presentation/customer/customer_details_page.dart';
import 'package:bookmyservice/core/presentation/customer/customer_login_page.dart';
import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:bookmyservice/core/widgets/app_initializer.dart';
import 'package:bookmyservice/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/presentation/admin/booking_details_page.dart';
import 'core/presentation/admin/contact_support_page.dart';
import 'core/presentation/admin/login_page.dart';
import 'core/presentation/maid/page/maid_bookings_page.dart';
import 'core/presentation/maid/services/current_maid_provider.dart';
import 'models/booking_model.dart';
import 'models/customer_model.dart';
import 'services/authentication_provider.dart';
import 'services/customer_provider.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

main() async {
  const String appConfig = 'customer'; // Change to 'admin' or 'maid' as needed
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  // Enable debug provider
  // await FirebaseAppCheck.instance.activate(
  //   // Set androidProvider to `AndroidProvider.debug`
  //   androidProvider: AndroidProvider.debug,
  //   //227e9375-b349-47bb-8d6c-63e3dd129229, 6Ld0DWUrAAAAAF1YSkjNWLh_rvHZEc9Gqaey5fup
  //   appleProvider: AppleProvider.debug,
  // );

  await NotificationService.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(settings);

  runApp(
    const ProviderScope(
      child: appConfig == AppConstants.CUSTOMER_APP ? CustomerApp() : MyApp(),
    ),
  ); // Riverpod root
}

void requestPermissionAndInitFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📥 Foreground message received: ${message.notification?.title}');
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔗 Notification clicked!');
    });
  }
}

void _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'booking_channel_mb', // channel id
    'Booking Notifications', // channel name
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alert_sound'),
    icon: '@mipmap/launcher_icon', // Notification icon
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    platformChannelSpecifics,
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Optional: handle when app is launched from terminated state
    _checkInitialMessage();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔗 Notification clicked!');
      debugPrint(
          'Message data: ${message.data}'); // Log message data for debugging
      _handleNotificationNavigation(message);
    });
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _showNotification(initialMessage);
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) async {
    final bookingId = message.data['bookingId'];
    debugPrint('🔗 Notification clicked with bookingId: $bookingId');
    if (bookingId == null) return;

    // Fetch the booking document
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (doc.exists) {
      final booking = BookingModel.fromMap(doc.data()!);

      // Navigate with the full booking model
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingDetailsPage(currentBooking: booking),
        ));
      }
    } else {
      // Optional: show error/snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final maid = ref.watch(currentMaidProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Maid Booking App',
      theme: ThemeData(primarySwatch: Colors.teal),
      //home: const AppInitializer(),
      home: authState.when(
        data: (user) {
          if (user != null) {
            // Watch appAccountProvider *only after* user is logged in
            final appAccountAsync = ref.watch(accountDetailsProvider);

            return appAccountAsync.when(
              data: (appAccount) {
                if (appAccount != null) {
                  return const AppInitializer(
                    appConfig: AppConstants.ADMIN_APP,
                  ); // ✅ App account exists
                } else {
                  return const ContactSupportPage(); // ❌ No app account
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Scaffold(
                body: Center(child: Text("Error: $e")),
              ),
            );
          } else if (maid != null && maid.appAccountId.isNotEmpty) {
            // Username/password Maid login
            return const MaidBookingsPage();
          } else {
            return const LoginPage(); // User not logged in
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text("Error: $e")),
        ),
      ),
    );
  }
}

class CustomerApp extends ConsumerStatefulWidget {
  const CustomerApp({
    Key? key,
  }) : super(key: key);
  @override
  ConsumerState<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends ConsumerState<CustomerApp> {
  @override
  void initState() {
    super.initState();

    // Optional: handle when app is launched from terminated state
    _checkInitialMessage();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔗 Notification clicked!');
      debugPrint(
          'Message data: ${message.data}'); // Log message data for debugging
      _handleNotificationNavigation(message);
    });
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _showNotification(initialMessage);
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) async {
    final bookingId = message.data['bookingId'];
    debugPrint('🔗 Notification clicked with bookingId: $bookingId');
    if (bookingId == null) return;

    // Fetch the booking document
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    if (doc.exists) {
      final booking = BookingModel.fromMap(doc.data()!);

      // Navigate with the full booking model
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingDetailsPage(currentBooking: booking),
        ));
      }
    } else {
      // Optional: show error/snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(customerDetailsProvider);
    final customerNotifier = ref.read(customerProvider.notifier);
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maid Booking App',
      theme: ThemeData(primarySwatch: Colors.teal),
      //home: const AppInitializer(),
      home: authState.when(
        data: (user) {
          debugPrint('IS USER EXIST : ${user != null}');
          if (user == null) {
            return const CustomerLoginPage();
          }

          return FutureBuilder<CustomerModel?>(
            future: ref
                .read(customerProvider.notifier)
                .getCustomerByPhoneNumber(user.phoneNumber!.substring(3)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final customer = snapshot.data;

              // If customer does not exist, add a new one
              if (customer == null || customer.id.isEmpty) {
                return CustomerDetailsPage(
                  customer: CustomerModel.getDefaultCustomer(),
                );
              }

              return const AppInitializer(appConfig: AppConstants.CUSTOMER_APP);
            },
          );
          // if (user != null) {
          //   return const AppInitializer(
          //     appConfig: AppConstants.CUSTOMER_APP,
          //   );
          // } else {
          //   // Username/password Maid login
          //   return const CustomerLoginPage();
          // }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text("Error: $e")),
        ),
      ),
    );
  }
}
