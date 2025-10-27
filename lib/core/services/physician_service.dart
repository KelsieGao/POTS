import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/auth_models.dart';
import 'supabase_service.dart';

class PhysicianService {
  static SupabaseClient get _client => SupabaseService.client;
  
  /// Generate a random 6-digit code
  static String _generatePhysicianCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  /// Create a new physician code
  static Future<PhysicianCode> createPhysicianCode({
    required String physicianName,
    String? physicianInstitution,
    String? physicianEmail,
    String? createdBy,
    DateTime? expiresAt,
  }) async {
    try {
      // Generate unique code
      String code = '';
      bool isUnique = false;
      int attempts = 0;
      
      while (!isUnique && attempts < 10) {
        code = _generatePhysicianCode();
        final existing = await _client
            .from('physician_codes')
            .select()
            .eq('code', code)
            .maybeSingle();
        
        if (existing == null) {
          isUnique = true;
        } else {
          attempts++;
        }
      }
      
      if (!isUnique) {
        throw Exception('Failed to generate unique physician code');
      }
      
      final response = await _client.from('physician_codes').insert({
        'code': code,
        'physician_name': physicianName,
        'physician_institution': physicianInstitution,
        'physician_email': physicianEmail,
        'created_by': createdBy,
        'is_active': true,
        'expires_at': expiresAt?.toIso8601String(),
      }).select().single();
      
      return PhysicianCode.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create physician code: $e');
    }
  }
  
  /// Validate a physician code
  static Future<PhysicianCode?> validatePhysicianCode(String code) async {
    try {
      final response = await _client
          .from('physician_codes')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();
      
      if (response == null) return null;
      
      final physicianCode = PhysicianCode.fromJson(response);
      
      // Check if expired
      if (physicianCode.expiresAt != null &&
          physicianCode.expiresAt!.isBefore(DateTime.now())) {
        return null;
      }
      
      return physicianCode;
    } catch (e) {
      throw Exception('Failed to validate physician code: $e');
    }
  }
  
  /// Link a patient to a physician using a code
  static Future<PhysicianPatientLink> linkPatientToPhysician({
    required String physicianCode,
    required String patientId,
    String? linkedBy,
  }) async {
    try {
      // Validate the code
      final physician = await validatePhysicianCode(physicianCode);
      if (physician == null) {
        throw Exception('Invalid or expired physician code');
      }
      
      // Check if already linked
      final existing = await _client
          .from('physician_patient_links')
          .select()
          .eq('physician_code', physicianCode)
          .eq('patient_id', patientId)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing link if inactive
        final link = PhysicianPatientLink.fromJson(existing);
        if (link.status == 'inactive' || link.status == 'removed') {
          await _client
              .from('physician_patient_links')
              .update({'status': 'active'})
              .eq('id', link.id);
          return link.copyWith(status: 'active');
        } else {
          return link;
        }
      }
      
      // Create new link
      final response = await _client.from('physician_patient_links').insert({
        'physician_code': physicianCode,
        'patient_id': patientId,
        'linked_by': linkedBy,
        'linked_at': DateTime.now().toIso8601String(),
        'status': 'active',
      }).select().single();
      
      return PhysicianPatientLink.fromJson(response);
    } catch (e) {
      throw Exception('Failed to link patient to physician: $e');
    }
  }
  
  /// Get all physicians linked to a patient
  static Future<List<PhysicianPatientLink>> getPatientPhysicians(String patientId) async {
    try {
      final response = await _client
          .from('physician_patient_links')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'active');
      
      return (response as List)
          .map((json) => PhysicianPatientLink.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get patient physicians: $e');
    }
  }
  
  /// Remove a physician link
  static Future<void> removePhysicianLink(String linkId) async {
    try {
      await _client
          .from('physician_patient_links')
          .update({'status': 'inactive'})
          .eq('id', linkId);
    } catch (e) {
      throw Exception('Failed to remove physician link: $e');
    }
  }
}

// Extension to add copyWith to PhysicianPatientLink
extension PhysicianPatientLinkExtension on PhysicianPatientLink {
  PhysicianPatientLink copyWith({String? status}) {
    return PhysicianPatientLink(
      id: id,
      physicianCode: physicianCode,
      patientId: patientId,
      linkedBy: linkedBy,
      linkedAt: linkedAt,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

