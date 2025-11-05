# 🚗 AutoPulse - Car Maintenance Tracker

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.5.3-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5.3-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Professional car maintenance tracking application built with Flutter**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Project Structure](#-project-structure) • [Screenshots](#-screenshots)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Database Schema](#-database-schema)
- [Usage](#-usage)
- [Service Categories](#-service-categories)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

AutoPulse is a comprehensive car maintenance tracking application that helps you manage your vehicle's maintenance history, schedule services, and track maintenance costs. Built with Flutter, it provides a modern, intuitive interface for keeping your vehicles in top condition.

### Key Benefits

- ✅ **Track Multiple Vehicles** - Manage multiple cars with individual maintenance histories
- ✅ **Comprehensive Service Catalog** - 100+ predefined maintenance services organized by category
- ✅ **Smart Reminders** - Never miss a service with automated maintenance reminders
- ✅ **Cost Tracking** - Monitor maintenance expenses and part costs
- ✅ **Service History** - Complete maintenance log with receipts and notes
- ✅ **Offline First** - All data stored locally with SQLite database

---

## ✨ Features

### 🚙 Vehicle Management
- Add and manage multiple vehicles
- Track vehicle details (make, model, year, VIN, license plate)
- Current mileage tracking
- Vehicle photos and nicknames

### 🔧 Maintenance Tracking
- **14 Service Categories** with color-coded organization:
  - Engine & Oil (Orange)
  - Brakes (Red)
  - Tires & Wheels (Dark Gray)
  - Battery & Electrical (Yellow)
  - Cooling System (Blue)
  - Transmission & Clutch (Purple)
  - Drivetrain & Axles (Dark Blue)
  - Suspension & Steering (Green)
  - Fuel System (Orange/Yellow)
  - Exhaust & Emissions (Gray)
  - HVAC & Cabin (Light Blue)
  - Fluids & Top-ups (Teal)
  - Diagnostics, Software & Safety (Indigo)
  - Body, Glass & Interior (Pink)

- **100+ Predefined Services** including:
  - Oil changes, filters, spark plugs
  - Brake pads, rotors, fluid
  - Tire rotation, alignment, balancing
  - Battery testing and replacement
  - Transmission service
  - And many more...

- **Custom Services** - Create your own service types
- **Service Parts Tracking** - Record parts used with costs
- **Service Notes & Receipts** - Add detailed notes and attach receipts

### 📊 Dashboard & Analytics
- Maintenance status overview
- Upcoming service reminders
- Service history timeline
- Cost summaries
- Mileage tracking

### 🔔 Reminders
- Automatic service interval reminders
- Custom maintenance rules
- Mileage-based and time-based alerts

### 🛒 Marketplace
- Browse car parts and accessories
- Product categories
- Shopping cart functionality
- Order management

### 👤 User Features
- Secure authentication
- User profiles
- Settings and preferences
- Dark theme support

---

## 🛠 Technology Stack

### Core Framework
- **Flutter** `^3.5.3` - Cross-platform UI framework
- **Dart** `^3.5.3` - Programming language

### Dependencies
- **sqflite** `^2.3.0` - SQLite database for local storage
- **shared_preferences** `^2.2.2` - Key-value storage for settings
- **uuid** `^4.2.1` - UUID generation for unique IDs
- **path** `^1.9.0` - Path manipulation utilities

### Architecture
- **MVC Pattern** - Model-View-Controller architecture
- **Service Layer** - Business logic separation
- **Database Layer** - SQLite with proper schema design

---

## 📦 Installation

### Prerequisites

- Flutter SDK (3.5.3 or higher)
- Dart SDK (3.5.3 or higher)
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDE)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/autopulse_demo_1.git
   cd autopulse_demo_1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
```bash
cd android
./gradlew build
```

#### iOS
```bash
cd ios
pod install
```

---

## 📁 Project Structure

```
lib/
├── data/                          # Data layer
│   └── car_maintenance_services.dart  # Predefined service catalog
│
├── database/                      # Database layer
│   └── database_helper.dart          # SQLite database helper
│
├── models/                        # Data models
│   ├── car.dart
│   ├── maintenance_log.dart
│   ├── service_type.dart
│   ├── service_group.dart
│   ├── product.dart
│   ├── cart_item.dart
│   └── order.dart
│
├── screens/                       # UI screens
│   ├── splash_intro_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_dashboard_screen.dart
│   ├── add_service_step1_screen.dart
│   ├── add_service_step2_screen.dart
│   ├── add_service_step3_screen.dart
│   ├── history_screen.dart
│   ├── reminders_screen.dart
│   ├── marketplace_screen.dart
│   └── more_settings_screen.dart
│
├── services/                      # Business logic
│   ├── auth_service.dart
│   ├── car_service.dart
│   ├── maintenance_service.dart
│   ├── service_group_service.dart
│   └── marketplace_service.dart
│
├── theme/                         # App theming
│   └── app_theme.dart
│
├── widgets/                       # Reusable widgets
│   ├── car_texture_background.dart
│   └── car_texture_scaffold.dart
│
└── main.dart                      # App entry point
```

---

## 🗄 Database Schema

The app uses SQLite with the following tables:

### Core Tables

- **users** - User accounts and authentication
- **cars** - Vehicle information
- **service_types** - Service categories and types
- **maintenance_logs** - Service records
- **service_parts** - Parts used in services
- **maintenance_rules** - Service interval rules

### Marketplace Tables

- **products** - Marketplace products
- **cart_items** - Shopping cart items
- **orders** - Order history
- **order_items** - Order line items

### Utility Tables

- **exports** - Export history
- **activity_log** - User activity tracking
- **user_settings** - User preferences

### Database Location

- **Android**: `/data/data/com.example.autopulse_demo_1/databases/autocare.db`
- **iOS**: App's Documents directory
- **Desktop**: Platform-specific app data directory

---

## 🚀 Usage

### Getting Started

1. **Launch the app** - Open AutoPulse on your device
2. **Sign up/Login** - Create an account or sign in
3. **Add your first car** - Enter your vehicle details
4. **Start tracking** - Log your first maintenance service

### Adding a Service

1. Tap the **+** button on the home screen
2. Browse service categories (color-coded for easy navigation)
3. Select a service from the category
4. Fill in service details:
   - Date and mileage
   - Cost and mechanic name
   - Parts used
   - Notes and receipts
5. Save the service

### Managing Vehicles

- **Add a car**: Go to settings → Add Vehicle
- **Update mileage**: Tap on the mileage card → Update
- **View history**: Navigate to History tab
- **Set reminders**: Configure maintenance rules in Settings

---

## 🎨 Service Categories

The app includes 14 comprehensive service categories:

| Category | Color | Services Count |
|----------|-------|----------------|
| Engine & Oil | 🟠 Orange | 8 services |
| Brakes | 🔴 Red | 5 services |
| Tires & Wheels | ⚫ Dark Gray | 8 services |
| Battery & Electrical | 🟡 Yellow | 7 services |
| Cooling System | 🔵 Blue | 7 services |
| Transmission & Clutch | 🟣 Purple | 7 services |
| Drivetrain & Axles | 🔵 Dark Blue | 6 services |
| Suspension & Steering | 🟢 Green | 7 services |
| Fuel System | 🟠 Orange/Yellow | 8 services |
| Exhaust & Emissions | ⚪ Gray | 7 services |
| HVAC & Cabin | 🔵 Light Blue | 6 services |
| Fluids & Top-ups | 🔷 Teal | 6 services |
| Diagnostics, Software & Safety | 🟣 Indigo | 8 services |
| Body, Glass & Interior | 🩷 Pink | 7 services |

**Total: 100+ predefined services** with hierarchical sub-items support.

---

## 💻 Development

### Running Tests

```bash
flutter test
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

### Code Style

The project follows Flutter/Dart style guidelines. Linting is configured via `analysis_options.yaml`.

### Database Migrations

When adding new tables or modifying schema:
1. Update `database_helper.dart`
2. Increment database version
3. Add migration logic in `_onUpgrade` method

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass

---

## 📱 Screenshots

> _Screenshots coming soon!_

- Dashboard overview
- Service selection with color-coded categories
- Maintenance history
- Service details
- Settings and preferences

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Abdelrahman Tamer** - [MY_GitHub](https://github.com/AbdelrahmanTamer11)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- SQLite team for the robust database engine
- All contributors and testers

---

## 📞 Support

For support, email ""___"" or open an issue in the repository.

---

## 🔮 Roadmap

- [ ] Cloud sync functionality
- [ ] Multi-language support
- [ ] Export to PDF/CSV
- [ ] Integration with OBD-II scanners
- [ ] Social sharing features
- [ ] Advanced analytics and reports
- [ ] Service provider directory
- [ ] Parts price comparison

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ Star this repo if you find it helpful!

</div>
