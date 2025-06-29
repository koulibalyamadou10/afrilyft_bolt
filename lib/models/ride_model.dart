class RideModel {
  final String id;
  final String customerId;
  final String? driverId;
  final double pickupLat;
  final double pickupLon;
  final String pickupAddress;
  final double destinationLat;
  final double destinationLon;
  final String destinationAddress;
  final RideStatus status;
  final double? fareAmount;
  final double? distanceKm;
  final int? estimatedDurationMinutes;
  final String paymentMethod;
  final String? notes;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final UserProfile? customer;
  final UserProfile? driver;

  RideModel({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.pickupLat,
    required this.pickupLon,
    required this.pickupAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.destinationAddress,
    required this.status,
    this.fareAmount,
    this.distanceKm,
    this.estimatedDurationMinutes,
    required this.paymentMethod,
    this.notes,
    this.scheduledFor,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.customer,
    this.driver,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'],
      customerId: json['customer_id'],
      driverId: json['driver_id'],
      pickupLat: _parseLocation(json['pickup_location'])['lat'],
      pickupLon: _parseLocation(json['pickup_location'])['lon'],
      pickupAddress: json['pickup_address'],
      destinationLat: _parseLocation(json['destination_location'])['lat'],
      destinationLon: _parseLocation(json['destination_location'])['lon'],
      destinationAddress: json['destination_address'],
      status: RideStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RideStatus.pending,
      ),
      fareAmount: json['fare_amount']?.toDouble(),
      distanceKm: json['distance_km']?.toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      paymentMethod: json['payment_method'] ?? 'cash',
      notes: json['notes'],
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at']) 
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      customer: json['customer'] != null 
          ? UserProfile.fromJson(json['customer']) 
          : null,
      driver: json['driver'] != null 
          ? UserProfile.fromJson(json['driver']) 
          : null,
    );
  }

  static Map<String, double> _parseLocation(dynamic location) {
    // Parse PostGIS POINT format: "POINT(lon lat)"
    if (location is String) {
      final coords = location
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');
      return {
        'lon': double.parse(coords[0]),
        'lat': double.parse(coords[1]),
      };
    }
    return {'lat': 0.0, 'lon': 0.0};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'driver_id': driverId,
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'status': status.name,
      'fare_amount': fareAmount,
      'distance_km': distanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'payment_method': paymentMethod,
      'notes': notes,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

enum RideStatus {
  pending,
  searching,
  accepted,
  inProgress,
  completed,
  cancelled,
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum UserRole {
  customer,
  driver,
}

class DriverLocation {
  final String id;
  final String driverId;
  final double lat;
  final double lon;
  final double? heading;
  final double? speed;
  final bool isAvailable;
  final DateTime lastUpdated;

  DriverLocation({
    required this.id,
    required this.driverId,
    required this.lat,
    required this.lon,
    this.heading,
    this.speed,
    required this.isAvailable,
    required this.lastUpdated,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    final location = RideModel._parseLocation(json['location']);
    return DriverLocation(
      id: json['id'],
      driverId: json['driver_id'],
      lat: location['lat']!,
      lon: location['lon']!,
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      isAvailable: json['is_available'] ?? true,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}