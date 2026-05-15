import 'address_model.dart';

class MaidModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userId;
  final String gender;
  final AddressModel address;
  final List<String> skills;
  final double totalEarnings;
  final double commissionPercentage;
  bool isAvailable;
  final String appAccountId;

  final String? aadharNumber;
  final String? panNumber;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final String? bankName;
  final String? bankBranch;
  final String? bankAccountHolderName;
  final String? profilePictureUrl;
  final String? userName;
  final String? password;
  final String? createdAt;
  final String? fcmToken;

  MaidModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userId,
    required this.gender,
    required this.address,
    required this.skills,
    required this.totalEarnings,
    required this.commissionPercentage,
    required this.isAvailable,
    required this.appAccountId,
    this.aadharNumber,
    this.panNumber,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.bankName,
    this.bankBranch,
    this.bankAccountHolderName,
    this.profilePictureUrl,
    this.userName,
    this.password,
    this.createdAt,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userId': userId,
      'gender': gender,
      'address': address.toMap(),
      'skills': skills,
      'totalEarnings': totalEarnings,
      'commissionPercentage': commissionPercentage,
      'isAvailable': isAvailable,
      'appAccountId': appAccountId,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'bankAccountNumber': bankAccountNumber,
      'bankIfscCode': bankIfscCode,
      'bankName': bankName,
      'bankBranch': bankBranch,
      'bankAccountHolderName': bankAccountHolderName,
      'profilePictureUrl': profilePictureUrl,
      'userName': userName,
      'password': password,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
    };
  }

  factory MaidModel.fromMap(Map<String, dynamic> map, String id) {
    return MaidModel(
      id: id,
      name: map.containsKey('name') ? map['name'] ?? '' : '',
      email: map.containsKey('email') ? map['email'] ?? '' : '',
      phone: map.containsKey('phone') ? map['phone'] ?? '' : '',
      userId: map.containsKey('userId') ? map['userId'] ?? '' : '',
      gender: map.containsKey('gender') ? map['gender'] ?? '' : '',
      address: map.containsKey('address')
          ? AddressModel.fromMap(map['address'] ?? {})
          : AddressModel.getDefaultAddress(), // Ensure you have an `empty()` constructor
      skills: map.containsKey('skills') ? List<String>.from(map['skills']) : [],
      totalEarnings: map.containsKey('totalEarnings')
          ? (map['totalEarnings'] ?? 0).toDouble()
          : 0.0,
      commissionPercentage: map.containsKey('commissionPercentage')
          ? (map['commissionPercentage'] ?? 0).toDouble()
          : 0.0,
      isAvailable:
          map.containsKey('isAvailable') ? map['isAvailable'] ?? false : false,
      appAccountId:
          map.containsKey('appAccountId') ? map['appAccountId'] ?? '' : '',
      aadharNumber:
          map.containsKey('aadharNumber') ? map['aadharNumber'] ?? '' : '',
      panNumber: map.containsKey('panNumber') ? map['panNumber'] ?? '' : '',
      bankAccountNumber: map.containsKey('bankAccountNumber')
          ? map['bankAccountNumber'] ?? ''
          : '',
      bankIfscCode:
          map.containsKey('bankIfscCode') ? map['bankIfscCode'] ?? '' : '',
      bankName: map.containsKey('bankName') ? map['bankName'] ?? '' : '',
      bankBranch: map.containsKey('bankBranch') ? map['bankBranch'] ?? '' : '',
      bankAccountHolderName: map.containsKey('bankAccountHolderName')
          ? map['bankAccountHolderName'] ?? ''
          : '',
      profilePictureUrl: map.containsKey('profilePictureUrl')
          ? map['profilePictureUrl'] ?? ''
          : '',
      userName: map.containsKey('userName') ? map['userName'] ?? '' : '',
      password: map.containsKey('password') ? map['password'] ?? '' : '',
      createdAt: map.containsKey('createdAt') ? map['createdAt'] ?? '' : '',
      fcmToken: map.containsKey('fcmToken') ? map['fcmToken'] ?? '' : '',
    );
  }

  MaidModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userId,
    String? gender,
    AddressModel? address,
    List<String>? skills,
    double? totalEarnings,
    double? commissionPercentage,
    bool? isAvailable,
    String? appAccountId,
    String? aadharNumber,
    String? panNumber,
    String? bankAccountNumber,
    String? bankIfscCode,
    String? bankName,
    String? bankBranch,
    String? bankAccountHolderName,
    String? profilePictureUrl,
    String? userName,
    String? password,
    String? createdAt,
    String? fcmToken,
  }) {
    return MaidModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      skills: skills ?? this.skills,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      isAvailable: isAvailable ?? this.isAvailable,
      appAccountId: appAccountId ?? this.appAccountId,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      panNumber: panNumber ?? this.panNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      userName: userName ?? this.userName,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory MaidModel.getDefaultMaid() {
    return MaidModel(
      id: '',
      name: '',
      email: '',
      phone: '',
      userId: '',
      gender: '',
      address: AddressModel.getDefaultAddress(),
      skills: [],
      totalEarnings: 0,
      commissionPercentage: 0,
      isAvailable: false,
      appAccountId: '',
      aadharNumber: '',
      panNumber: '',
      bankAccountNumber: '',
      bankIfscCode: '',
      bankName: '',
      bankBranch: '',
      bankAccountHolderName: '',
      profilePictureUrl: '',
      userName: '',
      password: '',
      createdAt: '',
      fcmToken: '',
    );
  }
}
