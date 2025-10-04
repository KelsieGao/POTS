import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/generated_classes.dart';
import '../models/voss_questionnaire_data.dart';

class VossQuestionnaireService {
  VossQuestionnaireService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<VossQuestionnaires> submit({
    required String patientId,
    required VossQuestionnaireData data,
  }) async {
    final payload = VossQuestionnaires.insert(
      patientId: patientId,
      completedAt: DateTime.now(),
      totalScore: data.totalScore,
      notes: jsonEncode(data.responses),
    );

    final response = await _client
        .from(VossQuestionnaires.table_name)
        .insert(payload)
        .select()
        .maybeSingle();

    if (response == null) {
      throw const VossQuestionnaireException('Failed to submit questionnaire');
    }

    return VossQuestionnaires.fromJson(response);
  }
}

class VossQuestionnaireException implements Exception {
  const VossQuestionnaireException(this.message);
  final String message;

  @override
  String toString() => 'VossQuestionnaireException: $message';
}
