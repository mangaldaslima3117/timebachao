import 'role_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userId;
  final String gender;
  final String address;
  final String supportPhone;
  final String appAccountId;
  final RoleModel role;
  final String photoUrl;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userId,
    required this.gender,
    required this.address,
    required this.supportPhone,
    required this.appAccountId,
    required this.role,
    required this.photoUrl,
    required this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      userId: map['userId'] ?? '',
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      supportPhone: map['supportPhone'] ?? '',
      appAccountId: map['appAccountId'] ?? '',
      role: RoleModel.fromMap(map['role'] ?? {}),
      photoUrl: map['photoUrl'] ?? 'https://www.example.com/default-avatar.jpg',
      fcmToken: map['fcmToken'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'userId': userId,
        'gender': gender,
        'address': address,
        'supportPhone': supportPhone,
        'appAccountId': appAccountId,
        'role': role.toMap(),
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
      };
}
