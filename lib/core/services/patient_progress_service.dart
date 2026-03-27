import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class PatientProgressService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<PatientProgress> getProgress(String patientId) async {
    // Each datum is resilient; one failure won't zero-out the rest.
    int testCount = 0;
    int logCount = 0;
    bool vossCompleted = false;
    bool profileComplete = false;

    // Count standup tests
    try {
      final testsResponse = await _client
          .from('standup_tests')
          .select()
          .eq('patient_id', patientId);
      testCount = (testsResponse as List).length;
    } catch (_) {}

    // Count symptom logs
    try {
      final logsResponse = await _client
          .from('symptom_logs')
          .select()
          .eq('patient_id', patientId);
      logCount = (logsResponse as List).length;
    } catch (_) {}

    // Check VOSS completion
    try {
      final vossResponse = await _client
          .from('voss_questionnaires')
          .select()
          .eq('patient_id', patientId)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      vossCompleted = vossResponse != null;
    } catch (_) {}

    // Check profile completeness
    try {
      final patientResponse = await _client
          .from('patients')
          .select('reason_for_using_app, date_of_birth, sex_assigned_at_birth')
          .eq('id', patientId)
          .single();
      profileComplete = patientResponse['reason_for_using_app'] != null &&
          patientResponse['reason_for_using_app'] != 'Other' &&
          patientResponse['sex_assigned_at_birth'] != null &&
          patientResponse['sex_assigned_at_birth'] != 'Other';
    } catch (_) {}

    return PatientProgress(
      patientId: patientId,
      testsCompleted: testCount,
      symptomsLogged: logCount,
      vossCompleted: vossCompleted,
      profileComplete: profileComplete,
    );
  }
}

class PatientProgress {
  final String patientId;
  final int testsCompleted;
  final int symptomsLogged;
  final bool vossCompleted;
  final bool profileComplete;

  PatientProgress({
    required this.patientId,
    required this.testsCompleted,
    required this.symptomsLogged,
    required this.vossCompleted,
    required this.profileComplete,
  });

  // Show actual test count (n/5 format)
  int get testProgress => testsCompleted > maxTests ? maxTests : testsCompleted;
  int get maxTests => 5;
  
  String get testProgressText =>
      '${testsCompleted > maxTests ? maxTests : testsCompleted}/$maxTests tests completed';
  
  int get totalItems => symptomsLogged;
  bool get hasVoss => vossCompleted;
  bool get hasProfile => profileComplete;
}

