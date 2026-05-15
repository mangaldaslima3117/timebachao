import 'package:bookmyservice/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider =
    StateNotifierProvider<CategoryModelNotifier, List<CategoryModel>>((ref) {
  return CategoryModelNotifier();
});

class CategoryModelNotifier extends StateNotifier<List<CategoryModel>> {
  final _collection =
      FirebaseFirestore.instance.collection('service_categories');

  CategoryModelNotifier() : super([]) {
    fetchServiceCategories();
  }

  Future<void> fetchServiceCategories() async {
    final snapshot = await _collection.get();
    state = snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryModel.fromMap(data, doc.id);
    }).toList();
  }

  Future<void> addCategory(CategoryModel service) async {
    final doc = await _collection.add(service.toMap());
    state = [...state, service.copyWith(id: doc.id)];
  }

  Future<void> updateCategory(CategoryModel updated) async {
    await _collection.doc(updated.id).update(updated.toMap());
    state = [
      for (final service in state)
        if (service.id == updated.id) updated else service
    ];
  }

  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
    state = state.where((s) => s.id != id).toList();
  }
}

final categoryStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final collection =
      FirebaseFirestore.instance.collection('service_categories');

  return collection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryModel.fromMap(data, doc.id);
    }).toList();
  });
});
