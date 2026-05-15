import 'package:bookmyservice/models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_account_model.dart';

final appAccountProvider =
    NotifierProvider<AppAccountNotifier, AppAccountModel?>(
        AppAccountNotifier.new);

class AppAccountNotifier extends Notifier<AppAccountModel?> {
  @override
  AppAccountModel? build() {
    _loadAccount(); // load data
    _loadAccountCustomer(); // load data for customer app
    return null;
  }

  //This is for admin app to fetch the account details
  Future<void> _loadAccount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('app_accounts')
        .where('ownerUserId', arrayContains: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      state = AppAccountModel.fromMap(doc.data(), doc.id);
    }
  }

  // This is for customer app to fetch the account details
  Future<void> _loadAccountCustomer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('app_accounts')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      state = AppAccountModel.fromMap(doc.data(), doc.id);
    }
  }

  Future<void> updateAccountFields({
    required String name,
    required AddressModel address,
    required String supportEmail,
    required String supportPhone,
  }) async {
    if (state == null) return;

    final docId = state!.appAccountId;

    await FirebaseFirestore.instance
        .collection('app_accounts')
        .doc(docId)
        .update({
      'name': name,
      'address': address.toMap(),
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
    });

    await _loadAccount(); // reload updated data
  }

  Future<void> updateConfigDetail(AppAccountModel appAccount) async {
    await FirebaseFirestore.instance
        .collection('app_accounts')
        .doc(appAccount.appAccountId)
        .update({
      'appConfig': appAccount.appConfig.toMap(),
    });

    await _loadAccount(); // reload updated data
  }
}
