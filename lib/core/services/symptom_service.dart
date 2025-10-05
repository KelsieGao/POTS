import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/symptom_models.dart';

class SymptomService {
  static const String _symptomLogsTable = 'symptom_logs';
  static const String _symptomsTable = 'symptoms';

  static Future<List<SymptomLog>> getSymptomLogs(String patientId) async {
    try {
      final response = await Supabase.instance.client
          .from(_symptomLogsTable)
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => SymptomLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching symptom logs: $e');
      rethrow;
    }
  }

  static Future<SymptomLog?> saveSymptomLog(SymptomLog symptomLog) async {
    try {
      // Create a new symptom log with proper UUID generation
      final symptomLogData = symptomLog.toJson();
      // Remove the id field to let Supabase generate it automatically
      symptomLogData.remove('id');
      
      final response = await Supabase.instance.client
          .from(_symptomLogsTable)
          .insert(symptomLogData)
          .select()
          .single();

      return SymptomLog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error saving symptom log: $e');
      rethrow;
    }
  }

  static Future<SymptomLog?> updateSymptomLog(SymptomLog symptomLog) async {
    try {
      final response = await Supabase.instance.client
          .from(_symptomLogsTable)
          .update(symptomLog.toJson())
          .eq('id', symptomLog.id)
          .select()
          .single();

      return SymptomLog.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating symptom log: $e');
      rethrow;
    }
  }

  static Future<void> deleteSymptomLog(String symptomLogId) async {
    try {
      await Supabase.instance.client
          .from(_symptomLogsTable)
          .delete()
          .eq('id', symptomLogId);
    } catch (e) {
      print('Error deleting symptom log: $e');
      rethrow;
    }
  }

  static Future<List<Symptom>> getAvailableSymptoms() async {
    try {
      final response = await Supabase.instance.client
          .from(_symptomsTable)
          .select()
          .order('name');

      return (response as List)
          .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching symptoms: $e');
      // Return predefined symptoms if database fails
      return PredefinedSymptoms.symptoms;
    }
  }

  static Future<Symptom?> saveCustomSymptom(Symptom symptom) async {
    try {
      final response = await Supabase.instance.client
          .from(_symptomsTable)
          .insert(symptom.toJson())
          .select()
          .single();

      return Symptom.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error saving custom symptom: $e');
      rethrow;
    }
  }

  // Initialize predefined symptoms in database
  static Future<void> initializeSymptoms() async {
    try {
      for (final symptom in PredefinedSymptoms.symptoms) {
        await Supabase.instance.client
            .from(_symptomsTable)
            .upsert(symptom.toJson(), onConflict: 'id');
      }
    } catch (e) {
      print('Error initializing symptoms: $e');
    }
  }

  // Get symptom statistics for a patient
  static Future<Map<String, dynamic>> getSymptomStats(String patientId) async {
    try {
      final logs = await getSymptomLogs(patientId);
      
      Map<String, int> symptomCounts = {};
      Map<String, double> symptomSeverity = {};
      int totalLogs = logs.length;
      
      for (final log in logs) {
        for (final symptom in log.symptoms) {
          symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
          symptomSeverity[symptom] = 
              (symptomSeverity[symptom] ?? 0) + log.severity;
        }
      }
      
      // Calculate average severity for each symptom
      for (final symptom in symptomSeverity.keys) {
        symptomSeverity[symptom] = 
            symptomSeverity[symptom]! / symptomCounts[symptom]!;
      }
      
      return {
        'total_logs': totalLogs,
        'symptom_counts': symptomCounts,
        'average_severity': symptomSeverity,
        'most_common_symptom': symptomCounts.isNotEmpty 
            ? symptomCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      print('Error getting symptom stats: $e');
      return {
        'total_logs': 0,
        'symptom_counts': {},
        'average_severity': {},
        'most_common_symptom': null,
      };
    }
  }
}
