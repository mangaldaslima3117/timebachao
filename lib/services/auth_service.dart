import 'package:bookmyservice/models/address_model.dart';
import 'package:bookmyservice/models/role_model.dart';
import 'package:bookmyservice/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _roleType = 'roleType';

  // Max retries for Firestore writes
  static const int _maxRetries = 3;

  AuthService(this._auth, this._googleSignIn);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retries a Firestore operation with exponential backoff
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        attempt++;
        debugPrint(
            'Firestore attempt $attempt failed: ${e.code} - ${e.message}');
        if (attempt >= _maxRetries || e.code != 'unavailable') {
          rethrow; // Don't retry non-transient errors
        }
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) throw Exception('Firebase Auth returned null user');

    // Check if user already exists in Firestore
    final existingUser =
        await _firestore.collection('users').doc(user.uid).get();

    if (!existingUser.exists) {
      final role = RoleModel(
        canRead: true,
        canWrite: true,
        isSuperAdmin: false,
        roleType: 'Admin',
      );

      final userModel = UserModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: '',
        userId: user.uid,
        gender: '',
        address: '',
        supportPhone: '',
        appAccountId: '',
        role: role,
        photoUrl: user.photoURL ?? '',
        fcmToken: '',
      );

      debugPrint("Firebase user: ${FirebaseAuth.instance.currentUser?.uid}");
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      debugPrint('Admin user created: ${user.uid}');
    } else {
      debugPrint('Admin user already exists: ${user.uid}');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleType, 'admin');

    return user;
  }

  Future<User?> signInWithGoogle_Customer() async {
    // Use injected _googleSignIn, not a new GoogleSignIn() instance
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) throw Exception('Firebase Auth returned null user');

    final existingCustomer = await _withRetry(
      () => _firestore.collection('customers').doc(user.uid).get(),
    );

    if (!existingCustomer.exists) {
      final customerModel = CustomerModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: '',
        userId: user.uid,
        gender: '',
        address: AddressModel.getDefaultAddress(),
        appAccountId: '',
        profileImageUrl: user.photoURL ?? '',
        fcmToken: '',
      );

      await _withRetry(
        () => _firestore
            .collection('customers')
            .doc(user.uid)
            .set(customerModel.toMap()),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleType, 'customer');

    return user;
  }

  Future<User?> createCustomerAccount(
      UserCredential credential, String phone) async {
    final user = credential.user;
    if (user == null) throw Exception('Credential has no user');

    final existingCustomer = await _withRetry(
      () => _firestore.collection('customers').doc(phone).get(),
    );

    if (!existingCustomer.exists) {
      final customerModel = CustomerModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: phone,
        userId: user.uid,
        gender: '',
        address: AddressModel.getDefaultAddress(),
        appAccountId: '',
        profileImageUrl: user.photoURL ?? '',
        fcmToken: '',
      );

      await _withRetry(
        () => _firestore
            .collection('customers')
            .doc(phone)
            .set(customerModel.toMap()),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleType, 'customer');

    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
