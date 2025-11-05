import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/service_group.dart';

class CarMaintenanceServices {
  static final _uuid = const Uuid();
  // Static UUIDs for consistent service identification
  // These would be generated once and stored, but for now we'll generate them dynamically
  // In production, you'd want to use fixed UUIDs stored in a constants file
  
  static List<ServiceGroup> getServiceGroups() {
    // Note: In a real implementation, you'd want to use fixed UUIDs
    // For now, we generate them dynamically but they'll be consistent within a session
    return [
      // Engine & Oil - Orange/Red
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Engine & Oil',
        color: const Color(0xFFFF6B35), // Orange
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Oil Change'),
          ServiceItem(id: _uuid.v4(), name: 'Oil Filter'),
          ServiceItem(id: _uuid.v4(), name: 'Engine Air Filter'),
          ServiceItem(
            id: _uuid.v4(),
            name: 'Spark Plugs',
            subItems: [
              ServiceItem(id: _uuid.v4(), name: 'Iridium/Platinum'),
              ServiceItem(id: _uuid.v4(), name: 'Copper'),
            ],
          ),
          ServiceItem(id: _uuid.v4(), name: 'PCV Valve / Breather'),
          ServiceItem(id: _uuid.v4(), name: 'Throttle Body Clean'),
          ServiceItem(id: _uuid.v4(), name: 'Timing Belt Kit'),
          ServiceItem(id: _uuid.v4(), name: 'Timing Chain Inspection'),
        ],
      ),

      // Brakes - Red
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Brakes',
        color: const Color(0xFFE63946), // Red
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Brake Pads'),
          ServiceItem(id: _uuid.v4(), name: 'Brake Rotors / Drums'),
          ServiceItem(id: _uuid.v4(), name: 'Brake Fluid'),
          ServiceItem(id: _uuid.v4(), name: 'Caliper Service & Slide Pins'),
          ServiceItem(id: _uuid.v4(), name: 'Parking Brake Adjustment'),
        ],
      ),

      // Tires & Wheels - Dark Gray/Black
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Tires & Wheels',
        color: const Color(0xFF2B2D42), // Dark Gray
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Tire Rotation'),
          ServiceItem(id: _uuid.v4(), name: 'Tire Replacement'),
          ServiceItem(id: _uuid.v4(), name: 'Wheel Alignment'),
          ServiceItem(id: _uuid.v4(), name: 'Wheel Balancing'),
          ServiceItem(id: _uuid.v4(), name: 'Tire Pressure Check'),
          ServiceItem(id: _uuid.v4(), name: 'Puncture Repair'),
          ServiceItem(id: _uuid.v4(), name: 'TPMS Sensor / Service Kit'),
          ServiceItem(id: _uuid.v4(), name: 'Rim Repair'),
        ],
      ),

      // Battery & Electrical - Yellow
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Battery & Electrical',
        color: const Color(0xFFFFB703), // Yellow
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Battery Test'),
          ServiceItem(id: _uuid.v4(), name: 'Battery Replacement'),
          ServiceItem(id: _uuid.v4(), name: 'Alternator Check'),
          ServiceItem(id: _uuid.v4(), name: 'Starter Motor Check'),
          ServiceItem(id: _uuid.v4(), name: 'Fuses / Relays'),
          ServiceItem(id: _uuid.v4(), name: 'Grounding Inspection'),
          ServiceItem(id: _uuid.v4(), name: 'Key / Immobilizer Programming'),
        ],
      ),

      // Cooling System - Blue
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Cooling System',
        color: const Color(0xFF219EBC), // Blue
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Coolant Change'),
          ServiceItem(id: _uuid.v4(), name: 'Radiator Flush'),
          ServiceItem(id: _uuid.v4(), name: 'Thermostat Replacement'),
          ServiceItem(id: _uuid.v4(), name: 'Water Pump'),
          ServiceItem(id: _uuid.v4(), name: 'Coolant Hoses'),
          ServiceItem(id: _uuid.v4(), name: 'Radiator Cap'),
          ServiceItem(id: _uuid.v4(), name: 'Inverter/Battery Coolant (Hybrid/EV)'),
        ],
      ),

      // Transmission & Clutch - Purple
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Transmission & Clutch',
        color: const Color(0xFF9B59B6), // Purple
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Automatic Transmission Fluid (ATF)'),
          ServiceItem(id: _uuid.v4(), name: 'Transmission Filter / Sump Service'),
          ServiceItem(id: _uuid.v4(), name: 'DSG / DCT Service'),
          ServiceItem(id: _uuid.v4(), name: 'Manual Gear Oil'),
          ServiceItem(id: _uuid.v4(), name: 'Clutch Kit Replacement'),
          ServiceItem(id: _uuid.v4(), name: 'Clutch Hydraulics (Master/Slave)'),
          ServiceItem(id: _uuid.v4(), name: 'Reduction Gear Oil (Hybrid/EV)'),
        ],
      ),

      // Drivetrain & Axles - Dark Blue
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Drivetrain & Axles',
        color: const Color(0xFF023047), // Dark Blue
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Front Differential Oil (AWD/4×4)'),
          ServiceItem(id: _uuid.v4(), name: 'Rear Differential Oil (RWD, AWD/4×4)'),
          ServiceItem(id: _uuid.v4(), name: 'Transfer Case Fluid (AWD/4×4)'),
          ServiceItem(id: _uuid.v4(), name: 'CV Boots / Axles'),
          ServiceItem(id: _uuid.v4(), name: 'Prop Shaft & U-Joints (RWD, AWD/4×4)'),
          ServiceItem(id: _uuid.v4(), name: 'Wheel Bearings'),
        ],
      ),

      // Suspension & Steering - Green
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Suspension & Steering',
        color: const Color(0xFF2A9D8F), // Green
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Shock Absorbers'),
          ServiceItem(id: _uuid.v4(), name: 'Struts'),
          ServiceItem(id: _uuid.v4(), name: 'Control Arm Bushings'),
          ServiceItem(id: _uuid.v4(), name: 'Ball Joints'),
          ServiceItem(id: _uuid.v4(), name: 'Tie-Rod Ends'),
          ServiceItem(id: _uuid.v4(), name: 'Steering Rack Boots'),
          ServiceItem(id: _uuid.v4(), name: 'Power Steering Fluid (Hydraulic)'),
        ],
      ),

      // Fuel System - Yellow/Orange
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Fuel System',
        color: const Color(0xFFFF9500), // Orange/Yellow
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Fuel Filter'),
          ServiceItem(id: _uuid.v4(), name: 'Fuel Pump'),
          ServiceItem(id: _uuid.v4(), name: 'Injector Cleaning'),
          ServiceItem(id: _uuid.v4(), name: 'Intake / MAF Clean'),
          ServiceItem(id: _uuid.v4(), name: 'Fuel Pressure Test'),
          ServiceItem(id: _uuid.v4(), name: 'EGR Service (Diesel)'),
          ServiceItem(id: _uuid.v4(), name: 'Boost Leak Test (Turbo)'),
          ServiceItem(id: _uuid.v4(), name: 'Intercooler Hoses Check (Turbo)'),
        ],
      ),

      // Exhaust & Emissions - Gray
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Exhaust & Emissions',
        color: const Color(0xFF6C757D), // Gray
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Muffler'),
          ServiceItem(id: _uuid.v4(), name: 'Catalytic Converter'),
          ServiceItem(id: _uuid.v4(), name: 'Pipes & Hangers'),
          ServiceItem(id: _uuid.v4(), name: 'O₂ / NOx Sensors'),
          ServiceItem(id: _uuid.v4(), name: 'EVAP System / Smoke Test'),
          ServiceItem(id: _uuid.v4(), name: 'DPF Regeneration / Clean (Diesel)'),
          ServiceItem(id: _uuid.v4(), name: 'AdBlue / DEF Top-Up (Diesel)'),
        ],
      ),

      // HVAC & Cabin - Light Blue
      ServiceGroup(
        id: _uuid.v4(),
        name: 'HVAC & Cabin',
        color: const Color(0xFF4A90E2), // Light Blue
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Cabin / AC Filter'),
          ServiceItem(id: _uuid.v4(), name: 'AC Performance Check'),
          ServiceItem(id: _uuid.v4(), name: 'Refrigerant Service (Leak-tested)'),
          ServiceItem(id: _uuid.v4(), name: 'Blower Motor'),
          ServiceItem(id: _uuid.v4(), name: 'Heater Core'),
          ServiceItem(id: _uuid.v4(), name: 'Evaporator Clean / Anti-mold'),
        ],
      ),

      // Fluids & Top-ups - Teal
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Fluids & Top-ups',
        color: const Color(0xFF17A2B8), // Teal
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Engine Oil Top-up'),
          ServiceItem(id: _uuid.v4(), name: 'Coolant Top-up'),
          ServiceItem(id: _uuid.v4(), name: 'Brake Fluid Top-up (investigate drop)'),
          ServiceItem(id: _uuid.v4(), name: 'Power Steering Fluid Top-up'),
          ServiceItem(id: _uuid.v4(), name: 'Windshield Washer Fluid'),
          ServiceItem(id: _uuid.v4(), name: 'Grease / Lube Points'),
        ],
      ),

      // Diagnostics, Software & Safety - Indigo
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Diagnostics, Software & Safety',
        color: const Color(0xFF6F42C1), // Indigo
        services: [
          ServiceItem(id: _uuid.v4(), name: 'OBD-II Scan'),
          ServiceItem(id: _uuid.v4(), name: 'Check-Engine Light Diagnosis'),
          ServiceItem(id: _uuid.v4(), name: 'ECU / TCU Software Update'),
          ServiceItem(id: _uuid.v4(), name: 'Infotainment Update'),
          ServiceItem(id: _uuid.v4(), name: 'ADAS Camera / Radar Calibration'),
          ServiceItem(id: _uuid.v4(), name: 'Recalls / TSBs Check'),
          ServiceItem(id: _uuid.v4(), name: 'ABS / SRS Diagnosis'),
          ServiceItem(id: _uuid.v4(), name: 'HV Battery Health Report (Hybrid/EV)'),
        ],
      ),

      // Body, Glass & Interior - Pink/Rose
      ServiceGroup(
        id: _uuid.v4(),
        name: 'Body, Glass & Interior',
        color: const Color(0xFFE91E63), // Pink
        services: [
          ServiceItem(id: _uuid.v4(), name: 'Wiper Blades'),
          ServiceItem(id: _uuid.v4(), name: 'Lights / Bulbs & Aiming'),
          ServiceItem(id: _uuid.v4(), name: 'Headlamp Restoration'),
          ServiceItem(id: _uuid.v4(), name: 'Windshield Chip Repair'),
          ServiceItem(id: _uuid.v4(), name: 'Door Locks / Window Regulators'),
          ServiceItem(id: _uuid.v4(), name: 'Door Seals & Drain Cleaning'),
          ServiceItem(id: _uuid.v4(), name: 'Interior Detailing'),
        ],
      ),
    ];
  }

  // Helper method to flatten all services from all groups into a flat list
  static List<ServiceItem> getAllServices() {
    final groups = getServiceGroups();
    final allServices = <ServiceItem>[];
    
    for (var group in groups) {
      allServices.addAll(group.services);
    }
    
    return allServices;
  }

  // Helper method to get a service by name (searches in all groups)
  static ServiceItem? getServiceByName(String name) {
    final groups = getServiceGroups();
    
    for (var group in groups) {
      for (var service in group.services) {
        if (service.name == name) {
          return service;
        }
        // Check sub-items
        if (service.subItems != null) {
          for (var subItem in service.subItems!) {
            if (subItem.name == name) {
              return subItem;
            }
          }
        }
      }
    }
    
    return null;
  }

  // Helper method to get the group that contains a specific service
  static ServiceGroup? getGroupForService(String serviceName) {
    final groups = getServiceGroups();
    
    for (var group in groups) {
      for (var service in group.services) {
        if (service.name == serviceName) {
          return group;
        }
        // Check sub-items
        if (service.subItems != null) {
          for (var subItem in service.subItems!) {
            if (subItem.name == serviceName) {
              return group;
            }
          }
        }
      }
    }
    
    return null;
  }
}

