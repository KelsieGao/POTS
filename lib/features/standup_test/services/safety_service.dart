import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pots/features/standup_test/models/safety_acknowledgment.dart';

class SafetyService {
  const SafetyService._();

  static const String _safetyAcknowledgmentTable = 'safety_acknowledgments';

  /// Save a safety acknowledgment for a patient
  static Future<SafetyAcknowledgment?> saveSafetyAcknowledgment(
    SafetyAcknowledgment acknowledgment,
  ) async {
    try {
      // Create a new acknowledgment with proper UUID generation
      final acknowledgmentData = acknowledgment.toJson();
      // Remove the id field to let Supabase generate it automatically
      acknowledgmentData.remove('id');

      final response = await Supabase.instance.client
          .from(_safetyAcknowledgmentTable)
          .insert(acknowledgmentData)
          .select()
          .single();

      return SafetyAcknowledgment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error saving safety acknowledgment: $e');
      rethrow;
    }
  }

  /// Get the latest safety acknowledgment for a patient
  static Future<SafetyAcknowledgment?> getLatestSafetyAcknowledgment(
    String patientId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from(_safetyAcknowledgmentTable)
          .select()
          .eq('patient_id', patientId)
          .order('acknowledged_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return SafetyAcknowledgment.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching safety acknowledgment: $e');
      rethrow;
    }
  }

  /// Check if patient has a valid safety acknowledgment (within last 30 days)
  static Future<bool> hasValidSafetyAcknowledgment(String patientId) async {
    try {
      final acknowledgment = await getLatestSafetyAcknowledgment(patientId);
      if (acknowledgment == null) return false;

      // Check if acknowledgment is less than 30 days old
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      return acknowledgment.acknowledgedAt.isAfter(thirtyDaysAgo);
    } catch (e) {
      print('Error checking safety acknowledgment validity: $e');
      return false;
    }
  }

  /// Get all safety acknowledgments for a patient
  static Future<List<SafetyAcknowledgment>> getSafetyAcknowledgmentHistory(
    String patientId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from(_safetyAcknowledgmentTable)
          .select()
          .eq('patient_id', patientId)
          .order('acknowledged_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => SafetyAcknowledgment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching safety acknowledgment history: $e');
      rethrow;
    }
  }
}
