import 'package:bookmyservice/models/address_model.dart';

import 'app_config_model.dart';

class AppAccountModel {
  final String appAccountId; // Firestore doc ID
  final String name; // Company or App Account Name
  final List<String>
      ownerUserId; // Google/Firebase UID of owner or any other types of user.
  final String supportEmail;
  final String supportPhone;
  final AddressModel address;
  final double platformCommissionRate;
  final String createdAt;
  final AppConfigModel appConfig;
  final double taxPercentage; // Default tax rate, can be overridden in appConfig

  AppAccountModel({
    required this.appAccountId,
    required this.name,
    required this.ownerUserId,
    required this.supportEmail,
    required this.supportPhone,
    required this.address,
    required this.platformCommissionRate,
    required this.createdAt,
    required this.appConfig,
    required this.taxPercentage,
  });

  factory AppAccountModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppAccountModel(
      appAccountId: docId,
      name: map['name'] ?? '',
      ownerUserId: List<String>.from(map['ownerUserId'] ?? []),
      supportEmail: map['supportEmail'] ?? '',
      supportPhone: map['supportPhone'] ?? '',
      address: AddressModel.fromMap(map['address'] ?? {}),
      platformCommissionRate: (map['platformCommissionRate'] ?? 0).toDouble(),
      createdAt: map['createdAt'] ?? '',
      appConfig: AppConfigModel.fromMap(map['appConfig'] ?? AppConfigModel.defaultConfig().toMap()),
      taxPercentage: (map['taxPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerUserId': ownerUserId,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
        'address': address.toMap(),
        'platformCommissionRate': platformCommissionRate,
        'createdAt': createdAt,
        'appConfig': appConfig.toMap(),
        'taxPercentage': taxPercentage,
      };

  AppAccountModel copyWith({
    String? appAccountId,
    String? name,
    List<String>? ownerUserId,
    String? supportEmail,
    String? supportPhone,
    AddressModel? address,
    double? platformCommissionRate,
    String? createdAt,
    AppConfigModel? appConfig,
    double? taxPercentage,
  }) {
    return AppAccountModel(
      appAccountId: appAccountId ?? this.appAccountId,
      name: name ?? this.name,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      address: address ?? this.address,
      platformCommissionRate:
          platformCommissionRate ?? this.platformCommissionRate,
      createdAt: createdAt ?? this.createdAt,
      appConfig: appConfig ?? this.appConfig,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }
}
