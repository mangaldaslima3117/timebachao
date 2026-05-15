// UserNotifier to cache user details
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart' show UserModel;

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
    // Optionally, you can load user details immediately upon initialization
    loadUserDetails();
  }

  Future<void> loadUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        state = UserModel.fromMap(userDoc.data()!, userDoc.id);
      }
    }
  }
}

// StateNotifierProvider for user details
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});
