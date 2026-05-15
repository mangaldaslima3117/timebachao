import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';

final maidServiceProvider =
    StateNotifierProvider<ServiceModelNotifier, List<ServiceModel>>((ref) {
  return ServiceModelNotifier();
});

final maidServiceStreamProvider = StreamProvider<List<ServiceModel>>((ref) {
  final collection = FirebaseFirestore.instance.collection('maid_services');

  return collection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ServiceModel.fromMap(data, doc.id);
    }).toList();
  });
});

class ServiceModelNotifier extends StateNotifier<List<ServiceModel>> {
  final _collection = FirebaseFirestore.instance.collection('maid_services');

  ServiceModelNotifier() : super([]) {
    fetchServices();
  }

  Future<void> fetchServices() async {
    final snapshot = await _collection.get();
    state = snapshot.docs.map((doc) {
      final data = doc.data();
      return ServiceModel.fromMap(data, doc.id);
    }).toList();
  }

  Future<void> addService(ServiceModel service) async {
    final doc = await _collection.add(service.toMap());
    state = [...state, service.copyWith(id: doc.id)];
  }

  Future<void> updateService(ServiceModel updated) async {
    await _collection.doc(updated.id).update(updated.toMap());
    state = [
      for (final service in state)
        if (service.id == updated.id) updated else service
    ];
  }

  Future<void> deleteService(String id) async {
    await _collection.doc(id).delete();
    state = state.where((s) => s.id != id).toList();
  }
}
