import 'package:bookmyservice/models/address_model.dart';
import 'package:bookmyservice/models/role_model.dart';
import 'package:bookmyservice/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _roleType = 'roleType';

  AuthService(this._auth, this._googleSignIn);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google and create user in Firestore
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 1. Save to `users` collection if not exists
        final existingUser =
            await _firestore.collection('users').doc(user.uid).get();

        if (!existingUser.exists) {
          RoleModel role = RoleModel(
            canRead: false,
            canWrite: false,
            isSuperAdmin: false,
            roleType: 'Admin',
          ); // Default role
          UserModel userModel = UserModel(
            id: user.uid,
            name: user.displayName!,
            email: user.email!,
            phone: '',
            userId: user.uid,
            gender: '',
            address: '',
            supportPhone: '',
            appAccountId: '',
            role: role,
            photoUrl: user.photoURL!,
            fcmToken: '',
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
          // await _firestore.collection('users').doc(user.uid).set({
          //   'email': user.email,
          //   'name': user.displayName,
          //   'photoUrl': user.photoURL,
          //   'createdAt': FieldValue.serverTimestamp(),
          // });
        }

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleType, 'admin'); // Store role type
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-in: $e');
      return null;
    }
  }

  // Sign in with Google and create user in Firestore
  Future<User?> signInWithGoogle_Customer() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 1. Save to `users` collection if not exists
        final existingUser =
            await _firestore.collection('customers').doc(user.uid).get();

        if (!existingUser.exists) {
          // Default role
          // CustomerModel userModel = CustomerModel(
          //   id: user.uid,
          //   name: user.displayName!,
          //   email: user.email!,
          //   phone: '',
          //   userId: user.uid,
          //   gender: '',
          //   address: AddressModel.getDefaultAddress(),
          //   appAccountId: '',
          // );

          // await _firestore
          //     .collection('customers')
          //     .doc(user.uid)
          //     .set(userModel.toMap());
          // await _firestore.collection('users').doc(user.uid).set({
          //   'email': user.email,
          //   'name': user.displayName,
          //   'photoUrl': user.photoURL,
          //   'createdAt': FieldValue.serverTimestamp(),
          // });
        }

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleType, 'customer'); // Store role type
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-in: $e');
      return null;
    }
  }

  // Sign in with Google and create customer account in Firestore
  Future<User?> createCustomerAccount(
      UserCredential? credential, String phone) async {
    try {
      final user = credential!.user;

      if (user != null) {
        // 1. Save to `users` collection if not exists
        final existingUser =
            await _firestore.collection('customers').doc(phone).get();

        if (!existingUser.exists) {
          // Default role
          CustomerModel userModel = CustomerModel(
              id: user.uid,
              name: user.displayName!,
              email: user.email!,
              phone: phone,
              userId: user.uid,
              gender: '',
              address: AddressModel.getDefaultAddress(),
              appAccountId: '',
              profileImageUrl: user.photoURL ?? '',
              fcmToken: '');

          await _firestore
              .collection('customers')
              .doc(phone)
              .set(userModel.toMap());
        }

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleType, 'customer'); // Store role type
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-in: $e');
      return null;
    }
  }

  Future<User?> getCustomerDetails(
      UserCredential? credential, String phone) async {
    try {
      final user = credential!.user;

      if (user != null) {
        // 1. Save to `users` collection if not exists
        final existingUser =
            await _firestore.collection('customers').doc(phone).get();

        if (!existingUser.exists) {
          // Default role
          CustomerModel userModel = CustomerModel(
            id: user.uid,
            name: user.displayName!,
            email: user.email!,
            phone: phone,
            userId: user.uid,
            gender: '',
            address: AddressModel.getDefaultAddress(),
            appAccountId: '',
            profileImageUrl: user.photoURL ?? '',
            fcmToken: '',
          );

          await _firestore
              .collection('customers')
              .doc(phone)
              .set(userModel.toMap());
        }

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleType, 'customer'); // Store role type
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Sign in with Google and create user in Firestore
  Future<User?> signInWithGoogleCustomer() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 1. Save to `users` collection if not exists
        final existingUser =
            await _firestore.collection('users').doc(user.uid).get();

        if (!existingUser.exists) {
          RoleModel role = RoleModel(
            canRead: false,
            canWrite: false,
            isSuperAdmin: false,
            roleType: 'Admin',
          ); // Default role
          UserModel userModel = UserModel(
            id: user.uid,
            name: user.displayName!,
            email: user.email!,
            phone: '',
            userId: user.uid,
            gender: '',
            address: '',
            supportPhone: '',
            appAccountId: '',
            role: role,
            photoUrl: user.photoURL!,
            fcmToken: '',
          );
          await createCustomerAccount(
            userCredential,
            user.phoneNumber ?? '',
          );
        }

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleType, 'admin'); // Store role type
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-in: $e');
      return null;
    }
  }
}
