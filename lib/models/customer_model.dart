import 'package:bookmyservice/models/address_model.dart';

class CustomerModel {
  String id;
  String name;
  String email;
  String phone;
  String userId;
  String gender;
  AddressModel address;
  String appAccountId;
  String profileImageUrl = '';
   String? fcmToken;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userId,
    required this.gender,
    required this.address,
    required this.appAccountId,
    required this.profileImageUrl,
    required this.fcmToken,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userId: map['userId'] ?? '',
      gender: map['gender'] ?? '',
      address: AddressModel.fromMap(map['address'] ?? {}),
      appAccountId: map['appAccountId'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'userId': userId,
        'gender': gender,
        'address': address.toMap(),
        'appAccountId': appAccountId,
        'profileImageUrl': profileImageUrl,
        'fcmToken': fcmToken,
      };

  factory CustomerModel.getDefaultCustomer() {
    return CustomerModel(
      id: '',
      name: '',
      email: '',
      phone: '',
      userId: '',
      gender: '',
      address: AddressModel.getDefaultAddress(),
      appAccountId: '',
      profileImageUrl: '',
      fcmToken: '',
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userId,
    String? gender,
    AddressModel? address,
    String? appAccountId,
    String? profileImageUrl,
    String? fcmToken,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      appAccountId: appAccountId ?? this.appAccountId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
