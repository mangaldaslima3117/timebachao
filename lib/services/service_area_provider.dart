import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_area_model.dart';

final serviceAreaProvider = StateNotifierProvider<ServiceAreaNotifier,
    AsyncValue<List<ServiceAreaModel>>>((ref) {
  return ServiceAreaNotifier();
});

class ServiceAreaNotifier
    extends StateNotifier<AsyncValue<List<ServiceAreaModel>>> {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('service_areas');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  ServiceAreaNotifier() : super(const AsyncValue.loading()) {
    _watchServiceAreas();
  }

  void _watchServiceAreas() {
    _subscription = _collection.snapshots().listen((snapshot) {
      final areas = snapshot.docs
          .map((doc) => ServiceAreaModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) {
          final cityCompare =
              a.cityKey.toLowerCase().compareTo(b.cityKey.toLowerCase());
          if (cityCompare != 0) return cityCompare;
          return a.areaKey.toLowerCase().compareTo(b.areaKey.toLowerCase());
        });

      state = AsyncValue.data(areas);
    }, onError: (Object error, StackTrace stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<void> addOrUpdateServiceArea(
    ServiceAreaModel area, {
    String? previousId,
  }) async {
    try {
      final docId = ServiceAreaModel.documentIdFor(area.city, area.areaName);
      final docRef = _collection.doc(docId);
      final doc = await docRef.get();
      final payload = area.copyWith(id: docId).toMap()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      if (!doc.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));

      if (previousId != null && previousId.isNotEmpty && previousId != docId) {
        await _collection.doc(previousId).delete();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleServiceable(
    ServiceAreaModel area,
    bool isServiceable,
  ) async {
    try {
      final docId = area.id.isNotEmpty
          ? area.id
          : ServiceAreaModel.documentIdFor(area.city, area.areaName);

      await _collection.doc(docId).update({
        'isServiceable': isServiceable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteServiceArea(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  bool isAreaServiceable(String city, String areaName) {
    final areas = state.valueOrNull ?? [];
    return ServiceAreaModel.isServiceableArea(areas, city, areaName);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
