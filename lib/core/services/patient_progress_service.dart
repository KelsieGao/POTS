import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class PatientProgressService {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<PatientProgress> getProgress(String patientId) async {
    try {
      // Count standup tests
      final testsResponse = await _client
          .from('standup_tests')
          .select()
          .eq('patient_id', patientId);
      
      final testCount = (testsResponse as List).length;

      // Count symptom logs
      final logsResponse = await _client
          .from('symptom_logs')
          .select()
          .eq('patient_id', patientId);
      
      final logCount = (logsResponse as List).length;

      // Check if VOSS questionnaire is completed
      final vossResponse = await _client
          .from('voss_questionnaires')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();
      
      final vossCompleted = vossResponse != null;

      // Check if profile is complete (has non-placeholder data)
      final patientResponse = await _client
          .from('patients')
          .select('reason_for_using_app, date_of_birth, sex_assigned_at_birth')
          .eq('id', patientId)
          .single();
      
      final profileComplete = patientResponse['reason_for_using_app'] != null &&
          patientResponse['reason_for_using_app'] != 'Other' &&
          patientResponse['sex_assigned_at_birth'] != null &&
          patientResponse['sex_assigned_at_birth'] != 'Other';

      return PatientProgress(
        patientId: patientId,
        testsCompleted: testCount,
        symptomsLogged: logCount,
        vossCompleted: vossCompleted,
        profileComplete: profileComplete,
      );
    } catch (e) {
      // Return empty progress on error
      return PatientProgress(
        patientId: patientId,
        testsCompleted: 0,
        symptomsLogged: 0,
        vossCompleted: false,
        profileComplete: false,
      );
    }
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
  int get testProgress => testsCompleted;
  int get maxTests => 5;
  
  String get testProgressText => '$testsCompleted/$maxTests tests completed';
  
  int get totalItems => symptomsLogged;
  bool get hasVoss => vossCompleted;
  bool get hasProfile => profileComplete;
}

