// current_maid_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/maid_model.dart';

class CurrentMaidNotifier extends StateNotifier<MaidModel?> {
  CurrentMaidNotifier() : super(null) {
    _loadMaidFromPrefs(); // Load on startup
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _maidIdKey = 'loggedInMaidId';
  static const _roleType = 'roleType';

  Future<bool> loginWithUsernameAndPassword(
      String userName, String password) async {
    try {
      final query = await _firestore
          .collection('maids')
          .where('userName', isEqualTo: userName)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final maid = MaidModel.fromMap(query.docs.first.data(), query.docs.first.id);
        state = maid;

        // Store maid ID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_maidIdKey, maid.id);
        await prefs.setString(_roleType, 'maid'); // Store role type
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_maidIdKey);
  }

  void setMaid(MaidModel maid) => state = maid;

  void clearMaid() => state = null;

  void updatePartial({String? name, String? phone}) {
    if (state != null) {
      state = state!
          .copyWith(name: name ?? state!.name, phone: phone ?? state!.phone);
    }
  }

  Future<void> updateMaid(MaidModel updatedMaid) async {
    await _firestore
        .collection('maids')
        .doc(updatedMaid.id)
        .update(updatedMaid.toMap());
    state = updatedMaid;
  }

  Future<void> _loadMaidFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final maidId = prefs.getString(_maidIdKey);

    if (maidId != null) {
      try {
        final doc = await _firestore.collection('maids').doc(maidId).get();
        if (doc.exists) {
          final maid = MaidModel.fromMap(doc.data()!, doc.id);

          // Store maid ID in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_maidIdKey, maid.id);
          await prefs.setString(_roleType, 'maid'); // Store role type

          state = maid;
        }
      } catch (e) {
        print('Error loading maid from prefs: $e');
      }
    }
  }
}

final maidIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('loggedInMaidId'); // or your `_maidIdKey`
});

final currentMaidProvider =
    StateNotifierProvider<CurrentMaidNotifier, MaidModel?>(
  (ref) => CurrentMaidNotifier(),
);
