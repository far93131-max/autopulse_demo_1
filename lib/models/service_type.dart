class ServiceType {
  final String id;
  final String userId;
  final String name;
  final String? category;
  final bool isCustom;
  final String? iconName;

  ServiceType({
    required this.id,
    required this.userId,
    required this.name,
    this.category,
    this.isCustom = false,
    this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'category': category,
        'isCustom': isCustom,
        'iconName': iconName,
      };

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
        iconName: json['iconName'] as String?,
      );
}

class ServicePart {
  final String id;
  final String name;
  final double? cost;

  ServicePart({
    required this.id,
    required this.name,
    this.cost,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cost': cost,
      };

  factory ServicePart.fromJson(Map<String, dynamic> json) => ServicePart(
        id: json['id'] as String,
        name: json['name'] as String,
        cost: json['cost'] as double?,
      );
}

