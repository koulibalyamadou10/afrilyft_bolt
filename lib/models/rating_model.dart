class RatingModel {
  final String id;
  final String rideId;
  final String raterId;
  final String ratedId;
  final int rating;
  final String? review;
  final DateTime createdAt;
  final UserProfile? rater;
  final RideInfo? ride;

  RatingModel({
    required this.id,
    required this.rideId,
    required this.raterId,
    required this.ratedId,
    required this.rating,
    this.review,
    required this.createdAt,
    this.rater,
    this.ride,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'],
      rideId: json['ride_id'],
      raterId: json['rater_id'],
      ratedId: json['rated_id'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
      rater: json['rater'] != null ? UserProfile.fromJson(json['rater']) : null,
      ride: json['ride'] != null ? RideInfo.fromJson(json['ride']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'rater_id': raterId,
      'rated_id': ratedId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RideInfo {
  final String pickupAddress;
  final String destinationAddress;
  final DateTime createdAt;

  RideInfo({
    required this.pickupAddress,
    required this.destinationAddress,
    required this.createdAt,
  });

  factory RideInfo.fromJson(Map<String, dynamic> json) {
    return RideInfo(
      pickupAddress: json['pickup_address'],
      destinationAddress: json['destination_address'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Add this to your existing ride_model.dart file
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