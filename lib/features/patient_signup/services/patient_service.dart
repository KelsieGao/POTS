import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/generated_classes.dart';
import '../models/patient_form_data.dart';

class PatientService {
  PatientService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<Patients> createPatient(PatientFormData data) async {
    final payload = Patients.insert(
      firstName: data.firstName,
      lastName: data.lastName,
      dateOfBirth: data.dateOfBirth,
      email: data.email.isEmpty ? null : data.email,
      phone: data.phone.isEmpty ? null : data.phone,
      heightCm: data.heightCm,
      weightKg: data.weightKg,
      potsDiagnosisDate: data.includeDiagnosisDate
          ? data.potsDiagnosisDate
          : null,
      primaryCarePhysician: data.primaryCarePhysician.isEmpty
          ? null
          : data.primaryCarePhysician,
      sexAssignedAtBirth: data.sexAssignedAtBirth!,
      reasonForUsingApp: data.reasonForUsingApp!,
    );

    final response = await _client
        .from(Patients.table_name)
        .insert(payload)
        .select()
        .maybeSingle();

    if (response == null) {
      throw const PatientServiceException('Failed to create patient');
    }

    return Patients.fromJson(response);
  }
}

class PatientServiceException implements Exception {
  const PatientServiceException(this.message);
  final String message;

  @override
  String toString() => 'PatientServiceException: $message';
}
