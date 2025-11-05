import 'package:flutter/material.dart';

class ServiceItem {
  final String id;
  final String name;
  final List<ServiceItem>? subItems;

  ServiceItem({
    required this.id,
    required this.name,
    this.subItems,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subItems': subItems?.map((item) => item.toJson()).toList(),
      };

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as String,
        name: json['name'] as String,
        subItems: json['subItems'] != null
            ? (json['subItems'] as List)
                .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class ServiceGroup {
  final String id;
  final String name;
  final Color color;
  final List<ServiceItem> services;

  ServiceGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.services,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'services': services.map((service) => service.toJson()).toList(),
      };

  factory ServiceGroup.fromJson(Map<String, dynamic> json) => ServiceGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        services: (json['services'] as List)
            .map((service) => ServiceItem.fromJson(service as Map<String, dynamic>))
            .toList(),
      );
}

