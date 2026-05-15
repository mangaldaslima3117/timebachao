class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double minPrice;
  final double maxPrice;
  final String categoryId;
  final String categoryName;
  final String duration;
  final double discountPrice;
  final double extraPricePerDuration;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.minPrice,
    required this.maxPrice,
    required this.categoryId,
    required this.categoryName,
    required this.duration,
    required this.discountPrice,
    required this.extraPricePerDuration,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      maxPrice: (map['maxPrice'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '', // Added categoryName
      duration: map['duration'] ?? '', // Added duration
      discountPrice: (map['discountPrice'] ?? 0).toDouble(),
      extraPricePerDuration: (map['extraPricePerDuration'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'categoryId': categoryId,
      'categoryName': categoryName, // Added categoryName
      'duration': duration, // Added duration
      'discountPrice': discountPrice,
      'extraPricePerDuration': extraPricePerDuration,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? categoryName,
    String? duration,
    double? discountPrice,
    double? extraPricePerDuration,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categoryId: categoryId ??
          this.categoryId, // categoryId is not nullable in this context
      categoryName: categoryName ?? this.categoryName, // Added categoryName
      duration: duration ?? this.duration, // Added duration
      discountPrice: discountPrice ?? this.discountPrice,
      extraPricePerDuration:
          extraPricePerDuration ?? this.extraPricePerDuration,
    );
  }
}
