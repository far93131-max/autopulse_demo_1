import 'service_type.dart';

enum ServiceStatus {
  ok,
  dueSoon,
  due,
  overdue,
}

class MaintenanceLog {
  final String id;
  final String carId;
  final String serviceTypeId;
  final ServiceType? serviceType;
  final int mileage;
  final DateTime dateOfService;
  final double? cost;
  final String? mechanicName;
  final String? notes;
  final String? receiptUrl;
  final List<ServicePart> parts;
  final DateTime createdAt;

  MaintenanceLog({
    required this.id,
    required this.carId,
    required this.serviceTypeId,
    this.serviceType,
    required this.mileage,
    required this.dateOfService,
    this.cost,
    this.mechanicName,
    this.notes,
    this.receiptUrl,
    this.parts = const [],
    required this.createdAt,
  });

  double get totalCost {
    final serviceCost = cost ?? 0.0;
    final partsCost = parts.fold(0.0, (sum, part) => sum + (part.cost ?? 0.0));
    return serviceCost + partsCost;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carId': carId,
        'serviceTypeId': serviceTypeId,
        'mileage': mileage,
        'dateOfService': dateOfService.toIso8601String(),
        'cost': cost,
        'mechanicName': mechanicName,
        'notes': notes,
        'receiptUrl': receiptUrl,
        'parts': parts.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) => MaintenanceLog(
        id: json['id'] as String,
        carId: json['carId'] as String,
        serviceTypeId: json['serviceTypeId'] as String,
        mileage: json['mileage'] as int,
        dateOfService: DateTime.parse(json['dateOfService'] as String),
        cost: json['cost'] as double?,
        mechanicName: json['mechanicName'] as String?,
        notes: json['notes'] as String?,
        receiptUrl: json['receiptUrl'] as String?,
        parts: (json['parts'] as List<dynamic>?)
                ?.map((p) => ServicePart.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

