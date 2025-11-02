class Car {
  final String id;
  final String userId;
  final String? nickname;
  final String make;
  final String model;
  final int year;
  final String? licensePlate;
  final String? vin;
  final String? imageUrl;
  final int currentMileage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.userId,
    this.nickname,
    required this.make,
    required this.model,
    required this.year,
    this.licensePlate,
    this.vin,
    this.imageUrl,
    this.currentMileage = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => nickname ?? '$make $model ($year)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nickname': nickname,
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'vin': vin,
        'imageUrl': imageUrl,
        'currentMileage': currentMileage,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as String,
        userId: json['userId'] as String,
        nickname: json['nickname'] as String?,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        licensePlate: json['licensePlate'] as String?,
        vin: json['vin'] as String?,
        imageUrl: json['imageUrl'] as String?,
        currentMileage: json['currentMileage'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

