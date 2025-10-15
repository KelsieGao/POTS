class Clinician {
  final String id;
  final String clinicianCode;
  final String name;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  Clinician({
    required this.id,
    required this.clinicianCode,
    required this.name,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory Clinician.fromJson(Map<String, dynamic> json) {
    return Clinician(
      id: json['id'] as String,
      clinicianCode: json['clinician_code'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinician_code': clinicianCode,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }
}

enum PatientStatus {
  active,
  completed,
  inactive;

  String get label {
    switch (this) {
      case PatientStatus.active:
        return 'Active';
      case PatientStatus.completed:
        return 'Completed';
      case PatientStatus.inactive:
        return 'Inactive';
    }
  }
}

class ClinicianPatient {
  final String id;
  final String clinicianId;
  final String patientId;
  final PatientStatus status;
  final DateTime addedAt;
  final DateTime updatedAt;

  ClinicianPatient({
    required this.id,
    required this.clinicianId,
    required this.patientId,
    required this.status,
    required this.addedAt,
    required this.updatedAt,
  });

  factory ClinicianPatient.fromJson(Map<String, dynamic> json) {
    return ClinicianPatient(
      id: json['id'] as String,
      clinicianId: json['clinician_id'] as String,
      patientId: json['patient_id'] as String,
      status: _parseStatus(json['status'] as String),
      addedAt: DateTime.parse(json['added_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinician_id': clinicianId,
      'patient_id': patientId,
      'status': status.name,
      'added_at': addedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static PatientStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PatientStatus.active;
      case 'completed':
        return PatientStatus.completed;
      case 'inactive':
        return PatientStatus.inactive;
      default:
        return PatientStatus.active;
    }
  }
}

class PatientSummary {
  final String patientId;
  final String firstName;
  final String lastName;
  final String patientCode;
  final PatientStatus status;
  final DateTime? lastActivity;
  final int currentDay;
  final int totalDays;

  PatientSummary({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.patientCode,
    required this.status,
    this.lastActivity,
    this.currentDay = 0,
    this.totalDays = 5,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  double get progressPercentage {
    if (totalDays == 0) return 0;
    return (currentDay / totalDays).clamp(0.0, 1.0);
  }
}

class DashboardStats {
  final int activePatients;
  final int completedPatients;
  final int totalPatients;

  DashboardStats({
    required this.activePatients,
    required this.completedPatients,
    required this.totalPatients,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      activePatients: 0,
      completedPatients: 0,
      totalPatients: 0,
    );
  }
}
