import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/maid_model.dart';

class MaidListNotifier extends StateNotifier<List<MaidModel>> {
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription? _subscription;

  MaidListNotifier() : super([]) {
    _subscribeToMaids();
    fetchMaidList();
  }

  void _subscribeToMaids() {
    _subscription =
        _firestore.collection('maids').snapshots().listen((snapshot) {
      state =
          snapshot.docs.map((doc) => MaidModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchMaidList() async {
    final snapshot = await _firestore.collection('maids').get();
    state = snapshot.docs.map((doc) => MaidModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> addMaid(MaidModel maid) async {
    final doc = await _firestore.collection('maids').add(maid.toMap());
    state = [...state, maid.copyWith(id: doc.id)];
  }

  Future<void> deleteMaid(String id) async {
    await _firestore.collection('maids').doc(id).delete();
    state = state.where((s) => s.id != id).toList();
  }

  Future<void> updateMaid(MaidModel updatedMaid) async {
    await _firestore
        .collection('maids')
        .doc(updatedMaid.id)
        .update(updatedMaid.toMap());
    state = [
      for (final maid in state)
        if (maid.id == updatedMaid.id) updatedMaid else maid
    ];
  }

  Future<void> updateMaidSkills(MaidModel maidData, List<String> skills) async {
    await _firestore
        .collection('maids')
        .doc(maidData.id)
        .update({'skills': skills});

    final updatedMaid = maidData.copyWith(skills: skills);
    state = [
      for (final maid in state)
        if (maid.id == updatedMaid.id) updatedMaid else maid
    ];
  }

  // Future<void> refreshList() async {
  //   state = const AsyncValue.loading();
  //   state = AsyncValue.data(await fetchMaidList());
  // }

  Future<void> updateMaidAvailability(String maidId, bool status) async {
    await _firestore
        .collection('maids')
        .doc(maidId)
        .update({'isAvailable': status});
    state = [
      for (final maid in state)
        if (maid.id == maidId) maid.copyWith(isAvailable: status) else maid
    ];
  }

  Future<bool> login(String username, String password) async {
    try {
      final query = await _firestore
          .collection('maids')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final maid = MaidModel.fromMap(query.docs.first.data(), query.docs.first.id);
        state = [maid];
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }
}

final maidAccountProvider =
    StateNotifierProvider<MaidListNotifier, List<MaidModel>>((ref) {
  return MaidListNotifier();
});
