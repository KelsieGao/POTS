class PatientFormData {
  PatientFormData({
    this.firstName = '',
    this.lastName = '',
    DateTime? dateOfBirth,
    this.email = '',
    this.phone = '',
    this.heightCm,
    this.weightKg,
    this.potsDiagnosisDate,
    this.includeDiagnosisDate = false,
    this.primaryCarePhysician = '',
    this.sexAssignedAtBirth,
    this.reasonForUsingApp,
  }) : dateOfBirth = dateOfBirth ?? DateTime.now();

  String firstName;
  String lastName;
  DateTime dateOfBirth;
  String email;
  String phone;
  int? heightCm;
  double? weightKg;
  DateTime? potsDiagnosisDate;
  bool includeDiagnosisDate;
  String primaryCarePhysician;
  String? sexAssignedAtBirth;
  String? reasonForUsingApp;

  bool get isValid {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        sexAssignedAtBirth != null &&
        reasonForUsingApp != null &&
        dateOfBirth.isBefore(DateTime.now());
  }

  PatientFormData copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    int? heightCm,
    double? weightKg,
    DateTime? potsDiagnosisDate,
    bool? includeDiagnosisDate,
    String? primaryCarePhysician,
    String? sexAssignedAtBirth,
    String? reasonForUsingApp,
  }) {
    return PatientFormData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      potsDiagnosisDate: potsDiagnosisDate ?? this.potsDiagnosisDate,
      includeDiagnosisDate: includeDiagnosisDate ?? this.includeDiagnosisDate,
      primaryCarePhysician: primaryCarePhysician ?? this.primaryCarePhysician,
      sexAssignedAtBirth: sexAssignedAtBirth ?? this.sexAssignedAtBirth,
      reasonForUsingApp: reasonForUsingApp ?? this.reasonForUsingApp,
    );
  }
}

const sexAssignedAtBirthOptions = <String>[
  'Male',
  'Female',
  'Other',
  'Prefer not to say',
];

const reasonForUsingAppOptions = <String>[
  'Doctor referral',
  'I suspect I have POTS',
  'Other',
];
