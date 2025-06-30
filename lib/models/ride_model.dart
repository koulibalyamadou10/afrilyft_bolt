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
    try {
      print('🔍 Création du RideModel depuis JSON: $json');

      // Validation des champs requis
      if (json['id'] == null) throw Exception('ID du trajet manquant');
      if (json['customer_id'] == null) throw Exception('ID du client manquant');
      if (json['pickup_latitude'] == null)
        throw Exception('Latitude de départ manquante');
      if (json['pickup_longitude'] == null)
        throw Exception('Longitude de départ manquante');
      if (json['pickup_address'] == null)
        throw Exception('Adresse de départ manquante');
      if (json['destination_latitude'] == null)
        throw Exception('Latitude de destination manquante');
      if (json['destination_longitude'] == null)
        throw Exception('Longitude de destination manquante');
      if (json['destination_address'] == null)
        throw Exception('Adresse de destination manquante');
      if (json['status'] == null) throw Exception('Statut du trajet manquant');
      if (json['payment_method'] == null)
        throw Exception('Méthode de paiement manquante');
      if (json['created_at'] == null)
        throw Exception('Date de création manquante');

      return RideModel(
        id: json['id'].toString(),
        customerId: json['customer_id'].toString(),
        driverId: json['driver_id']?.toString(),
        pickupLat: (json['pickup_latitude'] as num).toDouble(),
        pickupLon: (json['pickup_longitude'] as num).toDouble(),
        pickupAddress: json['pickup_address'].toString(),
        destinationLat: (json['destination_latitude'] as num).toDouble(),
        destinationLon: (json['destination_longitude'] as num).toDouble(),
        destinationAddress: json['destination_address'].toString(),
        status: RideStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => RideStatus.pending,
        ),
        fareAmount: json['fare_amount']?.toDouble(),
        distanceKm: json['distance_km']?.toDouble(),
        estimatedDurationMinutes: json['estimated_duration_minutes'],
        paymentMethod: json['payment_method'].toString(),
        notes: json['notes']?.toString(),
        scheduledFor:
            json['scheduled_for'] != null
                ? DateTime.parse(json['scheduled_for'])
                : null,
        createdAt: DateTime.parse(json['created_at']),
        acceptedAt:
            json['accepted_at'] != null
                ? DateTime.parse(json['accepted_at'])
                : null,
        startedAt:
            json['started_at'] != null
                ? DateTime.parse(json['started_at'])
                : null,
        completedAt:
            json['completed_at'] != null
                ? DateTime.parse(json['completed_at'])
                : null,
        customer:
            json['customer'] != null
                ? UserProfile.fromJson(json['customer'])
                : null,
        driver:
            json['driver'] != null
                ? UserProfile.fromJson(json['driver'])
                : null,
      );
    } catch (e) {
      print('❌ Erreur lors de la création du RideModel: $e');
      print('🔍 JSON problématique: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'driver_id': driverId,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLon,
      'pickup_address': pickupAddress,
      'destination_latitude': destinationLat,
      'destination_longitude': destinationLon,
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
    try {
      print('🔍 Création du UserProfile depuis JSON: $json');

      return UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.customer,
        ),
        avatarUrl: json['avatar_url']?.toString(),
        isActive: json['is_active'] ?? true,
        isVerified: json['is_verified'] ?? false,
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : DateTime.now(),
      );
    } catch (e) {
      print('❌ Erreur lors de la création du UserProfile: $e');
      print('🔍 JSON problématique: $json');
      rethrow;
    }
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

enum UserRole { customer, driver }

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
    return DriverLocation(
      id: json['id'],
      driverId: json['driver_id'],
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      isAvailable: json['is_available'] ?? true,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'latitude': lat,
      'longitude': lon,
      'heading': heading,
      'speed': speed,
      'is_available': isAvailable,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

enum NotificationType { rideRequest, rideUpdate, payment, general }
