class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(id: docId, name: map['name'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  CategoryModel copyWith({String? id, String? name, String? icon}) {
    return CategoryModel(id: id ?? this.id, name: name ?? this.name);
  }
}
