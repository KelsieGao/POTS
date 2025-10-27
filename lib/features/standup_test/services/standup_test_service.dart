import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pots/core/services/supabase_service.dart';
import 'package:pots/models/generated_classes.dart';

import '../models/standup_test_data.dart';

class StandupTestService {
  StandupTestService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<void> submit({
    required String patientId,
    required StandupTestData data,
  }) async {
    try {
      final now = DateTime.now();

      // Create the payload but filter out generated columns
      final fullPayload = StandupTests.insert(
        patientId: patientId,
        testDate: DateTime(now.year, now.month, now.day),
        testTime: now,
        supineHr: data.supineHr,
        supineSystolic: data.supineSystolic,
        supineDiastolic: data.supineDiastolic,
        supineDurationMinutes: data.supineDurationMinutes,
        standing1minHr: data.standing1MinHr,
        standing1minSystolic: data.standing1MinSystolic,
        standing1minDiastolic: data.standing1MinDiastolic,
        standing3minHr: data.standing3MinHr,
        standing3minSystolic: data.standing3MinSystolic,
        standing3minDiastolic: data.standing3MinDiastolic,
        standing5minHr: data.standing5MinHr,
        standing10minHr: data.standing10MinHr,
        notes: data.notes,
        createdAt: now,
      );

      // Remove generated columns that shouldn't be inserted
      final payload = Map<String, dynamic>.from(fullPayload)
        ..remove('hr_increase_1min')
        ..remove('hr_increase_3min')
        ..remove('hr_increase_5min')
        ..remove('hr_increase_10min')
        ..remove('systolic_drop_1min')
        ..remove('systolic_drop_3min')
        ..remove('test_result')
        ..remove('pots_severity');

      print('Submitting test with data:');
      print('  Supine BP: ${data.supineSystolic}/${data.supineDiastolic}');
      print('  1min BP: ${data.standing1MinSystolic}/${data.standing1MinDiastolic}');
      print('  3min BP: ${data.standing3MinSystolic}/${data.standing3MinDiastolic}');

      await _client.from(StandupTests.table_name).insert(payload);
      print('Test saved successfully!');
    } catch (e) {
      print('Error submitting standup test: $e');
      rethrow;
    }
  }

  Future<List<StandupTests>> getTestHistory({
    required String patientId,
    int? limit,
  }) async {
    final query = _client
        .from(StandupTests.table_name)
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    if (limit != null) {
      query.limit(limit);
    }

    final response = await query;
    return response.map((json) => StandupTests.fromJson(json)).toList();
  }
}
