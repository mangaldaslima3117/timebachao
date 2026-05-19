class ServiceAreaModel {
  final String id;
  final String city;
  final String areaName;
  final String cityKey;
  final String areaKey;
  final bool isServiceable;

  const ServiceAreaModel({
    required this.id,
    required this.city,
    required this.areaName,
    required this.cityKey,
    required this.areaKey,
    required this.isServiceable,
  });

  factory ServiceAreaModel.fromMap(Map<String, dynamic> map, String docId) {
    final city = (map['city'] ?? '').toString();
    final areaName = (map['areaName'] ?? '').toString();

    return ServiceAreaModel(
      id: docId,
      city: city,
      areaName: areaName,
      cityKey: (map['cityKey'] ?? normalizeKey(city)).toString(),
      areaKey: (map['areaKey'] ?? normalizeKey(areaName)).toString(),
      isServiceable:
          map['isServiceable'] is bool ? map['isServiceable'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'areaName': areaName,
      'cityKey': normalizeKey(city),
      'areaKey': normalizeKey(areaName),
      'isServiceable': isServiceable,
    };
  }

  ServiceAreaModel copyWith({
    String? id,
    String? city,
    String? areaName,
    String? cityKey,
    String? areaKey,
    bool? isServiceable,
  }) {
    final nextCity = city ?? this.city;
    final nextAreaName = areaName ?? this.areaName;

    return ServiceAreaModel(
      id: id ?? this.id,
      city: nextCity,
      areaName: nextAreaName,
      cityKey: cityKey ?? normalizeKey(nextCity),
      areaKey: areaKey ?? normalizeKey(nextAreaName),
      isServiceable: isServiceable ?? this.isServiceable,
    );
  }

  static String normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String documentIdFor(String city, String areaName) {
    return '${_slug(city)}__${_slug(areaName)}';
  }

  static bool isServiceableArea(
    List<ServiceAreaModel> areas,
    String city,
    String areaName,
  ) {
    final cityKey = normalizeKey(city);
    final areaKey = normalizeKey(areaName);

    if (cityKey.isEmpty || areaKey.isEmpty) return false;

    return areas.any(
      (area) =>
          area.cityKey == cityKey &&
          area.areaKey == areaKey &&
          area.isServiceable,
    );
  }

  static List<String> activeAreaNamesForCity(
    List<ServiceAreaModel> areas,
    String city,
  ) {
    final cityKey = normalizeKey(city);
    final activeAreas = areas
        .where((area) => area.cityKey == cityKey && area.isServiceable)
        .map((area) => area.areaName)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return activeAreas;
  }

  static String _slug(String value) {
    final normalized = normalizeKey(value);
    final slug = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    return slug.replaceAll(RegExp(r'^_|_$'), '');
  }
}
