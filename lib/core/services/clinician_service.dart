import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/clinician_models.dart';
import 'supabase_service.dart';

class ClinicianService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<Clinician?> authenticateWithCode(String code) async {
    try {
      final response = await _client
          .from('clinicians')
          .select()
          .eq('clinician_code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final clinician = Clinician.fromJson(response);

      await _client.from('clinicians').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', clinician.id);

      return clinician;
    } catch (e) {
      throw Exception('Failed to authenticate clinician: $e');
    }
  }

  static Future<Clinician> createClinician({
    required String code,
    required String name,
    String? email,
  }) async {
    try {
      final response = await _client.from('clinicians').insert({
        'clinician_code': code.toUpperCase(),
        'name': name,
        'email': email,
      }).select().single();

      return Clinician.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create clinician: $e');
    }
  }

  static Future<List<PatientSummary>> getClinicianPatients(
    String clinicianId, {
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('clinician_patients')
          .select('patient_id, status, added_at')
          .eq('clinician_id', clinicianId)
          .order('added_at', ascending: false);

      final relationshipData = await query;

      if (relationshipData.isEmpty) {
        return [];
      }

      final patientIds =
          relationshipData.map((r) => r['patient_id'] as String).toList();

      final patientQuery = _client
          .from('patients')
          .select('id, first_name, last_name, patient_code, created_at')
          .inFilter('id', patientIds);

      final patientsData = await patientQuery;

      final patientMap = <String, Map<String, dynamic>>{};
      for (final patient in patientsData) {
        patientMap[patient['id'] as String] = patient;
      }

      final summaries = <PatientSummary>[];
      for (final relationship in relationshipData) {
        final patientId = relationship['patient_id'] as String;
        final patient = patientMap[patientId];

        if (patient == null) continue;

        final firstName = patient['first_name'] as String? ?? '';
        final lastName = patient['last_name'] as String? ?? '';
        final patientCode = patient['patient_code'] as String? ?? patientId;

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!firstName.toLowerCase().contains(query) &&
              !lastName.toLowerCase().contains(query) &&
              !patientCode.toLowerCase().contains(query)) {
            continue;
          }
        }

        final testsCount = await _getPatientTestCount(patientId);

        summaries.add(
          PatientSummary(
            patientId: patientId,
            firstName: firstName,
            lastName: lastName,
            patientCode: patientCode,
            status: ClinicianPatient.parseStatus(
                relationship['status'] as String),
            lastActivity: DateTime.tryParse(
                relationship['added_at'] as String? ?? ''),
            currentDay: testsCount,
            totalDays: 5,
          ),
        );
      }

      return summaries;
    } catch (e) {
      throw Exception('Failed to get clinician patients: $e');
    }
  }

  static Future<int> _getPatientTestCount(String patientId) async {
    try {
      final response = await _client
          .from('standup_tests')
          .select('id')
          .eq('patient_id', patientId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<ClinicianPatient> addPatientToClinician({
    required String clinicianId,
    required String patientCode,
  }) async {
    try {
      final patientResponse = await _client
          .from('patients')
          .select('id')
          .eq('patient_code', patientCode.toUpperCase())
          .maybeSingle();

      if (patientResponse == null) {
        throw Exception('Patient not found with code: $patientCode');
      }

      final patientId = patientResponse['id'] as String;

      final existingRelationship = await _client
          .from('clinician_patients')
          .select()
          .eq('clinician_id', clinicianId)
          .eq('patient_id', patientId)
          .maybeSingle();

      if (existingRelationship != null) {
        throw Exception('Patient already added to your dashboard');
      }

      final response = await _client.from('clinician_patients').insert({
        'clinician_id': clinicianId,
        'patient_id': patientId,
        'status': 'active',
      }).select().single();

      return ClinicianPatient.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add patient: $e');
    }
  }

  static Future<DashboardStats> getDashboardStats(String clinicianId) async {
    try {
      final relationships = await _client
          .from('clinician_patients')
          .select('status')
          .eq('clinician_id', clinicianId);

      final activeCount =
          relationships.where((r) => r['status'] == 'active').length;
      final completedCount =
          relationships.where((r) => r['status'] == 'completed').length;
      final totalCount = relationships.length;

      return DashboardStats(
        activePatients: activeCount,
        completedPatients: completedCount,
        totalPatients: totalCount,
      );
    } catch (e) {
      return DashboardStats.empty();
    }
  }

  static Future<void> updatePatientStatus({
    required String clinicianId,
    required String patientId,
    required PatientStatus status,
  }) async {
    try {
      await _client
          .from('clinician_patients')
          .update({'status': status.name})
          .eq('clinician_id', clinicianId)
          .eq('patient_id', patientId);
    } catch (e) {
      throw Exception('Failed to update patient status: $e');
    }
  }
}
