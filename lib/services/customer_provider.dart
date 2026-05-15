import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';

final customerProvider =
    StateNotifierProvider<CustomerModelNotifier, List<CustomerModel>>((ref) {
  return CustomerModelNotifier();
});

class CustomerModelNotifier extends StateNotifier<List<CustomerModel>> {
  final _collection = FirebaseFirestore.instance.collection('customers');

  CustomerModelNotifier() : super([]) {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    final snapshot = await _collection.get();
    state = snapshot.docs.map((doc) {
      final data = doc.data();
      return CustomerModel.fromMap(data, doc.id);
    }).toList();
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      // Store/update in Firestore using phone as the document ID
      await _collection.doc(customer.phone).set(customer.toMap());

      // Check if the customer already exists in local state
      final existingIndex = state.indexWhere((c) => c.phone == customer.phone);

      if (existingIndex != -1) {
        // Customer exists — update the record
        final updatedList = [...state];
        updatedList[existingIndex] = customer.copyWith(id: customer.phone);
        state = updatedList;
      } else {
        // New customer — add to the list
        state = [...state, customer.copyWith(id: customer.phone)];
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack) as List<CustomerModel>;
    }
  }

  Future<void> updateCustomer(CustomerModel updated) async {
    await _collection.doc(updated.id).update(updated.toMap());
    state = [
      for (final customer in state)
        if (customer.id == updated.id) updated else customer
    ];
  }

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
    state = state.where((s) => s.id != id).toList();
  }

  Future<CustomerModel?> getCustomerByPhoneNumber(String phone) async {
    final doc = await _collection.doc(phone).get();
    if (doc.exists) {
      return CustomerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
// Example provider to get customer name from Firestore
final customerDataProvider = FutureProvider<CustomerModel?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.phoneNumber!.substring(3))
        .get();
    if (doc.exists) {
      return CustomerModel.fromMap(doc.data()!, doc.id);
    }
  }
  return CustomerModel.getDefaultCustomer();
});
