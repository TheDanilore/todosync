// lib/data/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final String color;
  
  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
  
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      color: map['color'],
    );
  }
}