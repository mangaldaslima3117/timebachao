import 'package:bookmyservice/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final skillProvider =
    StateNotifierProvider<SkillNotifier, List<CategoryModel>>((ref) {
  return SkillNotifier();
});

class SkillNotifier extends StateNotifier<List<CategoryModel>> {
  final _collection = FirebaseFirestore.instance.collection('skills');

  SkillNotifier() : super([]) {
    fetchServiceSkills();
  }

  Future<void> fetchServiceSkills() async {
    final snapshot = await _collection.get();
    state = snapshot.docs.map((doc) {
      final data = doc.data();
      return CategoryModel.fromMap(data, doc.id);
    }).toList();
  }

  Future<void> addSkill(CategoryModel service) async {
    final doc = await _collection.add(service.toMap());
    state = [...state, service.copyWith(id: doc.id)];
  }

  Future<void> updateSkill(CategoryModel updated) async {
    await _collection.doc(updated.id).update(updated.toMap());
    state = [
      for (final service in state)
        if (service.id == updated.id) updated else service
    ];
  }

  Future<void> deleteSkill(String id) async {
    await _collection.doc(id).delete();
    state = state.where((s) => s.id != id).toList();
  }
}
