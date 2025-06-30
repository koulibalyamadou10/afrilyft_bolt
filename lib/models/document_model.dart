class DriverDocument {
  final String id;
  final String driverId;
  final String documentType;
  final String documentUrl;
  final String status;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverDocument({
    required this.id,
    required this.driverId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    this.verifiedAt,
    this.expiresAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'],
      driverId: json['driver_id'],
      documentType: json['document_type'],
      documentUrl: json['document_url'],
      status: json['status'],
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'document_type': documentType,
      'document_url': documentUrl,
      'status': status,
      'verified_at': verifiedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'expired':
        return 'Expiré';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

enum DocumentType {
  license,
  insurance,
  vehicleRegistration,
  vehicleInspection,
}

extension DocumentTypeExtension on DocumentType {
  String get value {
    switch (this) {
      case DocumentType.license:
        return 'license';
      case DocumentType.insurance:
        return 'insurance';
      case DocumentType.vehicleRegistration:
        return 'vehicle_registration';
      case DocumentType.vehicleInspection:
        return 'vehicle_inspection';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentType.license:
        return 'Permis de conduire';
      case DocumentType.insurance:
        return 'Assurance véhicule';
      case DocumentType.vehicleRegistration:
        return 'Carte grise';
      case DocumentType.vehicleInspection:
        return 'Contrôle technique';
    }
  }
}