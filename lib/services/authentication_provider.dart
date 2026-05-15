import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_account_model.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider for fetching user details
final userDetailsProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      return UserModel.fromMap(userDoc.data()!, userDoc.id);
    }
  }
  throw Exception('User not found');
});

// Provider for fetching app account details
final accountDetailsProvider =
    FutureProvider.autoDispose<AppAccountModel?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  debugPrint('Current user: ${user?.uid}');
  if (user != null) {
    debugPrint('Fetching app account for user: ${user.uid}');
    final appAccountDoc = await FirebaseFirestore.instance
        .collection('app_accounts')
        .where('ownerUserId', arrayContains: user.uid)
        .limit(1)
        .get();
    debugPrint('App account document: ${appAccountDoc.docs}');
    if (appAccountDoc.docs.isNotEmpty) {
      return AppAccountModel.fromMap(
          appAccountDoc.docs.first.data(), appAccountDoc.docs.first.id);
    }
  }
  return null;
});

//Provider for current CUSTOMER DETAILS
// Provider for fetching user details
final customerDetailsProvider = StreamProvider<CustomerModel>((ref) {
  final user = FirebaseAuth.instance.currentUser!;
  final trimmedPhone = user.phoneNumber!.substring(3);

  return FirebaseFirestore.instance
      .collection('customers')
      .doc(trimmedPhone)
      .snapshots()
      .map((doc) => CustomerModel.fromMap(doc.data()!, doc.id));
});
