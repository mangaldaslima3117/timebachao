// models/address_model.dart

class AddressModel {
  static const String defaultState = 'Odisha';
  static const String defaultCountry = 'India';

  String houseNumber;
  String areaName;
  String landmark;
  String city;
  String pinCode;
  String state;
  String country;

  AddressModel({
    required this.houseNumber,
    required this.areaName,
    required this.landmark,
    required this.city,
    required this.pinCode,
    required this.state,
    required this.country,
  });

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'areaName': areaName,
      'landmark': landmark,
      'city': city,
      'pinCode': pinCode,
      'state': state,
      'country': country,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      houseNumber: map['houseNumber'] ?? '',
      areaName: map['areaName'] ?? '',
      landmark: map['landmark'] ?? '',
      city: map['city'] ?? '',
      pinCode: map['pinCode'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
    );
  }

  @override
  String toString() {
    return "$houseNumber, $areaName, $landmark, $city, $state, $pinCode, $country";
  }

  AddressModel copyWith({
    String? houseNumber,
    String? areaName,
    String? landmark,
    String? city,
    String? pinCode,
    String? state,
    String? country,
  }) {
    return AddressModel(
      houseNumber: houseNumber ?? this.houseNumber,
      areaName: areaName ?? this.areaName,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  factory AddressModel.getDefaultAddress() {
    return AddressModel(
      houseNumber: '',
      areaName: '',
      landmark: '',
      city: '',
      pinCode: '',
      state: defaultState,
      country: defaultCountry,
    );
  }
}
