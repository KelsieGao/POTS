class PatientAuth {
  final String id;
  final String patientId;
  final String email;
  final String passwordHash;
  final String? verificationCode;
  final DateTime? verificationCodeExpiresAt;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientAuth({
    required this.id,
    required this.patientId,
    required this.email,
    required this.passwordHash,
    this.verificationCode,
    this.verificationCodeExpiresAt,
    this.isVerified = false,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientAuth.fromJson(Map<String, dynamic> json) {
    return PatientAuth(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String,
      verificationCode: json['verification_code'] as String?,
      verificationCodeExpiresAt: json['verification_code_expires_at'] != null
          ? DateTime.parse(json['verification_code_expires_at'] as String)
          : null,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'email': email,
      'password_hash': passwordHash,
      'verification_code': verificationCode,
      'verification_code_expires_at': verificationCodeExpiresAt?.toIso8601String(),
      'is_verified': isVerified,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'patient_id': patientId,
      'email': email,
      'password_hash': passwordHash,
      'verification_code': verificationCode,
      'verification_code_expires_at': verificationCodeExpiresAt?.toIso8601String(),
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }
}

class PhysicianCode {
  final String id;
  final String code;
  final String physicianName;
  final String? physicianInstitution;
  final String? physicianEmail;
  final String? createdBy;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhysicianCode({
    required this.id,
    required this.code,
    required this.physicianName,
    this.physicianInstitution,
    this.physicianEmail,
    this.createdBy,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhysicianCode.fromJson(Map<String, dynamic> json) {
    return PhysicianCode(
      id: json['id'] as String,
      code: json['code'] as String,
      physicianName: json['physician_name'] as String,
      physicianInstitution: json['physician_institution'] as String?,
      physicianEmail: json['physician_email'] as String?,
      createdBy: json['created_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'physician_name': physicianName,
      'physician_institution': physicianInstitution,
      'physician_email': physicianEmail,
      'created_by': createdBy,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PhysicianPatientLink {
  final String id;
  final String physicianCode;
  final String patientId;
  final String? linkedBy;
  final DateTime linkedAt;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhysicianPatientLink({
    required this.id,
    required this.physicianCode,
    required this.patientId,
    this.linkedBy,
    required this.linkedAt,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhysicianPatientLink.fromJson(Map<String, dynamic> json) {
    return PhysicianPatientLink(
      id: json['id'] as String,
      physicianCode: json['physician_code'] as String,
      patientId: json['patient_id'] as String,
      linkedBy: json['linked_by'] as String?,
      linkedAt: DateTime.parse(json['linked_at'] as String),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'physician_code': physicianCode,
      'patient_id': patientId,
      'linked_by': linkedBy,
      'linked_at': linkedAt.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

