class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double mrpPrice;       // Shown as strikethrough  e.g. ₹699
  final double sellingPrice;   // Actual base price       e.g. ₹300
  final String categoryId;
  final String categoryName;
  final String duration;
  final double extraPricePerDuration;

  // Property counts
  final int numberOfBeds;
  final int numberOfKitchens;
  final int numberOfBalconies;
  final int numberOfFamilyMembers;

  // Per-unit prices
  final double pricePerBed;
  final double pricePerKitchen;
  final double pricePerBalcony;
  final double pricePerFamilyMember;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.mrpPrice,
    required this.sellingPrice,
    required this.categoryId,
    required this.categoryName,
    required this.duration,
    required this.extraPricePerDuration,
    this.numberOfBeds = 0,
    this.numberOfKitchens = 0,
    this.numberOfBalconies = 0,
    this.numberOfFamilyMembers = 0,
    this.pricePerBed = 0.0,
    this.pricePerKitchen = 0.0,
    this.pricePerBalcony = 0.0,
    this.pricePerFamilyMember = 0.0,
  });

  /// Property additions on top of sellingPrice
  double get propertyTotal =>
      (numberOfBeds * pricePerBed) +
      (numberOfKitchens * pricePerKitchen) +
      (numberOfBalconies * pricePerBalcony) +
      (numberOfFamilyMembers * pricePerFamilyMember);

  /// Final price customer pays = sellingPrice + all property costs
  double get finalPrice {
    final total = sellingPrice + propertyTotal;
    return total < 0 ? 0 : total;
  }

  /// True when there's a visible discount to show
  bool get hasDiscount => mrpPrice > sellingPrice;

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      // Support old field names (minPrice/discountPrice) for existing Firestore docs
      mrpPrice: (map['mrpPrice'] ?? map['minPrice'] ?? 0).toDouble(),
      sellingPrice:
          (map['sellingPrice'] ?? map['discountPrice'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      duration: map['duration'] ?? '',
      extraPricePerDuration: (map['extraPricePerDuration'] ?? 0).toDouble(),
      numberOfBeds: (map['numberOfBeds'] ?? 0).toInt(),
      numberOfKitchens: (map['numberOfKitchens'] ?? 0).toInt(),
      numberOfBalconies: (map['numberOfBalconies'] ?? 0).toInt(),
      numberOfFamilyMembers: (map['numberOfFamilyMembers'] ?? 0).toInt(),
      pricePerBed: (map['pricePerBed'] ?? 0).toDouble(),
      pricePerKitchen: (map['pricePerKitchen'] ?? 0).toDouble(),
      pricePerBalcony: (map['pricePerBalcony'] ?? 0).toDouble(),
      pricePerFamilyMember: (map['pricePerFamilyMember'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'mrpPrice': mrpPrice,
      'sellingPrice': sellingPrice,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'duration': duration,
      'extraPricePerDuration': extraPricePerDuration,
      'numberOfBeds': numberOfBeds,
      'numberOfKitchens': numberOfKitchens,
      'numberOfBalconies': numberOfBalconies,
      'numberOfFamilyMembers': numberOfFamilyMembers,
      'pricePerBed': pricePerBed,
      'pricePerKitchen': pricePerKitchen,
      'pricePerBalcony': pricePerBalcony,
      'pricePerFamilyMember': pricePerFamilyMember,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? mrpPrice,
    double? sellingPrice,
    String? categoryId,
    String? categoryName,
    String? duration,
    double? extraPricePerDuration,
    int? numberOfBeds,
    int? numberOfKitchens,
    int? numberOfBalconies,
    int? numberOfFamilyMembers,
    double? pricePerBed,
    double? pricePerKitchen,
    double? pricePerBalcony,
    double? pricePerFamilyMember,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mrpPrice: mrpPrice ?? this.mrpPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      duration: duration ?? this.duration,
      extraPricePerDuration:
          extraPricePerDuration ?? this.extraPricePerDuration,
      numberOfBeds: numberOfBeds ?? this.numberOfBeds,
      numberOfKitchens: numberOfKitchens ?? this.numberOfKitchens,
      numberOfBalconies: numberOfBalconies ?? this.numberOfBalconies,
      numberOfFamilyMembers:
          numberOfFamilyMembers ?? this.numberOfFamilyMembers,
      pricePerBed: pricePerBed ?? this.pricePerBed,
      pricePerKitchen: pricePerKitchen ?? this.pricePerKitchen,
      pricePerBalcony: pricePerBalcony ?? this.pricePerBalcony,
      pricePerFamilyMember: pricePerFamilyMember ?? this.pricePerFamilyMember,
    );
  }
}